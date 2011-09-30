# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "fluent-plugin-redis"
  s.version     = "0.1.0"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Yuki Nishijima"]
  s.date        = %q{2011-09-30}
  s.email       = "mail@yukinishijima.net"
  s.homepage    = "http://github.com/yuki24/fluent-plugin-redis"
  s.summary     = "Redis output plugin for Fluent"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency %q<fluent>, ["~> 0.9.14"]
  s.add_dependency %q<redis>, ["~> 2.2.2"]
end
