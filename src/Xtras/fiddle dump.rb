require 'fiddle'
def self.dump_object(object)
  address = object.object_id << 1
  dump_address(address)
end

def self.dump_address(address)
  ptr = Fiddle::Pointer.new(address)
  dump_ptr(ptr)
end

def self.dump_ptr(ptr)
  offset  = 0
  8.times {
    print (ptr.to_int + offset).to_s(16) # physical address
    data = ptr[offset, 16]
    data.each_byte { |b| print (b < 16 ? ' 0' + b.to_s(16) : ' ' + b.to_s(16)) }
    print '  '
    data.each_char { |b|
      if b.ord > 0x20
        print ' ' + b.to_s
      else
        print ' '
      end
    }
    offset += 16
    puts
  }

end

s = 'A string'
dump_object(s)

nil

