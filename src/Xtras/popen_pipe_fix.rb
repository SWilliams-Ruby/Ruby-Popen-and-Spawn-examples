#require 'open3'
#require 'readline'
#require 'io/wait'
#require 'socket'

module SW

  def self.get_dialog_path()
    ARGV[0]
  end

  
  def self.run()
    begin  
      temp = STDOUT
      STDOUT.reopen(STDERR)
      STDOUT.reopen(temp)

      STDOUT.sync
      STDERR.sync

      # Test pipes
      # puts 'Stdout from the TCP_console.rb'
      # STDERR.puts 'Stderr from the TCP_console.rb'
    
      dialog_path = get_dialog_path()
      cmd  = ["rubyw", dialog_path, :err=>[:child, :out] ] # ok
      
      IO.popen(cmd, mode = 'a+') {|f|
        # puts('popen_pipe client opened')
        @running = true
        while @running
          readable = IO.select([STDIN, f])[0]
          outbound_transfer(f) if readable[0] == STDIN 
          inbound_transfer(f) if readable[0] == f
        end
       }   
    rescue => e
      puts e
    end
  end
  
  def self.inbound_transfer(f)
    text = f.gets if @running
    @running = false unless text
    puts text if text
  end
  
  
  def self.outbound_transfer(f)
    begin
      text = STDIN.gets
      f.puts(text)
      STDOUT.puts "echo #{text}"
      
      rescue Errno::EPIPE
        puts "Can't connect to the window (was it closed?)"
      end
  
    rescue LoadError => e
      print_exception(e)
    rescue => e
      print_exception(e)
  end # outbound
  
  def self.print_exception(exception)
    puts "#{exception.class}: #{exception.message}"
    puts exception.backtrace.join("\n")
  end
  
  run()
end