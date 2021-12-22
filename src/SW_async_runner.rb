# RubyAsyncRunner
# OSAsyncRunner
# new (prog, args)
# run(:live) { |async_runner| ... }

# methods
# set_timeout
# close

# attr_readers
# :data, 
# :status, 
# :live_connection, 
# :error_message




module SW
  module AsyncRunner
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
        @status = :Closed
        @error_message = 'Client Closed'
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
          # This loop will throw IO::EWOULDBLOCKWaitReadable when the
          # pipe is empty on the second or later iteration
          loop do 
            break unless @status == :Running # The timer can wake us up after we are closed?
            @data << @stdout_r.read_nonblock(10000)
            @update_caller = true  if @live_connection
          end
          
        rescue IO::EWOULDBLOCKWaitReadable
          # Requeue unless we have timed out
          unless @timeout_time && (Time.now > @timeout_time) && @status == :Running
            UI.start_timer(0.5) { read_client_stdout() }
          end
          
        rescue 
          # When the spawned process closes we will receive an EOFError. Success or
          # failure of the spawned process is determined by the presence/absence of
          # data in the stderr pipe  
          begin
            @error_message = @stderr_r.read_nonblock(10000)
            @status = :Process_Failed
            @update_caller = true
            #puts error_message
          rescue 
            # The spawned process completed successfully
            @status = :Process_Completed_Normally
            @update_caller = true
          end
        end
        
        # Close the spawned process if we have timed out.
        if @timeout_time && (Time.now > @timeout_time) && @status == :Running
          close()
          @error_message = 'Client Timed Out'
          @update_caller = true
        end
      
        # Update the caller
        @callback_block.call(self) if @update_caller
        @update_caller = false
        
        # If we ae shutting down, close the pipes unless we are running or already closed
        close_pipes() unless @status == :Running || @status == :Closed
   
      end
    end #module

    class RubyAsyncRunner
      include AsyncRunnerCore
      def initialize(client, args)
        super
        prog = 'rubyw'
        @env = {'GEM_HOME' => nil,'GEM_PATH'=> nil}
        @cmd  = [prog, client, args]
      end
      
    end
    
    class OSAsyncRunner
      include AsyncRunnerCore
      def initialize(prog, args)
        super
        @env = {}
        @cmd  = [prog, args]
      end
      
    end
    
  end
end    
nil
