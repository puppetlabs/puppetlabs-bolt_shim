#!/opt/puppetlabs/puppet/bin/ruby
# frozen_string_literal: true

require 'base64'
require 'json'

def write_file(path, content, mode)
  source = Base64.decode64(content)
  File.open(path, 'w') do |f|
    f.chmod(mode)
    f.write(source)
  end
  { success: true }
end

params = JSON.parse(STDIN.read)

result = write_file(params['path'], params['content'], params['mode'])

puts result.to_json
