module Fluent
  class RedisOutput < BufferedOutput
    Fluent::Plugin.register_output('redis', self)
    attr_reader :redis

    config_param :host, :string, :default => 'localhost'
    config_param :port, :integer, :default => 6379
    config_param :db_number, :integer, :default => 0

    # To support log_level option implemented by Fluentd v0.10.43
    unless method_defined?(:log)
      define_method("log") { $log }
    end

    def initialize
      super
      require 'redis'
      require 'msgpack'
    end

    def configure(conf)
      super

      if conf.has_key?('namespace')
        log.warn "namespace option has been removed from fluent-plugin-redis 0.1.3. Please add or remove the namespace '#{conf['namespace']}' manually."
      end
    end

    def start
      super

      @redis = Redis.new(:host => @host, :port => @port,
                         :thread_safe => true, :db => @db_number)
    end

    def shutdown
      @redis.quit
      super
    end

    def format(tag, time, record)
      identifier = [tag, time].join(".")
      [identifier, record].to_msgpack
    end

    def write(chunk)
      @redis.pipelined {
        chunk.open { |io|
          begin
            MessagePack::Unpacker.new(io).each.each_with_index { |record, index|
              @redis.mapped_hmset "#{record[0]}.#{index}", record[1]
            }
          rescue EOFError
            # EOFError always occured when reached end of chunk.
          end
        }
      }
    end
  end
end
