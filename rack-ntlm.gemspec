# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "rack-ntlm/version"

Gem::Specification.new do |s|
  s.name        = "rack-ntlm"
  s.version     = Rack::Ntlm::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Luca Simone"]
  s.email       = ["info@lucasimone.info"]
  s.homepage    = "https://github.com/lukefx/rack-ntlm"
  s.summary     = %q{Rack module for NTLM Auth}
  s.description = %q{Rack module for NTLM Authentication against an ActiveDirectory or other LDAP Server}

  s.rubyforge_project = "rack-ntlm"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "rubyntlm"
  s.add_dependency "net-ldap"

end
