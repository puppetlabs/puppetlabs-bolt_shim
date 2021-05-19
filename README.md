
# bolt_shim

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with bolt_shim](#setup)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Reference - An under-the-hood peek at what the module is doing and how](#reference)

## Description

This module provides an adapter that allows Bolt to run commands, scripts, and upload files with PE Orchestrator.

This module is intended to allow Bolt plans to be run on a Puppet Enterprise (PE) installation by those with privileged access. Someone with the ability to run commands or scripts, or upload files, fundamentally has unrestricted access to their target.

## Setup

Install the Bolt shim. Using PE RBAC, grant the ability to run all tasks to those you intend to use this module.

## Usage

Configure Bolt to [work with PE Orchestrator](https://github.com/puppetlabs/puppetlabs-bolt_shim/blob/main/docs/connect_bolt_pe.md) and run Bolt commands.

## Reference

Provides three tasks to facilitate Bolt actions: `bolt_shim::command`, `bolt_shim::upload`, and `bolt_shim::script`. These are not meant to be run directly.
