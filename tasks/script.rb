#!/opt/puppetlabs/puppet/bin/ruby
# frozen_string_literal: true

require 'base64'
require 'json'
require 'open3'
require 'tempfile'
require 'pathname'
require 'fileutils'

module WinHelpers
  class << self
    def windows?
      !!File::ALT_SEPARATOR
    end

    def powershell_script?(path)
      Pathname(path).extname.casecmp('.ps1').zero?
    end

    def run_script(arguments, script_path)
      mapped_args = arguments.map { |a|
        "$invokeArgs.ArgumentList += @'\n#{a}\n'@"
      }.join("\n")
      <<-PS
    $invokeArgs = @{
      ScriptBlock = (Get-Command "#{script_path}").ScriptBlock
      ArgumentList = @()
    }
    #{mapped_args}

    try
    {
      Invoke-Command @invokeArgs
    }
    catch
    {
      Write-Error $_.Exception
      exit 1
    }
    PS
    end
  end
end

def with_tmpscript(content, script_name)
  Dir.mktmpdir(nil, File.expand_path(__dir__)) do |dir|
    dest = File.join(dir, script_name)
    File.write(dest, Base64.decode64(content))
    File.chmod(0o750, dest)
    yield dest, dir
  end
end

def error(msg)
  { stdout: '',
    stderr: msg,
    exit_code: 1 }
end

def command(command, arguments = [], options = {})
  stdout, stderr, p = Open3.capture3(*command, *arguments, chdir: options[:dir])
  { stdout: stdout,
    stderr: stderr,
    exit_code: p.exitstatus }
end

def script(content, arguments, script_name)
  if script_name.nil?
    legacy_bolt = true
    script_name = 'bolt_script'
  end

  with_tmpscript(content, script_name) do |file, dir|
    if WinHelpers.windows?
      return error('Error: Incompatible Bolt version. Update to puppet-bolt version => 1.11.0') if legacy_bolt
      return error('Error: Only powershell scripts are supported on windows targets.') unless WinHelpers.powershell_script?(file)
      command(['powershell.exe'] + [WinHelpers.run_script(arguments, file)], nil, dir: dir)
    else
      command(file, arguments, dir: dir)
    end
  end
end

params = JSON.parse(STDIN.read)

result = script(params['content'], params['arguments'], params['name'])

puts result.to_json
