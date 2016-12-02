require 'fluent/test'
require 'fluent/test/helpers'
require 'fluent/test/driver/output'
require 'fluent/plugin/out_redis'
require 'fluent/time' # Fluent::TimeFormatter
require 'timecop'

class FileOutputTest < Test::Unit::TestCase
  include Fluent::Test::Helpers

  CONFIG = %[
    host localhost
    port 6379
    db_number 1
  ]

  def setup
    Fluent::Test.setup

    @d = create_driver
    @time = event_time("2011-01-02 13:14:15 UTC")
  end

  def create_driver(conf = CONFIG)
    Fluent::Test::Driver::Output.new(Fluent::Plugin::RedisOutput).configure(conf)
  end

  def time_formatter(inject_config)
    Fluent::TimeFormatter.new(inject_config.time_format, inject_config.localtime, inject_config.timezone)
  end

  def test_configure
    assert_equal 'localhost', @d.instance.host
    assert_equal 6379, @d.instance.port
    assert_equal 1, @d.instance.db_number
    assert_nil @d.instance.password
    assert_equal '${tag}', @d.instance.insert_key_prefix
    assert_equal '%s', @d.instance.strftime_format
    assert_false @d.instance.allow_duplicate_key
  end

  def test_configure_with_password
    d = create_driver CONFIG + %[
      password testpass
    ]
    assert_equal 'localhost', d.instance.host
    assert_equal 6379, d.instance.port
    assert_equal 1, d.instance.db_number
    assert_equal 'testpass', d.instance.password
  end

  def test_configure_without_tag_chunk_key
    config = config_element('ROOT', '', {
                              "host" => "localhost",
                              "port" =>  6379,
                              "db_number" => 1,
                            }, [
                              config_element('buffer', 'time', {
                                               'chunk_keys' => 'time',
                                             })
                            ])
    assert_raise Fluent::ConfigError do
      create_driver(config)
    end
  end

  def test_format
    @d.run(default_tag: 'test') do
      @d.feed(@time, {"a"=>1})
    end
    assert_equal [["test", @time, {"a"=>1}].to_msgpack], @d.formatted
  end

  class InjectTest < self
    def test_format_inject_tag_keys
      d = create_driver CONFIG + %[
        include_tag_key true
      ]
      d.run(default_tag: 'test') do
        d.feed(@time, {"a"=>1})
      end
      assert_equal [["test", @time, {"a"=>1, "tag" => "test"}].to_msgpack], d.formatted
    end

    def test_format_inject_time_keys
      d = create_driver CONFIG + %[
        include_time_key true
      ]
      timef = time_formatter(d.instance.inject_config)
      d.run(default_tag: 'test') do
        d.feed(@time, {"a"=>1})
      end
      assert_equal [["test", @time, {"a"=>1, "time" => timef.call(@time)}].to_msgpack], d.formatted
    end
  end

  class WriteTest < self
    def setup
      Timecop.freeze(Time.parse("2011-01-02 13:14:00 UTC"))
    end

    def test_write
      d = create_driver
      time = Fluent::Engine.now.to_i
      d.run(default_tag: 'test') do
        d.feed(time, {"a"=>2})
        d.feed(time, {"a"=>3})
      end

      assert_equal "2", d.instance.redis.hget("test.#{time}.0", "a")
      assert_equal "3", d.instance.redis.hget("test.#{time}.1", "a")
    end

    def test_write_with_insert_key_prefix
      d = create_driver CONFIG + %[
        insert_key_prefix "${tag[1]}.${tag[2]}"
      ]
      time = Fluent::Engine.now.to_i
      d.run(default_tag: 'prefix.insert.test') do
        d.feed(time, {"a"=>2})
        d.feed(time, {"a"=>3})
      end

      assert_equal "2", d.instance.redis.hget("insert.test.#{time}.0", "a")
      assert_equal "3", d.instance.redis.hget("insert.test.#{time}.1", "a")
    end

    def test_write_with_custom_strftime_format
      d = create_driver CONFIG + %[
        strftime_format "%Y%m%d.%H%M%S"
      ]
      now = Time.parse("2011-01-02 13:14:00 UTC").localtime
      time = Fluent::EventTime.from_time(now)
      strtime = now.strftime("%Y%m%d.%H%M%S")
      d.run(default_tag: 'test') do
        d.feed(time, {"a"=>4})
        d.feed(time, {"a"=>5})
      end

      assert_equal "4", d.instance.redis.hget("test.#{strtime}.0", "a")
      assert_equal "5", d.instance.redis.hget("test.#{strtime}.1", "a")
    end

    def test_write_with_allow_duplicate
      d = create_driver CONFIG + %[
        allow_duplicate_key true
      ]
      time = event_time("2011-01-02 13:14:00 UTC")
      d.run(default_tag: 'test.duplicate') do
        d.feed(time, {"a"=>6})
        d.feed(time, {"a"=>7})
      end

      assert_equal "7", d.instance.redis.hget("test.duplicate", "a")
    end

    def teardown
      Timecop.return
    end
  end
end
