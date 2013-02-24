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
    @options = default_options.merge(options.symbolize_keys)
    self.api_endpoint = @options[:api_endpoint] if @options[:api_endpoint]
    connect! if @options[:autoconnect]
  end

  # Returns authenticated/connected status
  def connected?
    !sid.nil?
  end

  # Returns a pretty representation of the session object
  def to_s
    if connected?
      "#{self.class.name}: connected as #{email}"
    else
      "#{self.class.name}: not connected"
    end
  end

  # Command: perform login session challenge/response.
  # Establishes a user session based on the response to a cryptographic challenge.
  #
  def connect!
    handle_login_challenge_response(get_login_response)
  end

  # Returns the user email (convenience method)
  def email
    @email ||= options[:email]
  end

  # Returns the user password (convenience method)
  def password
    @password ||= options[:password]
  end

  # Returns the rsa_private_key base64-encoded
  def rsa_private_key_b64
    base64urlencode(rsa_private_key)
  end

  # Returns the folder collection
  def folders
    refresh_files! if @folders.nil?
    @folders
  end

  # Returns the files collection
  def files
    refresh_files! if @files.nil?
    @files
  end

  def refresh_files!
    handle_files_response(get_files_response)
  end

  def reset_files!
    @folders = Megar::Folders.new
    @files = Megar::Files.new
  end

  protected

  # Command: enforces guard condition requiring authenticated connection to proceed
  def ensure_connected!
    raise "Not connected" unless connected?
  end

  def get_login_response
    api_request({'a' => 'us', 'user' => email, 'uh' => uh})
  end

  # Command: decrypt/decode the login +response_data+ received from Mega
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

  def get_files_response
    ensure_connected!
    api_request({'a' => 'f', 'c' => 1})
  end

  # Command: decrypt/decode the login +response_data+ received from Mega
  #
  def handle_files_response(response_data)
    reset_files!
    response_data['f'].each do |f|
      item_attributes = {id: f['h'], payload: f.dup, type: f['t'] }
      case f['t']
      when 0 # File
        item_attributes[:key] = k = decrypt_file_key(f)
        item_attributes[:attributes] = decrypt_file_attributes(f,k)
        files.add(item_attributes)
      when 1 # Folder
        item_attributes[:key] = k = decrypt_file_key(f)
        item_attributes[:attributes] = decrypt_file_attributes(f,k)
        folders.add(item_attributes)
      when 2,3,4 # Root, Inbox, Trash Bin
        folders.add(item_attributes)
      end
    end
    true
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


end
