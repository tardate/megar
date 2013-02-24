class Megar::Session

  include Megar::Crypto
  include Megar::Connection

  attr_accessor :options
  attr_accessor :email
  attr_accessor :password
  attr_accessor :master_key
  attr_accessor :rsa_private_key # binary string
  attr_accessor :decomposed_rsa_private_key # 4 part array of a32

  # Start a new session, given +options+ hash.
  #
  # Required +options+ parameters:
  #   email: 'your email address'     -- email for authentication
  #   password: 'your password'       -- password for authentication
  #
  # Optional +options+ parameters:
  #   api_endpoint: 'url'             -- talk to an alternative API endpoint
  #   autoconnect: true/false         -- performs immediate login if true (default)
  #
  def initialize(options={})
    default_options = { autoconnect: true }
    @options = default_options.merge(options).inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
    self.api_endpoint = @options[:api_endpoint] if @options[:api_endpoint]
    connect! if @options[:autoconnect]
  end

  # Returns authenticated/connected status
  def connected?
    !sid.nil?
  end

  # Command: perform login session challenge/response.
  # Establishes a user session based on the response to a cryptographic challenge.
  #
  def connect!
    handle_login_challenge_response(get_login_response)
  end

  def get_login_response
    api_request({'a' => 'us', 'user' => email, 'uh' => uh})
  end

  # Command: decrypt the +response_data+ received from Mega
  #
  # Javascript reference implementation: function api_getsid2(res,ctx)
  #
  def handle_login_challenge_response(response_data)
    if k = response_data['k']
      enc_master_key = base64_to_a32(k)
      self.master_key = decrypt_key(enc_master_key, password_key)
    end
    if privk = response_data['privk']
      self.rsa_private_key = decrypt_base64_to_str(privk, master_key)
      self.decomposed_rsa_private_key = decompose_rsa_private_key(rsa_private_key)
      if csid = response_data['csid']
        self.sid = decrypt_session_id(csid,decomposed_rsa_private_key)
      end
    end
  end

  # Returns the user email (convenience method)
  def email
    @email ||= options[:email]
  end

  # Returns the user password (convenience method)
  def password
    @password ||= options[:password]
  end

  # Returns the encoded user password key
  def password_key
    prepare_key_pw(password)
  end

  # Returns the calculated uh parameter based on email and password
  #
  # Javascript reference implementation: function stringhash(s,aes)
  #
  def uh
    stringhash(email.downcase, password_key)
  end

  # Returns the rsa_private_key base64-encoded
  def rsa_private_key_b64
    base64urlencode(rsa_private_key)
  end

end
