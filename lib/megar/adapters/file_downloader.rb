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

    # TODO here: init mac calculation (perhaps should be an option to use of not)
    decryptor = session.get_file_decrypter(file.decomposed_key,iv)
    get_chunks(download_size).each do |chunk_start, chunk_size|
      chunk = stream.readpartial(chunk_size)
      decoded_chunk = decryptor.update(chunk)
      decoded_content << decoded_chunk
      # TODO here: calculate chunk mac
    end
    # TODO here: perform integrity check against expected file mac

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
      decrypt_file_attributes(attributes,file.decomposed_key)
    end
  end

  # Returns the initialisation vector
  def iv
    @iv ||= file.key[4,2] + [0, 0]
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

  # Returns an array of chunk sizes given total file +size+
  #
  # Chunk boundaries are located at the following positions:
  # 0 / 128K / 384K / 768K / 1280K / 1920K / 2688K / 3584K / 4608K / ... (every 1024 KB) / EOF
  def get_chunks(size)
    chunks = []
    p = pp = 0
    i = 1

    while i <= 8 and p < size - i * 0x20000 do
      chunk_size =  i * 0x20000
      chunks << [p, chunk_size]
      pp = p
      p += chunk_size
      i += 1
    end

    while p < size - 0x100000 do
      chunk_size =  0x100000
      chunks << [p, chunk_size]
      pp = p
      p += chunk_size
    end

    chunks << [p, size - p] if p < size

    chunks
  end

  def calculate_chunk_mac(iv,chunk)
    chunk_mac = [iv[0], iv[1], iv[0], iv[1]]
    (1..chunk.length).take(16).each do |bit|
      # NYI
    end
    chunk_mac
  end

end