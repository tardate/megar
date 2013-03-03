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

  def initialize(options={})
    @folder = options[:folder]
    @session = @folder && @folder.session
    self.body = options[:body]
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

  def post!
    return unless live_session?
    calculated_mac = [0, 0, 0, 0]
    completion_file_handle = ''


    encryptor = get_file_encrypter(upload_key,iv_str)

    get_chunks(upload_size).each do |chunk_start, chunk_size|
      chunk = stream.readpartial(chunk_size)
      encrypted_chunk = encryptor.update(chunk)
      calculated_mac = accumulate_mac(calculated_mac,chunk)

      # upload chunk
      Net::HTTP.start(upload_uri.host, upload_uri.port) {|http|
        path = "#{upload_uri.path}/#{chunk_start}"
        response = http.post(path,encrypted_chunk)
        completion_file_handle = response.body
      }

    end
    meta_mac = [calculated_mac[0] ^ calculated_mac[1], calculated_mac[2] ^ calculated_mac[3]]

    upload_attributes_response = session.send_file_upload_attributes(folder.id,name,upload_key,meta_mac,completion_file_handle)

    stream.close
    upload_attributes_response
  end


  # Returns an upload url for the file content
  def upload_url
    upload_url_response['p']
  end

  def upload_uri
    @upload_uri ||= URI.parse(upload_url)
  end

  def upload_key
    @upload_key ||= 6.times.each_with_object([]) {|i,memo| memo << rand( 0xFFFFFFFF) }
  end

  def encryption_key
    upload_key[0,4]
  end

  def iv
    ((upload_key[4]<<32)+upload_key[5])<<64
  end

  def iv_str
    hexstr_to_bstr( iv.to_s(16) )
  end

  def upload_size
    body.size
  end

  def stream
    body
  end

  def name
    @name ||= Pathname.new(body.path).basename.to_s
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

  def accumulate_mac(progressive_mac,chunk)
    signed = false
    chunk_mac = calculate_chunk_mac_ex(chunk,encryption_key,chunk_mac_iv,signed)
    combined_mac = [
      progressive_mac[0] ^ chunk_mac[0],
      progressive_mac[1] ^ chunk_mac[1],
      progressive_mac[2] ^ chunk_mac[2],
      progressive_mac[3] ^ chunk_mac[3]
    ]
    session.aes_cbc_encrypt_a32(combined_mac, encryption_key, signed)
  end

  def chunk_mac_iv
    [upload_key[4], upload_key[5], upload_key[4], upload_key[5]]
  end

  # Returns the +chunk+ mac (array of unsigned int)
  #
  def calculate_chunk_mac_ex(chunk,key,iv,signed=false)
    chunk_mac = iv
    (0..chunk.length-1).step(16).each do |i|
      block = chunk[i,16]
      if (m = block.length % 16) > 0
        block << "\0" * m
      end
      block = str_to_a32(block,signed)
      chunk_mac = [
        chunk_mac[0] ^ block[0],
        chunk_mac[1] ^ block[1],
        chunk_mac[2] ^ block[2],
        chunk_mac[3] ^ block[3]
      ]
      chunk_mac = aes_cbc_encrypt_a32(chunk_mac, key, signed)
    end
    chunk_mac
  end


end