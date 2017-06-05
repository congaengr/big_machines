require 'base64'

module BigMachines
  class MimeAttachment
    attr_reader :raw_attachment

    def initialize(multi_part)
      @xml_part, @binary_part = *multi_part.attachments
      parser = Nori.new(strip_namespaces: true)
      hash = parser.parse(@xml_part.content)
      @raw_attachment = hash['Envelope']['Body']['exportFileAttachmentsResponse']
      @attachment = @raw_attachment['attachments']['attachment']
    end

    def size
      @binary_part.content.length
    end

    def write(file_path)
      File.open(file_path, 'wb') do |f|
        f.write(@binary_part.content)
      end
    end

    def method_missing(method, *args)
      @raw_attachment[method.to_s] || @attachment[method.to_s]
    end
  end
end
