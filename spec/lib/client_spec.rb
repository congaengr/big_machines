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
      expect(response["status"]["success"]).to eq(true)
    end

  end

  describe "#get_user_info" do
    it "retrieve user info" do
      body = %Q{<targetNamespace:getUserInfo></targetNamespace:getUserInfo>}
      stub = stub_api_request({with_body: body, fixture: 'get_user_info_response'})

      response = subject.get_user_info
      user_info = response["userInfo"]
      expect(user_info["company_name"]).to eq('newtempge')
      expect(user_info["first_name"]).to eq('Joe')
      expect(user_info["last_name"]).to eq('Heth')
    end
  end

  describe "#set_session_currency" do
    it "sets currency for existing session" do
      body = %Q{<targetNamespace:setSessionCurrency><targetNamespace:sessionCurrency>USD</targetNamespace:sessionCurrency></targetNamespace:setSessionCurrency>}
      stub = stub_api_request({with_body: body, fixture: 'set_session_currency_response'})

      response = subject.set_session_currency('USD')
      expect(response["status"]["success"]).to eq(true)
    end
  end

  context "Commerce API" do
    describe "getTransaction" do
      it "returns transaction with specific attributes" do

        # NOTE: return_specific_attributes is optional
        # All attributes are returned when not defined.
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
        expect(quote_process["_document_number"]).to eq("1")

        quote_line_items = transaction.quote_line_items
        expect(quote_line_items).to be_a(Array)

        expect(quote_line_items.length).to eq(109)
        expect(quote_line_items.first["_model_id"]).to eq("17400975")
      end

    it "returns not found error" do
        # NOTE: return_specific_attributes is optional
        # All attributes are returned when not defined.
        body = %Q{
  <bm:getTransaction>
    <bm:transaction>
      <bm:id>265393499</bm:id>
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

        stub = stub_commerce_request({with_body: body, fixture: 'get_transaction_not_found_response'})

        expect {
          subject.get_transaction(265393499)
        }.to raise_error(Savon::SOAPFault)
      end

    end

    describe "updateTransaction" do
      it "confirms that transaction was updated" do

        body = %Q{
  <bm:updateTransaction>
    <bm:transaction>
      <bm:id>26539349</bm:id>
        <bm:data_xml>
          <bm:quote_process bs_id="26539349" data_type="0" document_number="1">
            <bm:opportunityName_quote>Test Oppty Auto Approval TinderBox</bm:opportunityName_quote>
            <bm:siteName_quote>MY DUMMY SITE</bm:siteName_quote>
            <bm:notesCMPM_es>http://subdomain.mytinder.com/view/X2Y58?version=1</bm:notesCMPM_es>
          </bm:quote_process>
        </bm:data_xml>
        <bm:action_data>
          <bm:action_var_name>_update_line_items</bm:action_var_name>
        </bm:action_data>
    </bm:transaction>
  </bm:updateTransaction>
        }.gsub(/^\s+/, '').gsub(/[\n]/, '').gsub("bm:", "targetNamespace:")

        stub = stub_commerce_request({with_body: body, fixture: 'update_transaction_response'})

        data = {
          opportunityName_quote: "Test Oppty Auto Approval TinderBox",
          siteName_quote: "MY DUMMY SITE",
          notesCMPM_es: "http://subdomain.mytinder.com/view/X2Y58?version=1"
        }
        response = subject.update_transaction(26539349, data)

        expect(response["status"]["success"]).to eq(true)
      end
    end

    describe "exportFileAttachments" do
      it "returns metadata for attachments" do

        body = %Q{
  <bm:exportFileAttachments>
    <bm:mode>metadata</bm:mode>
    <bm:inline>true</bm:inline>
    <bm:attachments>
      <bm:attachment>
        <bm:document_number>1</bm:document_number>
        <bm:variable_name>uploadEngineeringTemplate_File</bm:variable_name>
      </bm:attachment>
    </bm:attachments>
    <bm:transaction>
      <bm:process_var_name>quotes_process_bmClone_16</bm:process_var_name>
      <bm:id>34706909</bm:id>
    </bm:transaction>
  </bm:exportFileAttachments>
        }.gsub(/^\s+/, '').gsub(/[\n]/, '').gsub("bm:", "targetNamespace:")

        stub = stub_commerce_request({with_body: body, fixture: 'export_file_attachments_metadata_response'})

        attachments = subject.get_attachment(34706909, "uploadEngineeringTemplate_File", mode: 'metadata')

        expect(attachments).to be_a(Array)
        expect(attachments.size).to eq(1)

        file = attachments.first
        expect(file.filename).to eq('1020636-38959 Rev 0.docx')
        expect(file.size).to eq('404695')
        expect(file.added_date).to eq('2015-03-25 13:09:39')
        expect(file.last_modified_date).to eq('2015-03-25 13:09:39')
      end

      it "returns inline content for attachments" do

        body = %Q{
  <bm:exportFileAttachments>
    <bm:mode>content</bm:mode>
    <bm:inline>true</bm:inline>
    <bm:attachments>
      <bm:attachment>
        <bm:document_number>1</bm:document_number>
        <bm:variable_name>uploadEngineeringTemplate_File</bm:variable_name>
      </bm:attachment>
    </bm:attachments>
    <bm:transaction>
      <bm:process_var_name>quotes_process_bmClone_16</bm:process_var_name>
      <bm:id>34706909</bm:id>
    </bm:transaction>
  </bm:exportFileAttachments>
        }.gsub(/^\s+/, '').gsub(/[\n]/, '').gsub("bm:", "targetNamespace:")

        stub = stub_commerce_request({with_body: body, fixture: 'export_file_attachments_content_inline_response'})

        attachments = subject.get_attachment(34706909, "uploadEngineeringTemplate_File")

        expect(attachments).to be_a(Array)
        expect(attachments.size).to eq(1)

        file = attachments.first
        expect(file.filename).to eq('1020636-38959 Rev 0.docx')
        expect(file.file_content).to eq('UEsDBBQABgAIAAAAIQDQt2tlKQIAAJILAAATAACiBAIooAACAAAA==')
      end

      it "returns content for attachments using mime boundary" do

        body = %Q{
  <bm:exportFileAttachments>
    <bm:mode>content</bm:mode>
    <bm:inline>false</bm:inline>
    <bm:attachments>
      <bm:attachment>
        <bm:document_number>1</bm:document_number>
        <bm:variable_name>uploadEngineeringTemplate_File</bm:variable_name>
      </bm:attachment>
    </bm:attachments>
    <bm:transaction>
      <bm:process_var_name>quotes_process_bmClone_16</bm:process_var_name>
      <bm:id>34706909</bm:id>
    </bm:transaction>
  </bm:exportFileAttachments>
        }.gsub(/^\s+/, '').gsub(/[\n]/, '').gsub("bm:", "targetNamespace:")

        stub = stub_commerce_request({with_body: body, fixture: 'export_file_attachments_content_response'})

        attachments = subject.get_attachment(34706909, "uploadEngineeringTemplate_File", inline: false)

        expect(attachments).to be_a(Array)
        expect(attachments.size).to eq(1)

        file = attachments.first
        expect(file.filename).to eq('1020636-38959 Rev 0.docx')
        expect(file.file_content["@bm:href"]).to eq("cid:1020636-38959_Rev_0.docx@newtempge.bigmachines.com")
      end

    end

    describe "importFileAttachments" do
      it "uploads new file attachment" do

        contents = "This is a test"
        encoded = Base64.strict_encode64(contents)

        body = %Q{
  <bm:importFileAttachments>
    <bm:mode>update</bm:mode>
    <bm:attachments>
      <bm:attachment>
        <bm:document_number>1</bm:document_number>
        <bm:variable_name>uploadEngineeringTemplate_File</bm:variable_name>
        <bm:filename>NewProposal.txt</bm:filename>
        <bm:file_content>#{encoded}</bm:file_content>
      </bm:attachment>
    </bm:attachments>
    <bm:transaction>
      <bm:process_var_name>quotes_process_bmClone_16</bm:process_var_name>
      <bm:id>34706909</bm:id>
    </bm:transaction>
  </bm:importFileAttachments>
        }.gsub(/^\s+/, '').gsub(/[\n]/, '').gsub("bm:", "targetNamespace:")

        stub = stub_commerce_request({with_body: body, fixture: 'import_file_attachments_response'})

        File.open('NewProposal.txt', 'w') {|f| f.write(contents) }
        file = File.open('NewProposal.txt')
        response = subject.upload_attachment(34706909, file, "uploadEngineeringTemplate_File")

        File.unlink('NewProposal.txt')

        expect(response["status"]["success"]).to eq(true)
      end

      it "deletes file attachment" do

        body = %Q{
  <bm:importFileAttachments>
    <bm:mode>delete</bm:mode>
    <bm:attachments>
      <bm:attachment>
        <bm:document_number>1</bm:document_number>
        <bm:variable_name>uploadEngineeringTemplate_File</bm:variable_name>
      </bm:attachment>
    </bm:attachments>
    <bm:transaction>
      <bm:process_var_name>quotes_process_bmClone_16</bm:process_var_name>
      <bm:id>34706909</bm:id>
    </bm:transaction>
  </bm:importFileAttachments>
        }.gsub(/^\s+/, '').gsub(/[\n]/, '').gsub("bm:", "targetNamespace:")

        stub = stub_commerce_request({with_body: body, fixture: 'import_file_attachments_response'})

        response = subject.delete_attachment(34706909, "uploadEngineeringTemplate_File")

        expect(response["status"]["success"]).to eq(true)
      end

    end

  end
  # Commerce API
end
