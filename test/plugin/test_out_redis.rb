require 'fluent/test'
require 'fluent/test/helpers'
require 'fluent/test/driver/output'
require 'fluent/plugin/out_redis'

class FileOutputTest < Test::Unit::TestCase
  include Fluent::Test::Helpers

  def setup
    Fluent::Test.setup

    @d = create_driver %[
      host localhost
      port 6379
      db_number 1
    ]
    @time = event_time("2011-01-02 13:14:15 UTC")
  end

  def create_driver(conf = CONFIG)
    Fluent::Test::Driver::Output.new(Fluent::Plugin::RedisOutput).configure(conf)
  end

  def test_configure
    assert_equal 'localhost', @d.instance.host
    assert_equal 6379, @d.instance.port
    assert_equal 1, @d.instance.db_number
    assert_nil @d.instance.password
  end

  def test_configure_with_password
    d = create_driver %[
      host localhost
      port 6379
      db_number 1
      password testpass
    ]
    assert_equal 'localhost', d.instance.host
    assert_equal 6379, d.instance.port
    assert_equal 1, d.instance.db_number
    assert_equal 'testpass', d.instance.password
  end

  def test_format
    @d.run(default_tag: 'test') do
      @d.feed(@time, {"a"=>1})
    end
    assert_equal [["test.#{@time}", {"a"=>1}].to_msgpack], @d.formatted
  end

  def test_write
    @d.run(default_tag: 'test') do
      @d.feed(@time, {"a"=>2})
      @d.feed(@time, {"a"=>3})
    end


    assert_equal "2", @d.instance.redis.hget("test.#{@time}.0", "a")
    assert_equal "3", @d.instance.redis.hget("test.#{@time}.1", "a")
  end
end
