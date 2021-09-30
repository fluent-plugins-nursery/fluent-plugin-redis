require 'redis'
require 'fluent/plugin/input'

module Fluent::Plugin
  class RedisInput < Input
    Fluent::Plugin.register_input('redis', self)

    helpers :thread, :parser

    config_param :tag, :string
    config_param :host, :string, default: 'localhost'
    config_param :port, :integer, default: 6379
    config_param :db_number, :integer, default: 0
    config_param :password, :string, default: nil, secret: true
    config_param :channel, :string
    config_param :intercom, :string, default: 'fluentd:input:redis'

    def configure(conf)
      super
      raise Fluent::ConfigError, "redis: 'tag' parameter is required" unless @tag
      raise Fluent::ConfigError, "redis: 'channel' parameter is required" unless @channel

      parser_config = conf.elements('parse').first
      unless parser_config
        raise Fluent::ConfigError, "redis: <parse> section is required."
      end

      @parser = parser_create(conf: parser_config)
    end

    def multi_workers_ready?
      false
    end

    def start
      super
      thread_create(:redis_input, &method(:run))
    end

    def multi_workers_ready?
      true
    end

    def redis_client
      options = {
        host: @host,
        port: @port,
        thread_safe: true,
        db: @db_number
      }
      options[:password] = @password if @password
      Redis.new(options)
    end

    def shutdown
      log.info "closing Redis connection..."
      redis = redis_client
      redis.publish(@intercom, 'shutdown')
      redis.quit
      thread_wait_until_stop
      super
    end

    def run
      redis = redis_client
      begin
        redis.psubscribe([@channel, @intercom]) do |on|
          on.psubscribe do |channel, sub|
            unless channel === @intercom
              log.info "subscribed to ##{channel} (#{sub} subs)"
            end
          end

          on.pmessage do |pattern, channel, msg|
            unless channel === @intercom
              @parser.parse(msg) do |time, record|
                unless time && record
                  log.warn "pattern not matched", message: msg
                  next
                end
                tag = "#{@tag}.#{channel}"
                router.emit(tag, time, record)
              end
            else
              redis.quit
            end
          end

          on.punsubscribe do |channel, sub|
            unless channel === @intercom
              log.info "unsubscribe from ##{channel} (#{sub} subs)"
            end
          end
        end
      rescue => e
        log.error "error while subscribing Redis: '#{e}'"
        retry
      end
    end
  end
end
