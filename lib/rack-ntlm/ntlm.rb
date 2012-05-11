module Rack
  class Ntlm
    
    def initialize(app, config = {})
      @app = app
      @config = {
        :uri_pattern => /\//,
        :port => 389,
        :search_filter => "(sAMAccountName=%1)"
      }.merge(config)
    end

    def auth(user)
      ldap = Net::LDAP.new
      ldap.host = @config[:host]
      ldap.port = @config[:port]
      ldap.base = @config[:base]
      ldap.auth @config[:auth][:username], @config[:auth][:password] if @config[:auth]
      ldap.search(:filter => @config[:search_filter].gsub("%1", user))
      ldap.bind_as(:base => @config[:base], :filter => @config[:search_filter].gsub("%1", user), :password => "1234")
    rescue => e
      false
    end

    def call(env)
    
      puts env.inspect
    
      if env['PATH_INFO'] =~ @config[:uri_pattern] && env['HTTP_AUTHORIZATION'].blank?
        return [401, {'WWW-Authenticate' => "NTLM"}, []]
      end

      if /^(NTLM|Negotiate) (.+)/ =~ env["HTTP_AUTHORIZATION"]

        message = Net::NTLM::Message.decode64($2)

        if message.type == 1 
          type2 = Net::NTLM::Message::Type2.new
          return [401, {"WWW-Authenticate" => "NTLM " + type2.encode64}, []]
        end

        if message.type == 3 && env['PATH_INFO'] =~ @config[:uri_pattern]
          user = Net::NTLM::decode_utf16le(message.user)
          if auth(user, pass)
            env['REMOTE_USER'] = user
          else
            return [401, {}, ["You are not authorized to see this page"]]
          end
        end
    	end

      @app.call(env)
    end

  end

end