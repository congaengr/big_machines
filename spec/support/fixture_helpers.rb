module FixtureHelpers
  module InstanceMethods
    def stub_commerce_request(options = {})
      options = options.merge(headers: { service: :commerce })
      stub_api_request(options)
    end

    def stub_api_request(options = {})
      options = {
        method: :post,
        status: 200,
      }.merge(options)

      instance_url = 'https://newtempge.bigmachines.com/v1_0/receiver'
      stub = stub_request(options[:method], instance_url)
      stub = stub.with(body: soap_envelope(options[:headers], options[:with_body]))
      if options[:fixture]
        stub = stub.to_return(
          status: options[:status],
          body: fixture(options[:fixture]),
          headers: { 'Content-Type' => 'text/xml;charset=UTF-8'}
        )
      end
      stub
    end

    def stub_login_request(options = {})
      server_url = 'https://newtempge.bigmachines.com/v1_0/receiver'
      stub = stub_request(:post, server_url)
      stub = stub.with(body: soap_envelope(options[:headers], options[:with_body]))
      stub
    end

    def fixture(f)
      File.read(File.expand_path("../../fixtures/#{f}.xml", __FILE__))
    end

    def soap_envelope(headers, body)
%(<?xml version="1.0" encoding="UTF-8"?>
<env:Envelope xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:targetNamespace="urn:soap.bigmachines.com" xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">
#{soap_headers(headers)}
<env:Body>
#{body}
</env:Body>
</env:Envelope>
).gsub(/[\n\t]/, '')
    end

    def soap_headers(params = {})
      service = params.is_a?(Hash) ? params[:service] : :security

      if service == :security
        category = 'Security'
        schema = 'https://newtempge.bigmachines.com/bmfsweb/newtempge/schema/v1_0/security/Security.xsd'
      else
        category = 'Commerce'
        schema = 'https://newtempge.bigmachines.com/bmfsweb/newtempge/schema/v1_0/commerce/quotes_process_bmClone_16.xsd'
      end

      %(<env:Header>
<bm:category xmlns:bm="urn:soap.bigmachines.com">#{category}</bm:category>
<bm:xsdInfo xmlns:bm="urn:soap.bigmachines.com">
<bm:schemaLocation>#{schema}</bm:schemaLocation>
</bm:xsdInfo>
</env:Header>)
    end
  end
end

RSpec.configure do |config|
  config.include FixtureHelpers::InstanceMethods
end
