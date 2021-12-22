module SW
  module AsyncRunnerExamples

    def self.run_async_demo()
      run_ruby_example()
      #run_dir_example()
      run_python_example()
    end
    
    def self.run_dir_example()
      prog = 'dir'
      args = ''
      async_runner = SW::AsyncRunner::OSAsyncRunner.new(prog, args)
      async_runner.run() { |async_runner|
        puts async_runner.data.pop(true) rescue :NoData
        puts async_runner.status
        puts async_runner.error_message if async_runner.status != :Running
      }
    end

    def self.run_python_example()
      path = 'C:\Users\User\Documents\sketchup code\sw_async_runner\src\python_async_client.py'
      prog = 'pythonw'
      args = path
      async_runner = SW::AsyncRunner::OSAsyncRunner.new(prog, args)
      async_runner.run(:live) { |async_runner|
        puts async_runner.data.pop(true) rescue :NoData
        puts async_runner.status
        puts async_runner.error_message if async_runner.status != :Running
      }
    end
    
    def self.run_ruby_example()
      client = 'C:/Users/User/Documents/sketchup code/SW_async_runner/src/ruby_async_client.rb'
      args = 'Other Args'
      #args = 'force_error' #uncomment this line to test error handling
      async_runner = SW::AsyncRunner::RubyAsyncRunner.new(client, args)
      #async_runner.set_timeout(1)

      async_runner.run(:live) { |async_runner|
        puts async_runner.data.pop(true) rescue :NoData
        puts async_runner.status
        puts async_runner.error_message if async_runner.status != :Running
      }
  
      async_runner.stdin_puts 'hello from STDIN'
      # async_runner.close() # test closing the process
    end

    
  end
end    
 

SW::AsyncRunnerExamples.run_async_demo()
nil
