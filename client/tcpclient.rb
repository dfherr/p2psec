#!/usr/bin/env ruby

require 'socket'
require 'byebug'

s = TCPSocket.new 'fulcrum.net.in.tum.de', 34151

byebug

puts s
