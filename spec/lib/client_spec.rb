require 'spec_helper'

describe BigMachines::Client do
  let(:subject) { BigMachines::Client.new('newtempge', process_name: 'quotes_process_bmClone_16')}

  let(:login_body) {
    %Q{<targetNamespace:login>
<targetNamespace:userInfo>
<targetNamespace:username>jheth</targetNamespace:username>
<targetNamespace:password>changeme</targetNamespace:password>
</targetNamespace:userInfo>
</targetNamespace:login>}
  }

  describe "#operations" do
    it "should return list of operations from the wsdl" do
      subject.operations.should be_a(Array)
      subject.operations.should include(:get_user_info, :login, :logout, :set_session_currency)
    end
  end

  describe "#login" do
    it "authenticates with username and password" do
      stub = stub_login_request({with_body: login_body})
      stub.to_return(:status => 200, :body => fixture("login_response"))

      subject.login('jheth', 'changeme')
    end
  end

  describe "#logout" do
    it "logout current session" do
      body = %Q{<targetNamespace:logout></targetNamespace:logout>}
      stub = stub_api_request({with_body: body, fixture: 'logout_response'})

      response = subject.logout
      expect(response[:status][:success]).to eq(true)
    end

  end

  describe "#get_user_info" do
    it "retrieve user info" do
      body = %Q{<targetNamespace:getUserInfo></targetNamespace:getUserInfo>}
      stub = stub_api_request({with_body: body, fixture: 'get_user_info_response'})

      response = subject.get_user_info
      user_info = response[:user_info]
      expect(user_info[:company_name]).to eq('newtempge')
      expect(user_info[:first_name]).to eq('Joe')
      expect(user_info[:last_name]).to eq('Heth')
    end
  end

  describe "#set_session_currency" do
    it "sets currency for existing session" do
      body = %Q{<targetNamespace:setSessionCurrency><targetNamespace:sessionCurrency>USD</targetNamespace:sessionCurrency></targetNamespace:setSessionCurrency>}
      stub = stub_api_request({with_body: body, fixture: 'set_session_currency_response'})

      response = subject.set_session_currency('USD')
      expect(response[:status][:success]).to eq(true)
    end
  end

  context "Commerce API" do
    describe "getTransaction" do
      it "returns transaction with specific attributes" do

        body = %Q{
  <bm:getTransaction>
    <bm:transaction>
      <bm:id>26539349</bm:id>
      <bm:return_specific_attributes>
        <bm:documents>
          <bm:document>
            <bm:var_name>quote_process</bm:var_name>
          </bm:document>
        </bm:documents>
      </bm:return_specific_attributes>
    </bm:transaction>
  </bm:getTransaction>
        }.gsub(/^\s+/, '').gsub(/[\n]/, '').gsub("bm:", "targetNamespace:")

        stub = stub_commerce_request({with_body: body, fixture: 'get_transaction_response'})

        transaction = subject.get_transaction(26539349)
        expect(transaction).to be_a(BigMachines::Transaction)

        expect(transaction.id).to eq('26539349')
        expect(transaction.language_pref).to eq('English')

        quote_process = transaction.quote
        expect(quote_process).to be_a(Hash)

        quote_line_items = transaction.quote_line_items
        expect(quote_line_items).to be_a(Array)

        expect(quote_line_items.length).to eq(109)
        expect(quote_line_items.first[:_model_id]).to eq("17400975")
      end
    end
  end

end
