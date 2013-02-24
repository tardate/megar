
# Calculate ((b**p) % m) assuming that b and m are large integers.
# http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-talk/71964
def Math.powm(b, p, m)
  if p == 1
    b % m
  elsif (p & 0x1) == 0 # p.even?
    t = powm(b, p >> 1, m)
    (t * t) % m
  else
    (b * powm(b, p-1, m)) % m
  end
end
