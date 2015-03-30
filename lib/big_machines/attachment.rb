module BigMachines
  class Attachment
    attr_reader :raw_attachment

    def initialize(entry)
      @raw_attachment = entry
    end

    def write(file_path)
      data = Base64.strict_decode64(@raw_attachment[:file_content])
      File.open(file_path, 'wb') do |f|
        f.write(data)
      end
    end

    def method_missing(method, *args)
      @raw_attachment[method]
    end

  end
end