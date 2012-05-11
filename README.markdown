### :warning: This gem does NOT verify the user passowrd (see [issue #1](https://github.com/lukefx/rack-ntlm/issues/1))

**If you need verification against Active Directory** probably the best solution is 
[this comment](https://github.com/lukefx/rack-ntlm/issues/1#issuecomment-5569914).

**Otherwise** you should have the hashed ([LM](http://en.wikipedia.org/wiki/LM_hash), 
[NT, etc.](http://en.wikipedia.org/wiki/NTLM#Protocol)) version of your users' passwords 
and manually check the Type-3 response against them.

---

# Rack-ntlm

Transparent authentication with [NTLM](http://davenport.sourceforge.net/ntlm.html).

## Usage

In your Gemfile add:

```ruby
gem 'rack-ntlm', :git => 'git://github.com/lukefx/rack-ntlm.git'
```

Then add rack-ntlm to the middleware chain in config/application.rb (Rails 3)

```ruby
config.middleware.use 'Rack::Ntlm', {
  :uri_pattern => /\/login/                       # (default = /\//) (any URL)
  :host => '<Active Directory hostname>',
  :port => 389,                                   # default = 389
  :base => 'Base namespace for LDAP search',
  :search_filter => '(dn=%1)'                     # default = (sAMAccountName=%1)
  :auth => {
    :username => '<username to bind to LDAP>',
    :password => '<password to bind to LDAP>'
  }
}
```

**Credits to @dtsato to this awesome configuration and defaults**

## How it works?

NTLM is a transparent authentication system developed by Microsoft, it needs that your webserver 
use keepalive because the handshake consists in 6 steps all with the same connection.

1. `C => S   GET ...`

2. `C <= S   401 Unauthorized`
   
   `WWW-Authenticate: NTLM`

3. `C => S   GET ...`
   
   `Authorization: NTLM <base64-encoded type-1-message>`

4. `C <= S   401 Unauthorized`
   
   `WWW-Authenticate: NTLM <base64-encoded type-2-message>`

5. `C => S   GET ...`
   
   `Authorization: NTLM <base64-encoded type-3-message>`

6. `C <= S   200 Ok`
