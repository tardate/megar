# Implements AES COUNTER mode using base AES CBC implementation provided by OpenSSL
class Megar::Crypto::AesCtr

  attr_accessor :key
  attr_accessor :iv

  # Consturcts a new AES CTR-mode object give +options+
  # options[:key] = encryption key as binary string or array of 32-bit integer (required)
  # options[:iv] = initialisation vector as array of 32-bit integer (nulled by default)
  def initialize(options={})
    self.key = options[:key]
    self.iv = options[:iv]
  end

  def packing
    'l>*'
  end

  def key=(value)
    @key = value.is_a?(Array) ? value.pack(packing) : value
  end

  def iv=(value)
    @iv = value ? value.dup : [0,0,0,0]
  end

  # Returns the encrypted binary string of +chunk+ (provided as binary string).
  # Repeated calls will continue the counter sequence.
  def update(chunk)
    a32 = str_to_a32(chunk)
    last_i = 0

    (0..a32.size - 3).step(4) do |i|
      enc = Megar::Crypto::Aes.new(key: key).encrypt(iv)
      4.times do |m|
        a32[i+m] = (a32[i+m] || 0) ^ (enc[m] || 0)
      end
      iv[3] += 1
      iv[2] += 1 if iv[3] == 0
      last_i = i + 4
    end

    remainder = a32.size % 4

    if remainder > 0
      v = [0, 0, 0, 0]
      (last_i..a32.size - 1).step(1) { |m| v[m-last_i] = a32[m] || 0 }
      enc = Megar::Crypto::Aes.new(key: key).encrypt(iv)
      4.times { |m| v[m] = v[m] ^ enc[m] }

      (last_i..a32.size - 1).step(1) { |j| a32[j] = v[j - last_i] || 0 }
    end

    a32_to_str(a32)[0..chunk.size - 1]
  end

  # TODO: refactor to pull this method from a shared lib.
  def str_to_a32(b,signed=true)
    a = Array.new((b.length+3) >> 2,0)
    b.length.times { |i| a[i>>2] |= (b.getbyte(i) << (24-(i & 3)*8)) }
    if signed
      a.pack('l>*').unpack('l>*')
    else
      a
    end
  end

  # TODO: refactor to pull this method from a shared lib.
  def a32_to_str(a)
    b = ''
    (a.size * 4).times { |i| b << ((a[i>>2] >> (24-(i & 3)*8)) & 255).chr }
    b
  end

end
