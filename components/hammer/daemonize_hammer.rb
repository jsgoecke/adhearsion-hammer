#!/usr/bin/env ruby
require 'rubygems'
require 'daemons'

file_to_run = File.expand_path(File.dirname(__FILE__) + '/hammer.rb')
Daemons.run(file_to_run)