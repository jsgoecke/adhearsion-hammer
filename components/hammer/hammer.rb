require 'rubygems'
require 'activerecord'
require 'pp'
#require File.expand_path(File.dirname(__FILE__) + './db/models/*.rb')
require File.expand_path(File.dirname(__FILE__) + './hammer/libs/hammer.rb'

#Connect to Adhearsion instance
adhearsion = DRbObject.new_with_uri 'druby://localhost:9050'

hammer = Hammer.new(adhearsion)
loop do
  delay = hammer.make_calls
  sleep delay
end

