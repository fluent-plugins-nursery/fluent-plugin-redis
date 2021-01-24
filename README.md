# Redis output plugin for Fluent

![Testing on Ubuntu](https://github.com/fluent-plugins-nursery/fluent-plugin-redis/workflows/Testing%20on%20Ubuntu/badge.svg)

fluent-plugin-redis is a fluent plugin to output to redis.

## Requirements

|fluent-plugin-redis|     fluentd      |  ruby  |
|-------------------|------------------|--------|
|     >= 0.3.0      | >= 0.14.8        | >= 2.1 |
|     == 0.2.3      | ~> 0.12.0 *      | >= 1.9 |
|      < 0.2.3      | >= 0.10.0, < 2 * | >= 1.9 |

* May not support all future fluentd features

## Installation

What you have to do is only installing like this:

    gem install fluent-plugin-redis

Then fluent automatically loads the plugin installed.

## Configuration

### Example

    <match redis.**>
      @type redis

      # host localhost
      # port 6379
      # db_number 0
      # password hogefuga
      # insert_key_prefix '${tag}'
      # strftime_format "%s"
      # allow_duplicate_key false
      # ttl 300
    </match>

### Parameter

|parameter|description|default|
|---|---|---|
|host|The hostname of Redis server|`localhost`|
|port|The port number of Redis server|`6379`|
|db_number|The number of database|`0`|
|password|The password of Redis. If requirepass is set, please specify this|nil|
|insert\_key\_prefix|Users can set '${tag}' or ${tag[0]}.${tag[1]} or ...?|`${tag}`|
|strftime\_format|Users can set strftime format.<br> "%s" will be replaced into unixtime. "%Y%m%d.%H%M%S" will be replaced like as 20161202.112335|`"%s"`|
|allow\_duplicate\_key|Allow duplicated insert key. It will work as update values|`false`|
|ttl|The value of TTL. If 0 or negative value is set, ttl is not set in each key|`-1`|





### With multi workers

fluent-plugin-redis can handle <em>multi workers</em>.
This feature can be enabled with the following configuration:

    <system>
      workers n # where n >= 2.
    </system>

### Notice

<em>insert_key_prefix</em>, <em>strftime_format</em>, and <em>allow_duplicate_key</em> are newly added config parameters.

They can use v0.3.0 or later. To use this parameters, users must update Fluentd to v0.14 or later and this plugin to v0.3.0 or later.

<em>multi workers</em> are newly introduced feature in Fluentd v0.14.

It can use this feature in this plugin in v0.3.3 or later.

## Contributing to fluent-plugin-redis

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2011- Yuki Nishijima

## License

Apache License, Version 2.0
