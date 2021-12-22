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
      path = 'C:\Users\User\Documents\sketchup code\sw_async_runner\src\python_async_client.py'
      prog = 'pythonw'
      args = path
      os_client = SW::AsyncRunner::AsyncOSRunner.new(prog, args)
      os_client.run(:live) { |async_ruby_runner|
        puts async_ruby_runner.data.pop(true) rescue :NoData
        puts async_ruby_runner.status
        puts async_ruby_runner.error_message if async_ruby_runner.status != :Running
      }
    end
    
    def self.run_ruby_example()
      client = 'C:/Users/User/Documents/sketchup code/SW_async_runner/src/ruby_async_client.rb'
      args = 'Other Args'
      #args = 'force_error' #uncomment this line to test error handling
      async_ruby_runner = SW::AsyncRunner::AsyncRubyRunner.new(client, args)
      #async_ruby_runner.set_timeout(1)

      async_ruby_runner.run(:live) { |async_ruby_runner|
        puts async_ruby_runner.data.pop(true) rescue :NoData
        puts async_ruby_runner.status
        puts async_ruby_runner.error_message if async_ruby_runner.status != :Running
      }
  
      async_ruby_runner.stdin_puts 'hello from STDIN'
      # async_ruby_runner.close() # test closing the process
    end

    module AsyncRunnerCore
      attr_reader(:status, :data, :live_connection, :error_message )
      @update_caller = false  
      
      def initialize(client, args)
        @status = :Idle
        @data = Queue.new
        @live_connection = false
        @error_message  = nil
        @timeout_time = nil        
      end
      
      # if live_connection == :live the block is called each time there is data whenever there is data
      def run(live_connection = false, &block)
        @live_connection = live_connection == :live
        @callback_block = block
        spawn()
      end
      
      def close()
        Process.kill("KILL", @wait_thr.pid)
        close_pipes()
      end
      
      def stdin_puts(str)
        @stdin_w.puts str
      end
      
      def set_timeout(secs)
        @timeout_time = Time.now + secs
      end
      
      def close_pipes()
        @stdout_r.close
        @stdin_w.close
        @stderr_r.close
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
        @status = :Running
        read_client_stdout() 
      end
        
      def read_client_stdout()
        begin
          loop do 
            @data << @stdout_r.read_nonblock(10000)
            @update_caller = true  if @live_connection
          end
        rescue IO::EWOULDBLOCKWaitReadable
          unless @timeout_time && (Time.now > @timeout_time) && @status == :Running
            UI.start_timer(0.5) { read_client_stdout() }
          end
        rescue 
          # When the spawned process closes we will receive an EOFError
          # Success or failure of the spawned process is determined by the presence/absence of data in the stderr pipe  
          begin
            @error_message = @stderr_r.read_nonblock(10000)
            @status = :Process_Failed
            @update_caller = true
            #puts error_message
          rescue 
            @status = :Process_Completed_Normally
            @update_caller = true
          end
        end
        
        if @timeout_time && (Time.now > @timeout_time) && @status == :Running
            @status = :Closed
            @error_message = 'Client Timed Out'
            @update_caller = true
            close()
        end
          
      
        @callback_block.call(self) if @update_caller
        @update_caller = false
        
        # close pipes unless we are running or already closed
        close_pipes() unless @status == :Running || @status == :Closed
   
      end
    end #module

    class AsyncRubyRunner
      include AsyncRunnerCore
      def initialize(client, args)
        super
        prog = 'rubyw'
        @env = {'GEM_HOME' => nil,'GEM_PATH'=> nil}
        @cmd  = [prog, client, args]
      end
      
    end
    
    class AsyncOSRunner
      include AsyncRunnerCore
      def initialize(prog, args)
        super
        @env = {}
        @cmd  = [prog, args]
      end
      
    end
    
  end
end    
 

SW::AsyncRunner.run_async_demo()
nil
