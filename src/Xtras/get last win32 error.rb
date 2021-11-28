



#To reproduce run the following on 64-bit and 32-bit SketchUp (I tested on windows 7 and windows 10)

require 'Win32API'

NORMAL_PRIORITY_CLASS = 0x00000020
STARTUP_INFO_SIZE = 68
PROCESS_INFO_SIZE = 16
SECURITY_ATTRIBUTES_SIZE = 12

ERROR_SUCCESS = 0x00
FORMAT_MESSAGE_FROM_SYSTEM = 0x1000
FORMAT_MESSAGE_ARGUMENT_ARRAY = 0x2000

HANDLE_FLAG_INHERIT = 1
HANDLE_FLAG_PROTECT_FROM_CLOSE =2

STARTF_USESHOWWINDOW = 0x00000001
STARTF_USESTDHANDLES = 0x00000100

def raise_last_win_32_error
  errorCode = Win32API.new("kernel32", "GetLastError", [], 'L').call
  if errorCode != ERROR_SUCCESS
    params = [
        'L', # IN DWORD dwFlags,
        'P', # IN LPCVOID lpSource,
        'L', # IN DWORD dwMessageId,
        'L', # IN DWORD dwLanguageId,
        'P', # OUT LPSTR lpBuffer,
        'L', # IN DWORD nSize,
        'P', # IN va_list *Arguments
    ]

    formatMessage = Win32API.new("kernel32", "FormatMessage", params, 'L')
    msg = ' ' * 4000
    msgLength = formatMessage.call(FORMAT_MESSAGE_FROM_SYSTEM + FORMAT_MESSAGE_ARGUMENT_ARRAY, '', errorCode, 0, msg, 4000, '')
    puts msg
    msg.gsub!(/\000/, '')
    msg.strip!

    raise msg
  else
    raise 'GetLastError returned ERROR_SUCCESS'
  end
end

# def create_pipe # returns read and write handle
  # params = [
      # 'P', # pointer to read handle
      # 'P', # pointer to write handle
      # 'P', # pointer to security attributes
      # 'L'] # pipe size

  # createPipe = Win32API.new("kernel32", "CreatePipe", params, 'I')

  # read_handle, write_handle = [0].pack('I'), [0].pack('I')
  # sec_attrs = [SECURITY_ATTRIBUTES_SIZE, 0, 1].pack('III')

  # raise_last_win_32_error if createPipe.Call(read_handle, write_handle, sec_attrs, 0).zero?

  # [read_handle.unpack('I')[0], write_handle.unpack('I')[0]]
# end

# create_pipe
# =====================


# require "fiddle"# Default 

# libm=Fiddle.dlopen('C:/Users/Administrator/Documents/Visual Studio 2015/Projects/miniDll/x64/Debug/miniDll.dll')

# test1=Fiddle::Function.new(libm['Init_miniDll'], [Fiddle::TYPE_FLOAT]*2,Fiddle::TYPE_FLOAT]

# =========================================
# require 'fiddle/import'
# #
# # KING SABRI | @KINGSABRI
# #
# if ARGV.size == 2
  # lpfilename  = ARGV[0] # Library Name
  # lpprocname  = ARGV[1] # Function Name
# else
  # puts "ruby arwin.rb <Library Name> <Function Name>"
  # puts "example:\n arwin.rb user32.dll MessageBoxA"
  # #exit 0
# end

  # lpfilename  = 'ntdll.dll'
  # lpprocname  = 'NtQueryInformationProcess'



# module Kernel32

  # # Extend this module to an importer
  # extend Fiddle::Importer
  # # Load 'user32' dynamic library into this importer
  # dlload 'kernel32'

  # # HMODULE WINAPI LoadLibrary(
  # #   _In_ LPCTSTR lpFileName
  # # );
  # typealias 'lpfilename', 'char*'
  # extern 'unsigned char* LoadLibrary(lpfilename)'

  # # FARPROC WINAPI GetProcAddress(
  # #   _In_ HMODULE hModule,
  # #   _In_ LPCSTR  lpProcName
  # # );
  # typealias 'lpfilename', 'char*'
  # typealias 'lpprocname', 'char*'
  # extern 'unsigned char* GetProcAddress(lpfilename, lpprocname)'

# end



# address = Kernel32::GetProcAddress(Kernel32::LoadLibrary(lpfilename), lpprocname).inspect.scan(/0x[\h]+/i)[1]
# unless address.hex.zero?
  # puts "\n[+] #{lpprocname} is location at #{address} in #{lpfilename}\n"
# else
  # puts "[!] Could find #{lpprocname} in #{lpfilename}!"
  # puts "[-] Function's name is case sensitive"
# end
