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
    PS_ARGS = %w[
      -NoProfile -NonInteractive -NoLogo -ExecutionPolicy Bypass
    ].freeze

    def windows?
      !!File::ALT_SEPARATOR
    end

    def powershell_script?(extension)
      extension.casecmp('.ps1').zero?
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

    def process_from_extension(path)
      case Pathname(path).extname.downcase
      when '.rb'
        [
          'ruby.exe',
          ['-S', "\"#{path}\""],
        ]
      when '.ps1'
        [
          'powershell.exe',
          [*PS_ARGS, '-File', "\"#{path}\""],
        ]
      when '.pp'
        [
          'puppet.bat',
          ['apply', "\"#{path}\""],
        ]
      else
        # Run the script via cmd, letting Windows extension handling determine how
        [
          'cmd.exe',
          ['/c', "\"#{path}\""],
        ]
      end
    end

    def escape_arguments(arguments)
      arguments.map do |arg|
        if arg =~ %r{ }
          "\"#{arg}\""
        else
          arg
        end
      end
    end
  end
end

def in_tmpdir
  dir = Dir.mktmpdir
  yield dir
ensure
  FileUtils.remove_entry dir if dir
end

def with_tmpscript(content, script_name)
  in_tmpdir do |dir|
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
      if WinHelpers.powershell_script?(file)
        command(['powershell.exe'] + [WinHelpers.run_script(arguments, file)], nil, dir: dir)
      else
        path, args = *WinHelpers.process_from_extension(file)
        args += WinHelpers.escape_arguments(arguments)
        command(args.unshift(path).join(' '), nil, dir: dir)
      end
    else
      command(file, arguments, dir: dir)
    end
  end
end

params = JSON.parse(STDIN.read)

result = script(params['content'], params['arguments'], params['name'])

puts result.to_json
