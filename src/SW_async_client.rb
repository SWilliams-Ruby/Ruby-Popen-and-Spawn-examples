module SW
  def self.run()
    #reopen_io()

    puts STDIN.gets
    puts ARGV
    
    5.times { |i|
      STDOUT.puts "Step: #{i}"
      STDOUT.flush
      sleep(0.5)
    }
    
    # force an error
    m = 0/0 if /force_error/ =~ ARGV[0]
      
    puts "SU_ASYNC_RUNNER_Completed"
  end
  
  # def self.reopen_io()
    # #temp = STDOUT
    # #STDOUT.reopen(STDERR)
    # #STDOUT.reopen(temp)
    # STDOUT.sync
    # STDERR.sync
  # end
  
run()

end
nil
