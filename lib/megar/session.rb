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
  #   function api_getsid2(res,ctx)
  #   {
  #     console.log(new Date().getTime());
  #     var t, k;
  #     var r = false;
  #     if (typeof res == 'object')
  #     {
  #       var aes = new sjcl.cipher.aes(ctx.passwordkey);
  #       // decrypt master key
  #       if (typeof res[0].k == 'string')
  #       {
  #         k = base64_to_a32(res[0].k);
  #         if (k.length == 4)
  #         {
  #           k = decrypt_key(aes,k);
  #           aes = new sjcl.cipher.aes(k);
  #           if (typeof res[0].tsid == 'string')
  #           {
  #             t = base64urldecode(res[0].tsid);
  #             if (a32_to_str(encrypt_key(aes,str_to_a32(t.substr(0,16)))) == t.substr(-16)) r = [k,res[0].tsid];
  #           }
  #           else if (typeof res[0].csid == 'string')
  #           {
  #             var t = mpi2b(base64urldecode(res[0].csid));
  #             var privk = a32_to_str(decrypt_key(aes,base64_to_a32(res[0].privk)));
  #             var rsa_privk = Array(4);
  #             // decompose private key
  #             for (var i = 0; i < 4; i++)
  #             {
  #               var l = ((privk.charCodeAt(0)*256+privk.charCodeAt(1)+7)>>3)+2;
  #               rsa_privk[i] = mpi2b(privk.substr(0,l));
  #               if (typeof rsa_privk[i] == 'number') break;
  #               privk = privk.substr(l);
  #             }
  #             // check format
  #             if (i == 4 && privk.length < 16)
  #             {
  #               // @@@ check remaining padding for added early wrong password detection likelihood
  #               r = [k,base64urlencode(b2s(RSAdecrypt(t,rsa_privk[2],rsa_privk[0],rsa_privk[1],rsa_privk[3])).substr(0,43)),rsa_privk];
  #             }
  #           }
  #         }
  #       }
  #     }
  #   }
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

  def password_key
    prepare_key_pw(password)
  end

  # Returns the calculated uh parameter based on email and password
  #
  # Javascript reference implementation: function stringhash(s,aes)
  #
  # expectation generation in Javascript:
  #   aes = new sjcl.cipher.aes(prepare_key_pw(password))
  #   stringhash(email.toLowerCase(), aes)
  #   => EGQjdVjoWPA
  #
  def uh
    stringhash(email.downcase, password_key)
  end

  # Returns the rsa_private_key base64-encoded
  def rsa_private_key_b64
    base64urlencode(rsa_private_key)
  end

end
