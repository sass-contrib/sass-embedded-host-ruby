# frozen_string_literal: true

# This is a FileUtils extension that defines several additional commands to be
# added to the FileUtils utility functions.
module FileUtils
  def unarchive(archive, chdir: '.')
    if Gem.win_platform?
      sh File.absolute_path('tar.exe', Utils.windows_system_directory), '-vxf', archive, '-C', chdir
    elsif archive.downcase.end_with?('.zip')
      sh 'unzip', '-od', chdir, archive
    else
      sh 'tar', '-vxf', archive, '-C', chdir, '--no-same-owner', '--no-same-permissions'
    end
  end

  def fetch(source_uri, dest_path = nil)
    dest_path = File.basename(source_uri) if dest_path.nil?

    Rake.rake_output_message "fetch #{source_uri}" if Rake::FileUtilsExt.verbose_flag

    unless Rake::FileUtilsExt.nowrite_flag
      data = Utils.fetch_https(source_uri)
      Gem.write_binary(dest_path, data)
    end

    dest_path
  end

  def gem_install(name, version, platform)
    require 'rubygems/remote_fetcher'

    install_dir = File.absolute_path('ruby')

    if Rake::FileUtilsExt.verbose_flag
      Rake.rake_output_message [
        'gem', 'install',
        '--force',
        '--install-dir', install_dir,
        '--no-document', '--ignore-dependencies',
        '--platform', platform,
        '--version', version,
        'sass-embedded'
      ].join(' ')
    end

    dependency = Gem::Dependency.new(name, version)

    dependency_request = Gem::Resolver::DependencyRequest.new(dependency, nil)

    resolver_spec = Gem::Resolver::BestSet.new.find_all(dependency_request).find do |s|
      s.platform == platform
    end

    raise Gem::UnsatisfiableDependencyError, dependency_request if resolver_spec.nil?

    options = { force: true, install_dir: }
    if Rake::FileUtilsExt.nowrite_flag
      installer = Gem::Installer.for_spec(resolver_spec.spec, options)
    else
      path = resolver_spec.download(options)
      installer = Gem::Installer.at(path, options)
      installer.install
    end

    yield installer
  ensure
    rm_rf install_dir unless Rake::FileUtilsExt.nowrite_flag
  end

  def gh_attestation_verify(path, repo:, hostname: 'github.com')
    if SassConfig.development? && system('gh', 'auth', 'status', '--hostname', hostname, %i[out err] => File::NULL)
      sh 'gh', 'attestation', 'verify', path, '--hostname', hostname, '--repo', repo
    end
  end
end
