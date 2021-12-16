# Changelog

All notable changes to this project will be documented in this file.

## Release 0.4.0

**Feature**

Create tmpdir relative to the directory that tasks are uploaded to. This allows users who have the
system tmpdir mounted with noexec to use the `run_script` shim task.

## Release 0.3.1

**Bugfixes**

Document support for Puppet 6

## Release 0.3.0

**Feature**

Add support for running powershell scripts on windows targets.

## Release 0.2.1

**Bugfixes**

Mark file content as sensitive to prevent it being logged or stored in a database to improve the overall Bolt experience.

## Release 0.2.0

**Feature**

Add support for uploading directories. Corresponds to Bolt 1.1.0.

## Release 0.1.1

**Bugfixes**

Add puppet-blacksmith to support module release process.

## Release 0.1.0

Initial release of bolt_shim. Works with Bolt 0.19.0.
