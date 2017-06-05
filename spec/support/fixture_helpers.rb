module FixtureHelpers
  module InstanceMethods
    def fixture_path(f)
      File.expand_path("../../fixtures/#{f}", __FILE__)
    end

    def fixture(f)
      File.read(File.expand_path("../../fixtures/#{f}", __FILE__))
    end
  end
end

RSpec.configure do |config|
  config.include FixtureHelpers::InstanceMethods
end
