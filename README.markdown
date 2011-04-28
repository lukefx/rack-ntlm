# Rack-ntlm

Transparent authentication with NTLM.

## Usage

  In your Gemfile add:

    gem 'rack-ntlm', :git => 'git://github.com/lukefx/rack-ntlm.git'

  Then add rack-ntlm to the middleware chain in config/application.rb (Rails 3)

    config.middleware.use "Rack::Ntlm"


When a client needs to authenticate itself to a proxy or server using the NTLM scheme then the following 4-way handshake takes place (only parts of the request and status line and the relevant headers are shown here; "C" is the client, "S" the server): 

## How it works?

NTLM it's a transparent authentication system developed by Microsoft, it needs that your webserver use keepalive because the handshake consists in 6 steps all with the same connection.

  1: C  --> S   GET ...

  2: C <--  S   401 Unauthorized
              WWW-Authenticate: NTLM

  3: C  --> S   GET ...
              Authorization: NTLM <base64-encoded type-1-message>

  4: C <--  S   401 Unauthorized
              WWW-Authenticate: NTLM <base64-encoded type-2-message>

  5: C  --> S   GET ...
              Authorization: NTLM <base64-encoded type-3-message>

  6: C <--  S   200 Ok
