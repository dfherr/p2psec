#!/usr/bin/env ruby

require 'socket'

s = TCPSocket.new 'fulcrum.net.in.tum.de', 34151

puts s
