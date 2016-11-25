require 'fluent/test'
require 'fluent/plugin/out_redis'

class FileOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup

    @d = create_driver %[
      host localhost
      port 6379
      db_number 1
    ]
    @time = Time.parse("2011-01-02 13:14:15 UTC").to_i
  end

  def create_driver(conf = CONFIG)
    Fluent::Test::BufferedOutputTestDriver.new(Fluent::RedisOutput).configure(conf)
  end

  def test_configure
    assert_equal 'localhost', @d.instance.host
    assert_equal 6379, @d.instance.port
    assert_equal 1, @d.instance.db_number
    assert_nil @d.instance.password
  end

  def test_format
    @d.emit({"a"=>1}, @time)
    @d.expect_format(["test.#{@time}", {"a"=>1}].to_msgpack)
    @d.run
  end

  def test_write
    @d.emit({"a"=>2}, @time)
    @d.emit({"a"=>3}, @time)
    @d.run

    assert_equal "2", @d.instance.redis.hget("test.#{@time}.0", "a")
    assert_equal "3", @d.instance.redis.hget("test.#{@time}.1", "a")
  end
end
