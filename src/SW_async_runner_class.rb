
module SW
  class AsyncClient

      def initialize(client_path, method)
        prog = 'rubyw'
        #client_path = 'C:/Users/User/Documents/sketchup code/sw_popen/src/SW_async_client.rb'
        args = 'Other Args'
        #args = 'force_error' #uncomment this line to test error handling
        cmd  = [prog, client_path, args]
        popen(cmd) if  method == :popen
        spawn(cmd) if method == :spawn
      end

      def popen(cmd)
        env = {'GEM_HOME' => nil,'GEM_PATH'=> nil}
        cmd = [env, *cmd, :err=>[:child, :out]]
        @client_io = IO.popen(cmd, mode = 'a+')
        
        @client_io.puts 'hello from STDIN'
        @client_status = :running
        handle_client_results_popen()
      end

      def handle_client_results_popen()
        begin
          @client_status = loop do 
            data = @client_io.read_nonblock(10000)
            puts data
            break :Process_Completed if /SU_ASYNC_RUNNER_Completed/ =~ data
            break :Process_Failed if data.nil? #client closed
          end
        rescue IO::EWOULDBLOCKWaitReadable
          UI.start_timer(0.5) { handle_client_results_popen() }
        rescue # everything else
          @client_status = :failed
        end
        
        if @client_status != :running
          puts "Popen Client status: #{@client_status}"
        end
      end

      def spawn(cmd)
        in_r, @in_w = IO.pipe
        @out_r, out_w = IO.pipe
        #@err_r, err_w = IO.pipe
        env = {'GEM_HOME' => nil,'GEM_PATH'=> nil}
        pid = Kernel.spawn(env, *cmd, :in=>in_r, :out=>out_w, :err=>[:child, :out])
        in_r.close
        out_w.close
        #err_w.close
        
        @in_w.puts 'hello from STDIN'
        @client_status = :running
        handle_client_results_spawn() 
      end
        
      def handle_client_results_spawn
        begin
          @client_status = loop do 
            data = @out_r.read_nonblock(10000)
            puts data
            break :Process_Completed if /SU_ASYNC_RUNNER_Completed/ =~ data
            break :Process_Failed if data.nil?
          end
        rescue IO::EWOULDBLOCKWaitReadable
          UI.start_timer(0.5) { handle_client_results_spawn() }
        rescue # everytjhing else
          @client_status = :failed
        end
        
        if @client_status != :running
          puts "Spawn Client status: #{@client_status}"
          @out_r.close
        end
        
      end
    end
  end
  
client_path = 'C:/Users/User/Documents/sketchup code/sw_popen/src/SW_async_client.rb'
SW::AsyncClient.new(client_path, :popen)
SW::AsyncClient.new(client_path, :spawn)

nil
