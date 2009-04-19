require 'net/ntlm'

# Rack-ntlm
module Rack

  class Ntlm
    
    def initialize(app)
      @app = app
    end

    def auth(user, domain)
      # ldap auth or anythings else...
      1
    end

    def call(env)

      @status, @headers, @response = @app.call(env)

      if @headers["Authorization"].blank?
        @headers["WWW-Authenticate"] = "NTLM"
        @status = 401
      end

      if /^(NTLM|Negotiate) (.+)/ =~ env["HTTP_AUTHORIZATION"]

        message = Net::NTLM::Message.decode64($2)

        if message.type == 1 
          type2 = Net::NTLM::Message::Type2.new
      		@headers["WWW-Authenticate"] = "NTLM " + type2.encode64
      		@status = 401
        end

        if message.type == 3
          if auth(message.user, message.domain)
            @status = 200
          end

        end
    	end

      [@status, @headers, @response]

    end

  end

end