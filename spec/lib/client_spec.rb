require 'spec_helper'

describe BigMachines::Client do
  let(:subject) do
    BigMachines::Client.new('newtempge', process_name: 'quotes_process_bmClone_16')
  end
  let(:username) { 'TBSupport '}
  let(:password) { 'changeme' }

  def login
    VCR.use_cassette('v1/login') do
      if @session_id
        subject.session_id = @session_id
      else
        subject.login(username, password)
        @session_id = subject.session_id
      end
    end
  end

  describe '#operations' do
    it 'returns list of operations from the wsdl' do
      expect(subject.operations).to be_an(Array)
      expect(subject.operations).to include(:get_user_info, :login, :logout, :set_session_currency)
    end
  end

  describe '#login' do
    it 'authenticates with username and password' do
      VCR.use_cassette('v1/login') do
        response = subject.login(username, password)
        expect(response).to eq true
      end
    end
  end

  describe '#logout' do
    # You need to login before you can call logout.
    # I did that manually for this test.
    it 'logout current session' do
      login

      VCR.use_cassette('v1/logout') do
        response = subject.logout
        expect(response['status']['success']).to eq(true)
      end
    end
  end

  describe '#get_user_info' do
    it 'retrieve user info' do
      login

      VCR.use_cassette('v1/get_user_info') do
        user_info = subject.get_user_info
        expect(user_info).to be_a(BigMachines::UserInfo)
        expect(user_info.company_name).to eq 'newtempge'
        expect(user_info.first_name).to eq 'Joe'
        expect(user_info.last_name).to eq 'Smith'
        expect(user_info.email).to eq 'support@gettinderbox.com'
      end
    end
  end

  describe '#set_session_currency' do
    it 'sets currency for existing session' do
      login

      VCR.use_cassette('v1/set_session_currency') do
        response = subject.set_session_currency('USD')
        expect(response['status']['success']).to eq(true)
      end
    end
  end

  context 'getTransaction' do
    before(:each) do
      VCR.use_cassette('v1/commerce_login') do
        subject.login(username, password)
      end
    end

    describe 'getTransaction' do
      it 'returns transaction with specific attributes' do
        VCR.use_cassette('v1/get_transaction_success') do
          transaction = subject.get_transaction(79817515)
          expect(transaction).to be_a(BigMachines::Transaction)

          expect(transaction.id).to eq('79817515')
          expect(transaction.language_pref).to eq('English')

          quote_process = transaction.quote
          expect(quote_process).to be_a(Hash)
          expect(quote_process['_document_number']).to eq('1')

          quote_line_items = transaction.quote_line_items
          expect(quote_line_items).to be_a(Array)

          expect(quote_line_items.length).to eq(9)
          expect(quote_line_items.first['_model_id']).to eq('17400975')
        end
      end

      it 'returns not found error' do
        VCR.use_cassette('v1/get_transaction_not_found') do
          expect {
            subject.get_transaction(265393499)
          }.to raise_error(Savon::SOAPFault, /No transactions were found for the given ID, 265393499/)
        end
      end
    end
  end

  describe 'updateTransaction' do
    before(:each) do
      VCR.use_cassette('v1/update_transaction_login') do
        subject.login(username, password)
      end
    end

    it 'confirms that transaction was updated' do
      data = {
        opportunityName_quote: 'Test Oppty Auto Approval TinderBox',
        siteName_quote: 'MY DUMMY SITE',
        notesCMPM_es: 'http://subdomain.octiv.com/view/X2Y58?version=1'
      }

      VCR.use_cassette('v1/update_transaction') do
        response = subject.update_transaction(34706909, data)
        expect(response['status']['success']).to eq(true)
      end
    end
  end

  describe 'exportFileAttachments' do
    before(:each) do
      VCR.use_cassette('v1/export_file_attachment_login') do
        subject.login(username, password)
      end
    end

    it 'returns metadata for attachments' do
      VCR.use_cassette('v1/export_file_attachments_metadata') do
        attachments = subject.get_attachment(34706909, 'uploadEngineeringTemplate_File', mode: 'metadata')

        expect(attachments).to be_a(Array)
        expect(attachments.size).to eq(1)

        file = attachments.first
        expect(file.filename).to eq('sample-document.docx')
        expect(file.size).to eq('117259')
        expect(file.added_date).to eq('2017-06-04 18:58:50')
        expect(file.last_modified_date).to eq('2017-06-04 19:31:51')
      end
    end

    it 'returns inline content for attachments' do
      VCR.use_cassette('v1/export_file_attachments_content_inline') do
        attachments = subject.get_attachment(34706909, 'uploadEngineeringTemplate_File')

        expect(attachments).to be_a(Array)
        expect(attachments.size).to eq(1)

        file = attachments.first
        expect(file.filename).to eq 'sample-document.docx'
        expect(file.file_content).to start_with 'UEsDBBQABgAIAAAAIQDpURCwjQEAAMIFAAATAAgCW0Nv'

        file.write('/tmp/sample.docx')
        expect(File.exist?('/tmp/sample.docx'))
        File.delete('/tmp/sample.docx')
      end
    end

    it 'returns content for attachments using mime boundary' do
      VCR.use_cassette('v1/export_file_attachments_content_mime') do
        attachment = subject.get_attachment(34706909, 'uploadEngineeringTemplate_File', inline: false)

        expect(attachment).to be_a(BigMachines::MimeAttachment)
        expect(attachment.filename).to include 'sample-document.docx'
        expect(attachment.file_content['@bm:href']).to include 'sample-document.docx@newtempge.bigmachines.com'

        attachment.write('/tmp/sample.docx')
        expect(File.size('/tmp/sample.docx')).to eq attachment.size

        File.delete('/tmp/sample.docx')
      end
    end
  end

  describe 'importFileAttachments' do
    before(:each) do
      VCR.use_cassette('v1/export_file_attachment_login') do
        subject.login(username, password)
      end
    end

    it 'uploads new file attachment' do
      file = File.open(fixture_path('sample-document.docx'))

      VCR.use_cassette('v1/import_file_attachments_upload') do
        response = subject.upload_attachment(34706909, file, 'uploadEngineeringTemplate_File')
        expect(response['status']['success']).to eq(true)
      end
    end

    it 'deletes file attachment' do
      VCR.use_cassette('v1/import_file_attachments_delete') do
        response = subject.delete_attachment(34706909, 'uploadEngineeringTemplate_File')
        expect(response['status']['success']).to eq(true)
      end
    end
  end
end
