require 'net/ntlm'
require 'rack/auth/digest/nonce'

# Rack-ntlm
module Rack
  module Auth
    class NTLM < AbstractHandler

      class Request < Auth::AbstractRequest

        def message
          unless ntlm?
            raise ArgumentError
          end
          @message ||=  Net::NTLM::Message.decode64(params)
        end

        def ntlm?
          scheme == :ntlm || scheme == :negotiate
        end

        def nonce
          @nonce ||= Digest::Nonce.parse(cookies['_ntlm_challenge'])
        end

        # stolen from Rack::Request
        def cookies
          return {}  unless @env["HTTP_COOKIE"]

          if @env["rack.request.cookie_string"] == @env["HTTP_COOKIE"]
            @env["rack.request.cookie_hash"]
          else
            @env["rack.request.cookie_string"] = @env["HTTP_COOKIE"]
            @env["rack.request.cookie_hash"] =
              Utils.parse_query(@env["rack.request.cookie_string"], ';,').inject({}) {|h,(k,v)|
              h[k] = Array === v ? v.first : v
              h
            }
          end
        end

      end

      class << self
        def time_limit
          Digest.Nonce.time_limit
        end
        def time_limit=(t)
          Digest.Nonce.time_limit=t
        end
      end

      def initialize(*args)
        super
      end

      def call(env)
        @type2=nil
        auth = Request.new(env)

        unless auth.provided?
          return unauthorized
        end
        
        if !auth.ntlm?
          return bad_request
        end

        if auth.message.type == 1 && valid1?(auth)
          @type2 = Net::NTLM::Message::Type2.new
          set_flags(@type2)
          @new_nonce = Auth::Digest::Nonce.new
          @type2.challenge = Net::NTLM.unpack_int64le(ntlm_nonce @new_nonce)
          return unauthorized
        end

        if auth.message.type == 3 && valid3?(auth)
          if auth.nonce.stale?
            return unauthorized
          elsif valid_user(auth)
            env['REMOTE_USER'] = auth.message.user
            status, headers, body = @app.call(env)
            response = Rack::Response.new  body, status, headers
            response.set_cookie('_ntlm_challenge', {:value => ''})
            return response.finish
          end

        end

        unauthorized
      end

      def set_flags(message)
        true
      end
      def valid1?(auth)
        true
      end
      def valid3?(auth)
        true
      end

      def valid_user(auth)
        pwhash = [@authenticator.call(auth.message.user)].pack('H*')
        return false unless pwhash
        chall = ntlm_nonce auth.nonce
        
        # TODO LM NTLMv2
        auth.message.ntlm_response == Net::NTLM::apply_des(chall, Net::NTLM::gen_keys(pwhash.ljust(21, "\0"))).join
      end

      def ntlm_nonce(nonce) 
        [nonce.digest[0,16]].pack('H*')
      end

      def challenge
        "NTLM" + (@type2.nil? ? '' : " #{@type2.encode64}")
      end

      def unauthorized(www_authenticate = challenge)
        response = Rack::Response.new  [], 401,
          { 'Content-Type' => 'text/plain',
            'Content-Length' => '0',
            'WWW-Authenticate' => www_authenticate.to_s }
        response.set_cookie '_ntlm_challenge',
        if @new_nonce.nil?
          { :value => '', :expires => Time.parse('1970-01-01') }
        else
          { :value => @new_nonce.to_s }.merge(Digest::Nonce.time_limit.nil? ?
                                              {} :
                                              { :expires => Time.now.to_i + Digest::Nonce.time_limit })
        end
        response.finish
      end

    end
  end
end
