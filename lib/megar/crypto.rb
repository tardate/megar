require 'openssl'
require 'base64'

# A straight-forward "quirks-mode" transcoding of core crypto methods required to talk to Mega.
# Some of this reeks a bit .. maybe more idiomatic ruby approaches are possible.
#
# Generally we're using signed 32-bit by default here ... I don't think it's necessary, but it makes comparison with
# the javascript implementation easier.
#
# Javascript reference implementations quoted here are taken from the Mega javascript source.
#
module Megar::Crypto

  # Returns encrypted key given an array +a+ of 32-bit integers
  #
  # Javascript reference implementation: function prepare_key(a)
  #
  def prepare_key(a)
    pkey = [0x93C467E3, 0x7DB0C7A4, 0xD1BE3F81, 0x0152CB56]
    0x10000.times do
      (0..(a.length-1)).step(4) do |j|
        key = [0,0,0,0]
        4.times {|i| key[i] = a[i+j] if (i+j < a.length) }
        pkey = aes_encrypt_a32(pkey,key)
      end
    end
    pkey
  end

  # Returns encrypted key given the plain-text +password+ string
  #
  # Javascript reference implementation: function prepare_key_pw(password)
  #
  def prepare_key_pw(password)
    prepare_key(str_to_a32(password))
  end

  # Returns a decrypted given an array +a+ of 32-bit integers and +key+
  #
  # Javascript reference implementation: function decrypt_key(cipher,a)
  #
  def decrypt_key(a, key)
    b=[]
    (0..(a.length-1)).step(4) do |i|
      b.concat aes_cbc_decrypt_a32(a[i,4], key)
    end
    b
  end

  # Returns decrypted array of 32-bit integers representation of base64 +data+ decrypted using +key+
  def decrypt_base64_to_a32(data,key)
    decrypt_key(base64_to_a32(data), key)
  end

  # Returns decrypted string representation of base64 +data+ decrypted using +key+
  def decrypt_base64_to_str(data,key)
    a32_to_str(decrypt_base64_to_a32(data, key))
  end


  # Returns AES-128 encrypted given +key+ and +data+ (arrays of 32-bit signed integers)
  def aes_encrypt_a32(data, key)
    aes = OpenSSL::Cipher::Cipher.new('AES-128-ECB')
    aes.encrypt
    aes.padding = 0
    aes.key = key.pack('l>*')
    aes.update(data.pack('l>*')).unpack('l>*')
    # e = aes.update(data.pack('l>*')).unpack('l>*')
    # e << aes.final
    # e.unpack('l>*')
  end

  # Returns AES-128 decrypted given +key+ and +data+ (arrays of 32-bit signed integers)
  def aes_cbc_decrypt_a32(data, key)
    str_to_a32(aes_cbc_decrypt(a32_to_str(data), a32_to_str(key)))
  end

  # Returns AES-128 decrypted given +key+ and +data+ (String)
  def aes_cbc_decrypt(data, key)
    aes = OpenSSL::Cipher::Cipher.new('AES-128-CBC')
    aes.decrypt
    aes.padding = 0
    aes.key = key
    aes.iv = "\0" * 16
    d = aes.update(data)
    d = aes.final if d.empty?
    d
  end

  # Returns an array of 32-bit signed integers representing the string +b+
  #
  # Javascript reference implementation: function str_to_a32(b)
  #
  def str_to_a32(b)
    a = Array.new((b.length+3) >> 2,0)
    b.length.times { |i| a[i>>2] |= (b.getbyte(i) << (24-(i & 3)*8)) }
    a.pack('l>*').unpack('l>*') # hack to force to signed 32-bit ... I don't think we really need to do this, but it makes comparison with
  end

  # Returns a packed string given an array +a+ of 32-bit signed integers
  #
  # Javascript reference implementation: function a32_to_str(a)
  #
  def a32_to_str(a)
    b = ''
    (a.size * 4).times { |i| b << ((a[i>>2] >> (24-(i & 3)*8)) & 255).chr }
    b
  end

  # Returns a base64-encoding of string +s+ hashed with +aeskey+ key
  #
  # Javascript reference implementation: function stringhash(s,aes)
  #
  def stringhash(s,aeskey)
    s32 = str_to_a32(s)
    h32 = [0,0,0,0]
    s32.length.times {|i| h32[i&3] ^= s32[i] }
    16384.times {|i| h32 = aes_encrypt_a32(h32, aeskey) }
    a32_to_base64([h32[0],h32[2]])
  end

  # Returns a base64-encoding given an array +a+ of 32-bit integers
  #
  # Javascript reference implementation: function a32_to_base64(a)
  #
  def a32_to_base64(a)
    base64urlencode(a32_to_str(a))
  end

  # Returns an array +a+ of 32-bit integers given a base64-encoded +b+ (String)
  #
  # Javascript reference implementation: function base64_to_a32(s)
  #
  def base64_to_a32(s)
    str_to_a32(base64urldecode(s))
  end

  # Returns a base64-encoding given +data+ (String).
  #
  # Javascript reference implementation: function base64urlencode(data)
  #
  def base64urlencode(data)
    Base64.urlsafe_encode64(data).gsub(/=*$/,'')
  end

  # Returns a string given +data+ (base64-encoded String)
  #
  # Javascript reference implementation: function base64urldecode(data)
  #
  def base64urldecode(data)
    Base64.urlsafe_decode64(data + '=' * ((4 - data.length % 4) % 4))
  end

  # Returns multiple precision integer (MPI) as an array of 32-bit unsigned integers decoded from raw string +s+
  # This first 16-bits of the MPI is the MPI length in bits
  #
  # Javascript reference implementation: function mpi2b(s)
  #
  def mpi_to_a32(s)
    bs=28
    bx2=1<<bs
    bm=bx2-1

    bn=1
    r=[0]
    rn=0
    sb=256
    c = nil
    sn=s.length
    return 0 if(sn < 2)

    len=(sn-2)*8
    bits=s[0].ord*256+s[1].ord

    return 0 if(bits > len || bits < len-8)

    len.times do |n|
      if ((sb<<=1) > 255)
        sb=1
        sn -= 1
        c=s[sn].ord
      end
      if(bn > bm)
        bn=1
        rn += 1
        r << 0
      end
      if(c & sb != 0)
        r[rn]|=bn
      end
      bn<<=1
    end
    r
  end

  # Alternative mpi2b implementation; doesn't quite match the javascript implementation yet however
  # def native_mpi_to_a32(s)
  #   len = s.length - 2
  #   short = len % 4
  #   base = len - short
  #   r = s[2,base].unpack('N*')
  #   case short
  #   when 1
  #     r.concat s[2+base,short].unpack('C*')
  #   when 2
  #     r.concat s[2+base,short].unpack('n*')
  #   when 3
  #     r.concat ("\0" + s[2+base,short]).unpack('N*')
  #   end
  #   r
  # end

  # Returns multiple precision integer (MPI) as an array of 32-bit signed integers decoded from base64 string +s+
  #
  def base64_mpi_to_a32(s)
    mpi_to_a32(base64urldecode(s))
  end

  # Returns multiple precision integer (MPI) as a big integers decoded from base64 string +s+
  #
  def base64_mpi_to_bn(s)
    data = base64urldecode(s)
    len = ((data[0].ord * 256 + data[1].ord + 7) / 8) + 2
    data[2,len+2].unpack('H*').first.to_i(16)
  end


  # Returns the 4-part RSA key as 32-bit signed integers [d, p, q, u] given +key+ (String)
  #
  # result[0] = p: The first factor of n, the RSA modulus
  # result[1] = q: The second factor of n
  # result[2] = d: The private exponent.
  # result[3] = u: The CRT coefficient, equals to (1/p) mod q.
  #
  # Javascript reference implementation: function api_getsid2(res,ctx)
  #
  def decompose_rsa_private_key_a32(key)
    privk = key.dup
    decomposed_key = []
    # puts "decomp: privk.len:#{privk.length}"
    4.times do
      len = ((privk[0].ord * 256 + privk[1].ord + 7) / 8) + 2
      privk_part = privk[0,len]
      # puts "\nprivk_part #{base64urlencode(privk_part)}"
      privk_part_a32 = mpi_to_a32(privk_part)
      decomposed_key << privk_part_a32
      # puts "decomp: len:#{len} privk_part_a32:#{privk_part_a32.length} first:#{privk_part_a32.first} last:#{privk_part_a32.last}"
      privk.slice!(0,len)
    end
    decomposed_key
  end

  # Returns the 4-part RSA key as array of big integers [d, p, q, u] given +key+ (String)
  #
  # result[0] = p: The first factor of n, the RSA modulus
  # result[1] = q: The second factor of n
  # result[2] = d: The private exponent.
  # result[3] = u: The CRT coefficient, equals to (1/p) mod q.
  #
  # Javascript reference implementation: function api_getsid2(res,ctx)
  #
  def decompose_rsa_private_key(key)
    privk = key.dup
    decomposed_key = []
    offset = 0
    4.times do |i|
      len = ((privk[0].ord * 256 + privk[1].ord + 7) / 8) + 2
      privk_part = privk[0,len]
      # puts "\nl: ", len
      # puts "decrypted rsa part hex: \n", privk_part.unpack('H*').first
      decomposed_key << privk_part[2,privk_part.length].unpack('H*').first.to_i(16)
      privk.slice!(0,len)
    end
    decomposed_key
  end

  # Returns the decrypted session id given base64 MPI +csid+ and RSA +rsa_private_key+ as array of big integers [d, p, q, u]
  #
  # Javascript reference implementation: function api_getsid2(res,ctx)
  #
  def decrypt_session_id(csid,rsa_private_key)
    csid_bn = base64_mpi_to_bn(csid)
    sid_bn = rsa_decrypt(csid_bn,rsa_private_key)
    sid_hs = sid_bn.to_s(16)
    sid_hs = '0' + sid_hs if sid_hs.length % 2 > 0
    sid = hexstr_to_bstr(sid_hs)[0,43]
    base64urlencode(sid)
  end

  # Returns the private key decryption of +m+ given +pqdu+ (array of integer cipher components).
  # Computes m**d (mod n).
  #
  # This implementation uses a Pure Ruby implementation of RSA private_decrypt
  #
  # p: The first factor of n, the RSA modulus
  # q: The second factor of n
  # d: The private exponent.
  # u: The CRT coefficient, equals to (1/p) mod q.
  #
  # n = pq
  # n is used as the modulus for both the public and private keys. Its length, usually expressed in bits, is the key length.
  #
  # φ(n) = (p – 1)(q – 1), where φ is Euler's totient function.
  #
  # Choose an integer e such that 1 < e < φ(n) and gcd(e, φ(n)) = 1; i.e., e and φ(n) are coprime.
  # e is released as the public key exponent
  #
  # Determine d as d ≡ e−1 (mod φ(n)), i.e., d is the multiplicative inverse of e (modulo φ(n)).
  # d is kept as the private key exponent.
  #
  # More info: http://en.wikipedia.org/wiki/RSA_(algorithm)#Operation
  #
  # Javascript reference implementation: function RSAdecrypt(m, d, p, q, u)
  #
  def rsa_decrypt(m, pqdu)
    p, q, d, u = pqdu
    if p && q && u
      m1 = Math.powm(m, d % (p-1), p)
      m2 = Math.powm(m, d % (q-1), q)
      h = m2 - m1
      h = h + q if h < 0
      h = h*u % q
      h*p+m1
    else
      Math.powm(m, d, p*q)
    end
  end


  # Returns the private key decryption of +m+ given +pqdu+ (array of integer cipher components)
  # This implementation uses OpenSSL RSA public key feature.
  #
  # NB: can't get this to work exactly right with Mega yet
  def openssl_rsa_decrypt(m, pqdu)
    rsa = openssl_rsa_cipher(pqdu)

    chunk_size = 256 # hmm. need to figure out how to calc for "data greater than mod len"
    # number.size(self.n) - 1 : Return the maximum number of bits that can be handled by this key.
    decrypt_texts = []
    (0..m.length - 1).step(chunk_size) do |i|
      pt_part = m[i,chunk_size]
      decrypt_texts << rsa.private_decrypt(pt_part,3)
    end
    decrypt_texts.join
  end

  # Returns an OpenSSL RSA cipher object initialised with +pqdu+ (array of integer cipher components)
  # p: The first factor of n, the RSA modulus
  # q: The second factor of n
  # d: The private exponent.
  # u: The CRT coefficient, equals to (1/p) mod q.
  #
  # NB: this hacks the RSA object creation n a way that should work, but can't get this to work exactly right with Mega yet
  def openssl_rsa_cipher(pqdu)
    rsa = OpenSSL::PKey::RSA.new
    p, q, d, u = pqdu
    rsa.p, rsa.q, rsa.d = p, q, d
    rsa.n = rsa.p * rsa.q
    # # dmp1 = d mod (p-1)
    # rsa.dmp1 = rsa.d % (rsa.p - 1)
    # # dmq1 = d mod (q-1)
    # rsa.dmq1 = rsa.d % (rsa.q - 1)
    # # iqmp = q^-1 mod p?
    # rsa.iqmp =  (rsa.q ** -1) % rsa.p
    # # ipmq =  (rsa.p ** -1) % rsa.q
    # ipmq =  rsa.p ** -1 % rsa.q
    rsa.e = 0 # 65537
    rsa
  end

  # Returns a binary string given a string +h+ of hex digits
  def hexstr_to_bstr(h)
    bstr = ''
    (0..h.length-1).step(2) {|n| bstr << h[n,2].to_i(16).chr }
    bstr
  end

  def decrypt_file_key(f)
    key = f['k'].split(':')[1]
    decrypt_key(base64_to_a32(key), self.master_key)
  end

  def decrypt_file_attributes(f,key)
    k = f['t'] == 0 ? decompose_file_key(key) : key
    rstr = aes_cbc_decrypt(base64urldecode(f['a']), a32_to_str(k))
    JSON.parse( rstr.gsub("\x0",'').gsub(/^.*{/,'{'))
  end

  def decompose_file_key(key)
    [
      key[0] ^ key[4],
      key[1] ^ key[5],
      key[2] ^ key[6],
      key[3] ^ key[7]
    ]
  end


end
