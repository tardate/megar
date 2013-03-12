class Megar::Crypto::Aes

  def packing
    'l>*'
  end

  def mode
    'AES-128-CBC'
  end

  def cipher
    @cipher ||= OpenSSL::Cipher::Cipher.new(mode)
  end

  def iv
    "\x0" * 16
  end

  def encrypt(data, key)
    k = key.is_a?(Array)  ? key.pack(packing)  : key
    d = data.is_a?(Array) ? data.pack(packing) : data

    cipher.reset
    cipher.encrypt
    cipher.padding = 0
    cipher.iv = iv
    cipher.key = k
    result = cipher.update d

    if data.is_a? Array
      result.unpack packing
    else
      result
    end
  end

  def decrypt(data, key)
    k = key.is_a?(Array)  ? key.pack(packing)  : key
    d = data.is_a?(Array) ? data.pack(packing) : data

    cipher.reset
    cipher.decrypt
    cipher.padding = 0
    cipher.iv = iv
    cipher.key = k
    result = cipher.update d

    if data.is_a? Array
      result.unpack packing
    else
      result
    end
  end

end
