# Redis output plugin for Fluent

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

    <match redis.**>
      @type redis

      host localhost
      port 6379

      # database number is optional.
      db_number 0        # 0 is default
      # If requirepass is set, please specify this.
      # password hogefuga
      # Users can set '${tag}' or ${tag[0]}.${tag[1]} or ...?
      # insert_key_prefix '${tag}'
      # Users can set strftime format.
      # "%s" will be replaced into unixtime.
      # "%Y%m%d.%H%M%S" will be replaced like as 20161202.112335.
      # strftime_format "%s"
      # Allow insert key duplicate. It will work as update values.
      # allow_duplicate_key true
      # ttl 300 # If 0 is set, ttl is not set in each key.
    </match>


### Notice

<em>insert_key_prefix</em>, <em>strftime_format</em>, and <em>allow_duplicate_key</em> are newly added config parameters.

They can use v0.3.0 or later. To use this parameters, users must update Fluentd to v0.14 or later and this plugin to v0.3.0 or later.

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
