# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'big_machines/version'

Gem::Specification.new do |spec|
  spec.name          = "big_machines"
  spec.version       = BigMachines::VERSION
  spec.authors       = ["Joe Heth"]
  spec.email         = ["joeheth@gmail.com"]
  spec.summary       = %q{Communicate with BigMachine's SOAP API}
  spec.description   = %q{BigMachine's SOAP API Implementation}
  spec.homepage      = "https://github.com/TinderBox/big_machines"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'savon', '>= 2.3.0', '< 3.0.0'

  spec.add_development_dependency 'rake', '~> 10.1'
  spec.add_development_dependency 'rspec', '~> 2.14.0', '>= 2.14.0'
  spec.add_development_dependency 'webmock', '~> 1.13.0', '>= 1.13.0'
  spec.add_development_dependency 'simplecov', '~> 0.7.1', '>= 0.7.1'
end
