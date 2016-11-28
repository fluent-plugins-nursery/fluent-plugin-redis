# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "fluent-plugin-redis"
  s.version     = "0.2.2"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Yuki Nishijima", "Hiroshi Hatake", "Kenji Okimoto"]
  s.date        = %q{2016-10-28}
  s.email       = ["mail@yukinishijima.net", "fluent@clear-code.com"]
  s.homepage    = "http://github.com/yuki24/fluent-plugin-redis"
  s.summary     = "Redis output plugin for Fluent"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency %q<fluentd>, [">= 0.10.0", "< 2"]
  s.add_dependency %q<redis>, ["~> 3.3.0"]
  s.add_development_dependency %q<rake>, [">= 11.3.0"]
  s.add_development_dependency %q<bundler>
  s.add_development_dependency %q<test-unit>, ["~> 3.1.0"]
  s.add_development_dependency %q<appraisal>, ["~> 2.1.0"]
end
