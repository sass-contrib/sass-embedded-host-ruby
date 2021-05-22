# frozen_string_literal: true



module Sass
  module Platform

    OS = case RbConfig::CONFIG['host_os'].downcase
         when /linux/
           "linux"
         when /darwin/
           "darwin"
         when /freebsd/
           "freebsd"
         when /netbsd/
           "netbsd"
         when /openbsd/
           "openbsd"
         when /dragonfly/
           "dragonflybsd"
         when /sunos|solaris/
           "solaris"
         when /mingw|mswin/
           "windows"
         else
           RbConfig::CONFIG['host_os'].downcase
         end

    OSVERSION = RbConfig::CONFIG['host_os'].gsub(/[^\d]/, '').to_i

    CPU = RbConfig::CONFIG['host_cpu']

    ARCH = case CPU.downcase
           when /amd64|x86_64|x64/
             "x86_64"
           when /i\d86|x86|i86pc/
             "i386"
           when /ppc64|powerpc64/
             "powerpc64"
           when /ppc|powerpc/
             "powerpc"
           when /sparcv9|sparc64/
             "sparcv9"
           when /arm64|aarch64/  # MacOS calls it "arm64", other operating systems "aarch64"
             "aarch64"
           when /^arm/
             if OS == "darwin"   # Ruby before 3.0 reports "arm" instead of "arm64" as host_cpu on darwin
               "aarch64"
             else
               "arm"
             end
           else
             RbConfig::CONFIG['host_cpu']
           end
  end
end
