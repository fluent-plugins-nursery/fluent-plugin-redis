module Fluent
  class RedisOutput < BufferedOutput
    Fluent::Plugin.register_output('redis', self)

    def initialize
      super
      require 'redis'
      require 'msgpack'
    end

    def configure(conf)
      super

      @host = conf.has_key?('host') ? conf['host'] : 'localhost'
      @port = conf.has_key?('port') ? conf['port'] : 6379
      @db = conf.has_key?('db') ? conf['db'] : nil

      if conf.has_key?('namespace')
        puts "Namespace option has been removed from fluent-plugin-radis 0.1.1. Please add or remove the namespace #{conf['namespace']} manually."
      end
    end

    def start
      super

      @redis = Redis.new(:host => @host, :port => @port,
                         :thread_safe => true, :db => @db)
    end

    def shutdown
      @redis.quit
    end

    def format(tag, event)
      # event.record[:identifier]=[tag,event.time].join(".")
      # event.record.to_msgpack
      identifier=[tag,event.time].join(".")
      [ identifier, event.record ].to_msgpack
    end

    def write(chunk)
      @redis.pipelined {
        chunk.open { |io|
          begin
            MessagePack::Unpacker.new(io).each { |record|
              # identifier = record["identifier"].to_s
              # record.delete("identifier")
              # @redis.mapped_hmset identifier, record
              @redis.mapped_hmset record[0], record[1]
            }
          rescue EOFError
            # EOFError always occured when reached end of chunk.
          end
        }
      }
    end
  end
end
