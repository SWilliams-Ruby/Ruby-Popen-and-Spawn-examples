# Sketchup Ruby STDOUT Patch to restore IO.popen and Kernal.spawn functionality

Out of the box, versions of Sketchup that run on Windows do not allow child processes to inherit STDOUT. The result is that the various Kernel.spawn and IO.popen methods do not function. It should be noted that if Sketchup is started from a command prompt, a batch file 'START' command, or a terminal window in a debugger, the child processes will inherit STDOUT and function properly. This repository contains a patch that restores the function of STDOUT in situations where it is not enabled by default.

SW_enable_child_stdout.rb contains the code to 'flip' the flag in the RTL_USER_PROCESS_PARAMETERS that allows STDOUT to be inherited.

SW_async_runner.rb is a set of utilities to facilitate asynchronous communication with child processes.

SW_async_runner_examples.rb. Examples of running several asynchronous processses in parallel.

python_async_client.py and ruby_async_client.rb are the two of child processes that are used in the demonstration.
