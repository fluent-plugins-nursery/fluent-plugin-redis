require 'redis'
require 'msgpack'
require 'fluent/plugin/output'

module Fluent::Plugin
  class RedisOutput < Output
    Fluent::Plugin.register_output('redis', self)

    helpers :compat_parameters, :inject

    DEFAULT_BUFFER_TYPE = "memory"

    attr_reader :redis

    config_param :host, :string, default: 'localhost'
    config_param :port, :integer, default: 6379
    config_param :db_number, :integer, default: 0
    config_param :password, :string, default: nil, secret: true
    config_param :insert_key_prefix, :string, default: "${tag}"
    config_param :strftime_format, :string, default: "%s"

    config_section :buffer do
      config_set_default :@type, DEFAULT_BUFFER_TYPE
      config_set_default :chunk_keys, ['tag', 'time']
      config_set_default :timekey, 60
    end

    def configure(conf)
      compat_parameters_convert(conf, :buffer, :inject)
      super

      if conf.has_key?('namespace')
        log.warn "namespace option has been removed from fluent-plugin-redis 0.1.3. Please add or remove the namespace '#{conf['namespace']}' manually."
      end
    end

    def start
      super

      options = {
        host: @host,
        port: @port,
        thread_safe: true,
        db: @db_number
      }
      options[:password] = @password if @password

      @redis = Redis.new(options)
    end

    def shutdown
      @redis.quit
      super
    end

    def format(tag, time, record)
      record = inject_values_to_record(tag, time, record)
      [tag, time, record].to_msgpack
    end

    def write(chunk)
      tag, time = expand_placeholders(chunk.metadata)
      @redis.pipelined {
        chunk.open { |io|
          begin
            MessagePack::Unpacker.new(io).each.each_with_index { |record, index|
              identifier = [tag, time].join(".")
              @redis.mapped_hmset "#{identifier}.#{index}", record[2]
            }
          rescue EOFError
            # EOFError always occured when reached end of chunk.
          end
        }
      }
    end

    private

    def expand_placeholders(metadata)
      tag = extract_placeholders(@insert_key_prefix, metadata)
      time = extract_placeholders(@strftime_format, metadata)
      return tag, time
    end
  end
end
