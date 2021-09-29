require 'redis'
require 'msgpack'
require 'fluent/plugin/output'

module Fluent::Plugin
  class RedisOutput < Output
    Fluent::Plugin.register_output('redis', self)

    helpers :compat_parameters, :inject, :formatter

    DEFAULT_BUFFER_TYPE = "memory"
    DEFAULT_TTL_VALUE = -1

    attr_reader :redis

    config_param :host, :string, default: 'localhost'
    config_param :port, :integer, default: 6379
    config_param :db_number, :integer, default: 0
    config_param :password, :string, default: nil, secret: true
    config_param :insert_key_prefix, :string, default: "${tag}"
    config_param :strftime_format, :string, default: "%s"
    config_param :allow_duplicate_key, :bool, default: false
    config_param :ttl, :integer, default: DEFAULT_TTL_VALUE
    config_param :command, :enum, list: [:hset, :publish], default: :hset

    config_section :buffer do
      config_set_default :@type, DEFAULT_BUFFER_TYPE
      config_set_default :chunk_keys, ['tag', 'time']
      config_set_default :timekey, 60
    end

    config_section :format do
      config_set_default :@type, 'json'
      config_set_default :add_newline, false
    end

    def configure(conf)
      compat_parameters_convert(conf, :buffer, :inject)
      @running_multi_workers = system_config.workers > 1
      super

      if conf.has_key?('namespace')
        log.warn "namespace option has been removed from fluent-plugin-redis 0.1.3. Please add or remove the namespace '#{conf['namespace']}' manually."
      end
      raise Fluent::ConfigError, "'tag' in chunk_keys is required." if not @chunk_key_tag
      raise Fluent::ConfigError, "'time' in chunk_keys is required." if not @chunk_key_time
      @unpacker = Fluent::Engine.msgpack_factory.unpacker
      @formatter = formatter_create
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

    def formatted_to_msgpack_binary
      true
    end

    def multi_workers_ready?
      true
    end

    def redis_publish(chunk)
      tag, time = expand_placeholders(chunk)
      chunk.each do |_tag, _time, record|
        @redis.publish "#{tag}", @formatter.format(tag, time, record)
      end
    end

    def redis_hset(chunk)
      tag, time = expand_placeholders(chunk)
      @redis.pipelined {
        unless @allow_duplicate_key
          stream = chunk.to_msgpack_stream
          @unpacker.feed_each(stream).with_index { |record, index|
            identifier = if @running_multi_workers
                           [tag, time, fluentd_worker_id].join(".")
                         else
                           [tag, time].join(".")
                         end
            @redis.multi do
              @redis.mapped_hmset "#{identifier}.#{index}", record[2]
              @redis.expire "#{identifier}.#{index}", @ttl if @ttl > 0
            end
          }
        else
          chunk.each do |_tag, _time, record|
            @redis.multi do
              @redis.mapped_hmset "#{tag}", record
              @redis.expire "#{tag}", @ttl if @ttl > 0
            end
          end
        end
      }
    end

    def write(chunk)
      case @command
      when :hset
        redis_hset(chunk)
      when :publish
        redis_publish(chunk)
      else
        log.error "unknown command #{@command}"
      end
    end

    private

    def expand_placeholders(chunk)
      tag = extract_placeholders(@insert_key_prefix, chunk)
      time = extract_placeholders(@strftime_format, chunk)
      return tag, time
    end
  end
end
