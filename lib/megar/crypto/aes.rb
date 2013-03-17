# A convenience wrapper for AES CBC implementation provided by OpenSSL
class Megar::Crypto::Aes

  attr_accessor :key
  attr_accessor :iv

  def initialize(options={})
    self.key = options[:key]
    self.iv = options[:iv]
  end

  def key=(value)
    @key = value.is_a?(Array) ? value.pack(packing) : value
  end

  def iv=(value)
    @iv = value || "\x0" * 16
  end

  def packing
    'l>*'
  end

  def mode
    'AES-128-CBC'
  end

  def cipher
    @cipher ||= OpenSSL::Cipher::Cipher.new(mode)
  end

  def encrypt(data)
    a32_mode = data.is_a?(Array)
    d = a32_mode ? data.pack(packing) : data

    cipher.reset
    cipher.encrypt
    cipher.padding = 0
    cipher.iv = iv
    cipher.key = key
    result = cipher.update d

    a32_mode ? result.unpack(packing) : result
  end

  def decrypt(data)
    a32_mode = data.is_a?(Array)
    d = a32_mode ? data.pack(packing) : data

    cipher.reset
    cipher.decrypt
    cipher.padding = 0
    cipher.iv = iv
    cipher.key = key
    result = cipher.update d

    a32_mode ? result.unpack(packing) : result
  end

end
