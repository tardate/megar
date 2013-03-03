require 'open-uri'

# Encapsulates a file download task. This is intended as a one-shot helper.
#
# Javascript reference implementation: function startdownload2(res,ctx)
#
class Megar::FileDownloader
  include Megar::CryptoSupport

  attr_reader :session
  attr_reader :file

  def initialize(options={})
    @file = options[:file]
    @session = @file && @file.session
  end

  # Returns an io stream to the file content
  def stream
    return unless live_session?
    @stream ||= if url = download_url
      open(url)
    end
  end

  # Returns the complete decrypted content.
  # If anything goes wrong here, it's going to bubble up an unhandled error.
  #
  def content
    return unless live_session?
    decoded_content = ''
    calculated_mac = [0, 0, 0, 0]

    decryptor = get_file_decrypter(decomposed_key,iv)

    get_chunks(download_size).each do |chunk_start, chunk_size|
      chunk = stream.readpartial(chunk_size)
      decoded_chunk = decryptor.update(chunk)
      decoded_content << decoded_chunk
      calculated_mac = accumulate_mac(calculated_mac,decoded_chunk)
    end

    raise Megar::MacVerificationError.new unless ([calculated_mac[0] ^ calculated_mac[1], calculated_mac[2] ^ calculated_mac[3]] == mac)

    decoded_content
  end

  # Returns the complete encrypted content (mainly for testing purposes)
  def raw_content
    return unless live_session?
    stream.read
  end

  # Returns a download url for the file content
  def download_url
    download_url_response['g']
  end

  # Returns a download size for the file content
  def download_size
    download_url_response['s']
  end

  # Returns the decrypted download attributes
  def download_attributes
    if attributes = download_url_response['at']
      decrypt_file_attributes(attributes,decomposed_key)
    end
  end

  # Returns the initialisation vector
  def iv
    @iv ||= key[4,2] + [0, 0]
  end

  # Returns the expected MAC for the file
  def mac
    key[6,2]
  end

  # Returns the file key (shortcut)
  def key
    file.key
  end

  # Returns the file key (shortcut)
  def decomposed_key
    file.decomposed_key
  end

  # Returns the initial value for AES counter
  def initial_counter_value
    ((iv[0] << 32) + iv[1]) << 64
  end

  # Returns and caches a file download response
  def download_url_response
    @download_url_response ||= if live_session?
      session.get_file_download_url_response(file.id)
    else
      {}
    end
  end

  protected

  # Returns true if live session/file properly set
  def live_session?
    !!(session && file)
  end

  def accumulate_mac(progressive_mac,chunk)
    use_signed_math = true
    chunk_mac = calculate_chunk_mac(chunk,use_signed_math)
    combined_mac = [
      progressive_mac[0] ^ chunk_mac[0],
      progressive_mac[1] ^ chunk_mac[1],
      progressive_mac[2] ^ chunk_mac[2],
      progressive_mac[3] ^ chunk_mac[3]
    ]
    session.aes_cbc_encrypt_a32(combined_mac, decomposed_key, use_signed_math)
  end

  # Returns the calculated mac for +chunk+
  def calculate_chunk_mac(chunk,signed=true)
    session.calculate_chunk_mac(chunk,decomposed_key,iv,signed)
  end

end