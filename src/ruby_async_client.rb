module SW
  def self.run()
    puts "Ruby Argv: #{ARGV}"
    STDOUT.flush
    5.times { |i|
      check_stdin()
      puts "Ruby Step: #{i}"
      STDOUT.flush
      sleep(0.5)
    }
    
    # force an error
    m = 0/0 if /force_error/ =~ ARGV[0]

  end
  
  def self.check_stdin()
    begin
      data = STDIN.read_nonblock(10000)
      puts "Ruby Echo STDIN: #{data}"
      STDOUT.flush
    rescue IO::EWOULDBLOCKWaitReadable
    end
  end
  
  
    
run()

end
nil
