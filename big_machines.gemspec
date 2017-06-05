# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'big_machines/version'

Gem::Specification.new do |spec|
  spec.name          = 'big_machines'
  spec.version       = BigMachines::VERSION
  spec.authors       = ['Joe Heth']
  spec.email         = ['joeheth@gmail.com']
  spec.summary       = %(Communicate with BigMachine's SOAP API)
  spec.description   = %(BigMachine's SOAP API Implementation)
  spec.homepage      = 'https://github.com/TinderBox/big_machines'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'savon', '>= 2.3.0', '< 3.0.0'

  spec.add_development_dependency 'rake', '>= 10.1'
  spec.add_development_dependency 'rspec', '>= 3.2.0', '< 4.0.0'
  spec.add_development_dependency 'webmock', '>= 2.2.0', '< 4.0.0'
  spec.add_development_dependency 'simplecov', '>= 0.11.2', '< 1.0.0'
  spec.add_development_dependency 'vcr', '>= 3.0.0', '< 4.0.0'
  spec.add_development_dependency 'pry-byebug', '>= 3.0.0', '< 4.0.0'
  spec.add_development_dependency 'awesome_print', '>= 1.5.0', '< 2.0.0'
end
