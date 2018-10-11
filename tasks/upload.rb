#!/opt/puppetlabs/puppet/bin/ruby
# frozen_string_literal: true

require 'base64'
require 'fileutils'
require 'json'

def write_dir(path, content, mode)
  require 'puppet'
  require 'puppet/module_tool/tar'
  Tempfile.open('upload.tar.gz') do |tgz|
    tgz.chmod(0o600)
    File.binwrite(tgz, Base64.decode64(content))

    # Puppet's tar doesn't give us control over where a directory is unpacked, so we pack
    # the files in the directory than unpack into a new one.
    Dir.mkdir(path, mode)
    Puppet::ModuleTool::Tar.instance.unpack(tgz, path, Etc.getlogin || Etc.getpwuid.name)
  end
end

def write_file(path, content, mode)
  source = Base64.decode64(content)
  File.open(path, 'w') do |f|
    f.chmod(mode)
    f.write(source)
  end
end

params = JSON.parse(STDIN.read)

if params['directory']
  write_dir(params['path'], params['content'], params['mode'])
else
  write_file(params['path'], params['content'], params['mode'])
end

puts({ success: true }.to_json)
