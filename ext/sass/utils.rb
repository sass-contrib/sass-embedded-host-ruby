# frozen_string_literal: true

# The {Utils} module.
module Utils
  module_function

  def capture(...)
    require 'open3'

    stdout, stderr, status = Open3.capture3(...)

    raise stderr unless status.success?

    stdout
  end

  def fetch_https(source_uri)
    require 'rubygems/remote_fetcher'

    source_uri = begin
      Gem::Uri.parse!(source_uri)
    rescue NoMethodError
      URI.parse(source_uri)
    end

    Gem::RemoteFetcher.fetcher.fetch_https(source_uri)
  end

  def windows_system_directory
    path = capture('powershell.exe',
                   '-NoLogo',
                   '-NoProfile',
                   '-NonInteractive',
                   '-Command',
                   '[Environment]::GetFolderPath([Environment+SpecialFolder]::System) | Write-Host -NoNewline')

    File.absolute_path(path)
  end
end
