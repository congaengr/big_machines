module BigMachines
  class MultiPart
    def initialize(headers, body)
      @headers = headers
      @body = body
      @parts = []
      parse_body(body)
    end

    def attachments
      @parts
    end

    def parse_body(body)
      content_type_parts = {}
      @headers['content-type'].split(';').each do |part|
        next unless part.include?('=')
        key, value = *part.split('=')
        content_type_parts[key.strip] = value.strip.delete('"')
      end

      parts = body.split('--' + content_type_parts['boundary'] + "\r\n")
      parts.each do |p|
        next if p.empty? || p == '--'

        lines = p.split("\r\n")

        headers, data = lines.slice_after('').to_a
        headers.inject({}) do |hash, h|
          next hash if h.empty?
          key, value = *h.split(': ', 2)
          hash[key] = value.strip
          hash
        end

        content = data.first
        @parts << Part.new(headers, content)
      end
    end
  end

  class Part
    attr_reader :headers, :content
    def initialize(headers, content)
      @headers = headers
      @content = content
    end
  end
end
