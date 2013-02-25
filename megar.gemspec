# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'megar/version'

Gem::Specification.new do |gem|
  gem.name          = "megar"
  gem.version       = Megar::VERSION
  gem.authors       = ["Paul Gallagher"]
  gem.email         = ["gallagher.paul@gmail.com"]
  gem.description   = %q{Megaargh! A Ruby wrapper for the Mega API (mega.co.nz)}
  gem.summary       = %q{A Ruby wrapper and command-line tool for the Mega API (mega.co.nz)}
  gem.homepage      = "https://github.com/tardate/megar"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency(%q<getoptions>, [">= 0.3"])
  gem.add_runtime_dependency(%q<activesupport>, [">= 3.0.3"])

  gem.add_development_dependency(%q<bundler>, ["> 1.1.0"])
  gem.add_development_dependency(%q<rake>, ["~> 0.9.2.2"])
  gem.add_development_dependency(%q<rspec>, ["~> 2.8.0"])
  gem.add_development_dependency(%q<rdoc>, ["~> 3.11"])
  gem.add_development_dependency(%q<guard-rspec>, ["~> 1.2.0"])
  gem.add_development_dependency(%q<rb-fsevent>, ["~> 0.9.1"])

end
