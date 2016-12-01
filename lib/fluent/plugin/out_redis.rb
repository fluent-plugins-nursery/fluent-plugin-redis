require 'redis'
require 'msgpack'
require 'fluent/plugin/output'

module Fluent::Plugin
  class RedisOutput < Output
    Fluent::Plugin.register_output('redis', self)

    helpers :compat_parameters

    DEFAULT_BUFFER_TYPE = "memory"

    attr_reader :redis

    config_param :host, :string, :default => 'localhost'
    config_param :port, :integer, :default => 6379
    config_param :db_number, :integer, :default => 0
    config_param :password, :string, :default => nil, :secret => true

    config_section :buffer do
      config_set_default :@type, DEFAULT_BUFFER_TYPE
      config_set_default :chunk_keys, ['tag']
    end

    def initialize
      super
    end

    def configure(conf)
      compat_parameters_convert(conf, :buffer)
      super

      if conf.has_key?('namespace')
        log.warn "namespace option has been removed from fluent-plugin-redis 0.1.3. Please add or remove the namespace '#{conf['namespace']}' manually."
      end
    end

    def start
      super

      options = {
        :host => @host,
        :port => @port,
        :thread_safe => true,
        :db => @db_number
      }
      options[:password] = @password if @password

      @redis = Redis.new(options)
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
