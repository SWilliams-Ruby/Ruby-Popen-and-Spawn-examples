module SW
  module AsyncRunner

    def self.run_async_demo()
      run_ruby_example()
      #run_dir_example()
      run_python_example()
    end
    
    def self.run_dir_example()
      prog = 'dir'
      args = ''
      os_client = SW::AsyncRunner::AsyncOSRunner.new(prog, args)
      os_client.run() { |result| puts result}
    end

    def self.run_python_example()
      path = 'C:\Users\User\Documents\sketchup code\sw_async_runner\src\hello.py'
      prog = 'pythonw'
      args = path
      os_client = SW::AsyncRunner::AsyncOSRunner.new(prog, args)
      os_client.run() { |result| puts result}
    end
    
    def self.run_ruby_example()
      client = 'C:/Users/User/Documents/sketchup code/sw_popen/src/SW_async_client.rb'
      args = 'Other Args'
      #args = 'force_error' #uncomment this line to test error handling
      ruby_client = SW::AsyncRunner::AsyncRubyRunner.new(client, args)
      ruby_client.run(:live) { |result| puts result}
      ruby_client.stdin_puts 'hello from STDIN'
      # ruby_client.close() # test closing the process
      # ruby_client.set_timeout(2)
  end

    module AsyncRunnerCore
      class AsyncRunnerAbort < RuntimeError; end
      
      # if live_connection == :live the block is called each time there is data whenever there is data
      def run(live_connection = false, &block)
        @live_connection = live_connection == :live
        @callback_block = block
        spawn()
      end
      
      def close()
        Process.kill("KILL", @wait_thr.pid)
      end
      
      def stdin_puts(str)
        @stdin_w.puts str
      end
      
      def set_timeout(secs)
        @timeout_time = Time.now + secs
      end
    
      def spawn()
        stdin_r, @stdin_w = IO.pipe
        @stdout_r, stdout_w = IO.pipe
        @stderr_r, stderr_w = IO.pipe
        pid = Kernel.spawn(@env, *@cmd, :in=>stdin_r, :out=>stdout_w, :err => stderr_w)
        @wait_thr = Process.detach(pid)
        stdin_r.close
        stdout_w.close
        stderr_w.close
        @timeout_time = nil
        @data = ''
        @client_status = :running
        read_client_stdout() 
      end
        
      def read_client_stdout
        begin
          if @timeout_time && (Time.now > @timeout_time)
            close()
            raise AsyncRunnerAbort, "Client Timed Out"
          end
          loop do 
            if @live_connection
              data = @stdout_r.read_nonblock(10000)
              @callback_block.call(data) if @live_connection
            else
              @data << @stdout_r.read_nonblock(10000)
            end
            
          end
        rescue IO::EWOULDBLOCKWaitReadable
          UI.start_timer(0.5) { read_client_stdout() }
        rescue AsyncRunnerAbort
          @client_status = :Process_Timed_Out
        rescue 
          # When the spawned process closes we will receiceand EOFError
          # Success or failure of the spawned process is determined by the presence/absence of data in the stderr pipe  
          begin
            error = @stderr_r.read_nonblock(10000)
            puts error
            @client_status = :Process_Failed
          rescue 
            @client_status = :Process_Completed_Normally
          end
        end
        
        if @client_status != :running
          @stdout_r.close
          @stderr_r.close
          @callback_block.call(@data) unless @live_connection
          puts "Async_Runner Client status: #{@client_status}"
        end
      end
    end #module

    class AsyncRubyRunner
      include AsyncRunnerCore
      def initialize(client, args)
        prog = 'rubyw'
        @env = {'GEM_HOME' => nil,'GEM_PATH'=> nil}
        @cmd  = [prog, client, args]
      end
      
    end
    
    class AsyncOSRunner
      include AsyncRunnerCore
      def initialize(prog, args)
        @env = {}
        @cmd  = [prog, args]
      end
      
    end
    
  end
end    
 

SW::AsyncRunner.run_async_demo()
nil
