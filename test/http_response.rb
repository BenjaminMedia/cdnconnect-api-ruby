
class CDNTestHttpResponse

    def initialize(status, body)
      @status = status
      @body = body
      return self
    end

    def status
        @status
    end

    def body
        @body
    end
    
end