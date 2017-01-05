## 0.3.1

* Use public msgpack related API instead of internal its API
* Remove needless rescue block

## 0.3.0

* Migrate v0.14 API based plugin
* Allow duplicate insert key to support update values functionality
* Use v0.14's built-in placeholder functionality
  * Enabled to specify more flexible tag and time format for identifier

## 0.2.2

* Use redis-rb 3.2.x
* Support requirepass authentication

## 0.2.1

* Use config_param to clarify supported/default parameters.
* Use log instead of $log if avaliable.

## 0.2.0

* Support Fluentd v0.10.

## 0.1.3

* Colored the log message added on v0.1.2.

## 0.1.2

* Shows a warning message when trying to use namespace option.

## 0.1.1

* Disabled Redis::Namespace operation.

## 0.1.0

* Specified the versions of dependencies(fluent, redis and redis-namespace).

## 0.0.1

* This initial plugin is released.
