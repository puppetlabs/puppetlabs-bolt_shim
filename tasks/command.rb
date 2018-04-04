#!/opt/puppetlabs/puppet/bin/ruby
# frozen_string_literal: true

require 'json'
require 'open3'

def command(command, arguments = [])
  stdout, stderr, p = Open3.capture3(command, *arguments)
  { stdout: stdout,
    stderr: stderr,
    exit_code: p.exitstatus }
end

params = JSON.parse(STDIN.read)

result = command(params['command'])

puts result.to_json
