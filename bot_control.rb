#!/usr/bin/env ruby

require 'rubygems'
require 'daemons'

Daemons.run('watcher.rb')
