# frozen_string_literal: true

# The {Platform} module.
module Platform
  HOST_CPU = RbConfig::CONFIG['host_cpu'].downcase

  CPU = case HOST_CPU
        when /amd64|x86_64|x64/
          'x86_64'
        when /i\d86|x86|i86pc/
          'i386'
        when /arm64|aarch64/
          'aarch64'
        when /arm/
          'arm'
        when /ppc64le|powerpc64le/
          'ppc64le'
        else
          HOST_CPU
        end

  HOST_OS = RbConfig::CONFIG['host_os'].downcase

  OS = case HOST_OS
       when /darwin/
         'darwin'
       when /linux-android/
         'linux-android'
       when /linux-musl/
         'linux-musl'
       when /linux-none/
         'linux-none'
       when /linux-uclibc/
         'linux-uclibc'
       when /linux/
         'linux'
       when *Gem::WIN_PATTERNS
         'windows'
       else
         HOST_OS
       end

  ARCH = "#{CPU}-#{OS}".freeze
end
