module BigMachines
  class UserInfo
    attr_reader :hash

    def initialize(response)
      @hash = response['userInfo']
    end

    def method_missing(method, *args)
      if @hash.key?(method.to_s)
        @hash[method.to_s]
      else
        super
      end
    end

    def to_s
      @hash.to_s
    end
  end
end
