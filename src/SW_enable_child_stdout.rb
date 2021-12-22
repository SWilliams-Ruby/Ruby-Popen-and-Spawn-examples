require 'fiddle'
require 'fiddle/import'
require 'fiddle/types'

# Reset the RTL WindowFlag that enables STDOUT in Child Processes
# S. Williams
# December 1, 2021

module SW
  module Util

    # typedef struct _RTL_USER_PROCESS_PARAMETERS
    # {
        # ULONG               AllocationSize;
        # ULONG               Size;
        # ULONG               Flags;
        # ULONG               DebugFlags;
        # HANDLE              ConsoleHandle;
        # ULONG               ConsoleFlags;
        # HANDLE              hStdInput;
        # HANDLE              hStdOutput;
        # HANDLE              hStdError;
        # CURDIR              CurrentDirectory; / 0x40 /
        # UNICODE_STRING      DllPath;
        # UNICODE_STRING      ImagePathName;
        # UNICODE_STRING      CommandLine;
        # PWSTR               Environment; / 0x80 /
        # ULONG               dwX;
        # ULONG               dwY;
        # ULONG               dwXSize;
        # ULONG               dwYSize;
        # ULONG               dwXCountChars;
        # ULONG               dwYCountChars;
        # ULONG               dwFillAttribute;
        # ULONG               dwFlags; / 0xA4 / <<<<<<<<<<<<<<<<<<
        # ULONG               wShowWindow;
        # UNICODE_STRING      WindowTitle;
        # UNICODE_STRING      Desktop;
        # UNICODE_STRING      ShellInfo;
        # UNICODE_STRING      RuntimeInfo;
        # RTL_DRIVE_LETTER_CURDIR DLCurrentDirectory[0x20];
        # ULONG_PTR           EnvironmentSize;
        # ULONG_PTR           EnvironmentVersion;
        # PVOID               PackageDependencyData;
        # ULONG               ProcessGroupId;
        # ULONG               LoaderThreads;
    # } RTL_USER_PROCESS_PARAMETERS, *PRTL_USER_PROCESS_PARAMETERS;
        
    def self.enable_child_stdout()
      rtl_ptr = get_RTL_pointer()

      # read the flags byte
      current_value = rtl_ptr[0xa5]
      p "STDIO flags were: #{current_value.to_s(2)}"
      
      if (current_value & 0x04) != 0
        new_value =  current_value & 0xfb
        rtl_ptr[0xa5] = new_value
      end
      
    end

    # Offset 0x20in the PEB is RTL_USER_PROCESS_PARAMETERS *ProcessParameters;
    # see: https://pastebin.com/am5RNncE
    #
    def self.get_RTL_pointer()
      pebBaseAddress = get_PEB_pointer()
      rtl_adr = pebBaseAddress[0x20, 8]
      address = rtl_adr.unpack('Q')[0]
      rtl_ptr = Fiddle::Pointer.new(address)
      # puts "RTL"
      # memory_dump_ptr(rtl_ptr, 16)
      rtl_ptr
    end

    # Process_Environment_Block
    # https://docs.microsoft.com/en-us/windows/win32/api/winternl/ns-winternl-peb
    # https://en.wikipedia.org/wiki/Process_Environment_Block
    def self.get_PEB_pointer()
      pbi = get_PBI()
      # puts "PEB"
      # memory_dump_ptr(pbi.pebBaseAddress)
      pbi.pebBaseAddress
    end

    # PROCESS_BASIC_INFORMATION
    # retrieve the ProcessBasicInformation
    # https://docs.microsoft.com/en-us/windows/win32/api/winternl/nf-winternl-ntqueryinformationprocess
    #
    def self.get_PBI()
      len = Fiddle::malloc(8)
      pbi = Ntdll::PBI.malloc()
      processInformationClass = 0
      ntstatus = Ntdll.NtQueryInformationProcess(get_current_process(), processInformationClass, pbi, 48, len);
      #p ntstatus.to_s(16)
      # dump_pbi(pbi)
      pbi
    end

    # Dump the PROCESS_BASIC_INFORMATION
    #
    def self.dump_pbi(pbi)
      puts
      puts 'pbi dump'
      puts "ExitStatus #{pbi.exitStatus.to_s(16)}"
      p pbi.pebBaseAddress
      puts "AffinityMask #{pbi.affinityMask.to_s(16)}"
      puts "BasePriority #{pbi.basePriority.to_s(16)}"
      puts "UniqueProcessId #{pbi.uniqueProcessId}"
      puts "ParentProcessId #{pbi.parentProcessId}"
    end
    
    # GetCurrentProcess function (processthreadsapi.h)
    # https://docs.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-getcurrentprocess
    #
    def self.get_current_process()
      return -1
    end
  
    module Ntdll
      extend Fiddle::Importer
      dlload 'ntdll'
      include Fiddle::Win32Types

      # https://docs.microsoft.com/en-us/windows/win32/api/winternl/nf-winternl-ntqueryinformationprocess
      # __kernel_entry NTSTATUS NtQueryInformationProcess(
      # [in]            HANDLE           ProcessHandle,
      # [in]            PROCESSINFOCLASS ProcessInformationClass,
      # [out]           PVOID            ProcessInformation, # This is the PBI
      # [in]            ULONG            ProcessInformationLength,
      # [out, optional] PULONG           ReturnLength
      # );

      # from Ruby 2.2 Win32.c
      # get_process_parent_pid __kernel_entry NTSTATUS NtQueryInformationProcess
      #  typedef long (WINAPI query_func)(HANDLE, int, void *, ULONG, ULONG *);
      #  static query_func *pNtQueryInformationProcess = NULL;
      #
      # struct {
      #   long ExitStatus;
      #   void* PebBaseAddress;
      #   uintptr_t AffinityMask;
      #   uintptr_t BasePriority;
      #   uintptr_t UniqueProcessId;
      #   uintptr_t ParentProcessId;
      # } pbi;

      # Fiddle::CStructEntity.size(
        # [ Fiddle::TYPE_LONG,
          # Fiddle::TYPE_VOIDP,
          # Fiddle::TYPE_UINTPTR_T,
          # Fiddle::TYPE_UINTPTR_T,
          # Fiddle::TYPE_UINTPTR_T,
          # Fiddle::TYPE_UINTPTR_T]
        # ) # => 48
        
      PBI = struct [
        'long exitStatus',
        'void* pebBaseAddress',
        'uintptr_t affinityMask',
        'uintptr_t basePriority',
        'uintptr_t uniqueProcessId',
        'uintptr_t parentProcessId'
      ]
     
      extern 'long NtQueryInformationProcess(HANDLE, int, struct *, ULONG, ULONG *)'   

    end
    
    ################################
    # generic memory dump routines
    ################################ 
    
    # Dump ruby object. Count is the number of 16 byte lines
    #
    def self.memory_dump_object(object, count = 8)
      address = object.object_id << 1
      memory_dump_address(address, count)
    end

    # Dump a memory address
    #
    def self.memory_dump_address(address, count = 8)
      ptr = Fiddle::Pointer.new(address)
      memory_dump_ptr(ptr, count)
    end

    # Dump memory at [Fiddle::Pointer] ptr
    #
    def self.memory_dump_ptr(ptr, count = 8)
      offset  = 0
      count.times {
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
      puts
    end

    # Dump a string a hexadecimal bytes
    #
    def self.dump_string_as_hex(str)
      p str.each_byte.map { |b| (b < 16 ? ' 0' + b.to_s(16) : ' ' + b.to_s(16)) }.join
    end
    
  end
end

SW::Util.enable_child_stdout()
nil




