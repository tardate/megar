require 'open-uri'
require 'net/http'
require 'pathname'

# Encapsulates a file upload task. This is intended as a one-shot helper.
#
# Javascript reference implementation: function initupload3()
#
class Megar::FileUploader
  include Megar::CryptoSupport

  attr_reader :folder
  attr_reader :session
  attr_reader :body
  attr_writer :name

  def initialize(options={})
    @folder = options[:folder]
    @session = @folder && @folder.session
    self.body = options[:body]
    self.name = options[:name]
  end

  def body=(value)
    @body = case value
    when File
      value
    when Pathname
      File.open(value,'rb')
    when String
      if value.size < 1024  # theoretically, a path name could be even longer but we'll assume
        # see if its a file name
        File.open(value,'rb')
      end
    when NilClass
    else
      raise Megar::UnsupportedFileHandleTypeError.new
    end
  end

  # Returns the size of the file content
  def upload_size
    body.size
  end

  # Returns stream handle to the file body
  def stream
    body
  end

  # Returns the name of the file
  def name
    @name ||= Pathname.new(body.path).basename.to_s
  end

  # Command: perform upload
  def post!
    return unless live_session?
    calculated_mac = [0, 0, 0, 0]
    completion_file_handle = ''

    encryptor = get_file_encrypter(upload_key,iv_str)

    get_chunks(upload_size).each do |chunk_start, chunk_size|
      chunk = stream.readpartial(chunk_size)
      encrypted_chunk = encryptor.update(chunk)
      calculated_mac = accumulate_mac(chunk,calculated_mac,mac_encryption_key,mac_iv,false)
      completion_file_handle = post_chunk(encrypted_chunk,chunk_start)
    end
    stream.close
    meta_mac = [calculated_mac[0] ^ calculated_mac[1], calculated_mac[2] ^ calculated_mac[3]]

    upload_attributes_response = send_file_upload_attributes(meta_mac,completion_file_handle)
    if upload_attributes_response.is_a?(Hash) && upload_attributes_response['f']
      session.handle_files_response(upload_attributes_response,false)
    else
      raise Megar::FileUploadError.new
    end
  end

  # upload chunk
  def post_chunk(encrypted_chunk,chunk_start)
    Net::HTTP.start(upload_uri.host, upload_uri.port) { |http|
      path = "#{upload_uri.path}/#{chunk_start}"
      response = http.post(path,encrypted_chunk)
      response.body
    }
  end
  protected :post_chunk

  def send_file_upload_attributes(meta_mac,completion_file_handle)
    session.send_file_upload_attributes(folder.id,name,upload_key,meta_mac,completion_file_handle)
  end
  protected :send_file_upload_attributes

  # Returns an upload url for the file content
  def upload_url
    upload_url_response['p']
  end

  # Returns an upload url for the file content as a URI
  def upload_uri
    @upload_uri ||= URI.parse(upload_url)
  end

  def upload_key
    @upload_key ||= 6.times.each_with_object([]) {|i,memo| memo << rand( 0xFFFFFFFF) }
  end

  # Returns the encryption key to use for calculating the MAC
  def mac_encryption_key
    upload_key[0,4]
  end

  # Returns the initialisation vector as array of 32bit integer to use for calculating the MAC
  def mac_iv
    [upload_key[4], upload_key[5], upload_key[4], upload_key[5]]
  end

  def iv
    ((upload_key[4]<<32)+upload_key[5])<<64
  end

  def iv_str
    hexstr_to_bstr( iv.to_s(16) )
  end

  # Returns and caches a file upload response
  def upload_url_response
    @upload_url_response ||= if live_session?
      session.get_file_upload_url_response(upload_size)
    else
      {}
    end
  end

  protected

  # Returns true if live session/folder properly set
  def live_session?
    !!(session && folder)
  end


end