require 'simplecov'
require 'webmock/rspec'
require 'vcr'
require 'pry-byebug'
require 'awesome_print'

SimpleCov.start do
  add_filter '/vendor/'
end

require 'bundler/setup'
Bundler.require :default, :test

WebMock.disable_net_connect!

VCR.configure do |config|
  config.ignore_localhost = true
  config.allow_http_connections_when_no_cassette = true
  config.cassette_library_dir = 'spec/cassettes'
  config.hook_into :webmock
end

RSpec.configure do |config|
  config.order = 'random'
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
end

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].each { |f| require f }
