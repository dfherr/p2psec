#!/usr/bin/env ruby

require 'socket'
require 'byebug'
require 'digest'
require 'parallel'

#
# email = "xxxxxx@mytum.de"
# firstname = "Dennis-Florian"
# lastname = "Herr"
# team_number = [0].pack("n")
# project_choice = [4963].pack("n") # DHT
# REQUEST_PART_1 = "#{team_number}#{project_choice}"
# REQUEST_PART_2 = email + "\r\n" + firstname  + "\r\n" + lastname  + "\r\n"
# sha256 = Digest::SHA256.new
#
# challenge = [0, 0, 0, 0, 72, 203, 168, 189].pack("CCCCCCCC")
#
# for_sha = challenge + REQUEST_PART_1 + [0, 10000].pack("NN") + REQUEST_PART_2
# puts for_sha.bytes.inspect
# sha_size = 60
# zero_padds = ((((sha_size+1) * 8) + 64) % 512 - 512).abs / 8
# zero_padd_array = Array.new(zero_padds, 0)
# SHA_PADDING = [128].pack("C") + zero_padd_array.pack("C*") + [0,60].pack("NN")
# puts (for_sha+SHA_PADDING).bytes.inspect
# puts (for_sha+SHA_PADDING).size
# puts sha256.digest(for_sha+SHA_PADDING).bytes.inspect


Parallel.each([1,2,3,4], in_processes: 4) do |worker|
  puts "Worker #{worker} running"

  email = "xxxxxx@mytum.de"
  firstname = "Dennis-Florian"
  lastname = "Herr"
  team_number = [0].pack("n")
  project_choice = [4963].pack("n") # DHT
  sha_size = 60
  zero_padds = ((((sha_size+1) * 8) + 64) % 512 - 512).abs / 8
  zero_padd_array = Array.new(zero_padds, 0)
  SHA_PADDING = [128].pack("C") + zero_padd_array.pack("C*") + [0,60].pack("NN")

  ENROLL_REGISTER = [681].pack("n")

  sha256 = Digest::SHA256.new

  REQUEST_PART_1 = "#{team_number}#{project_choice}"
  REQUEST_PART_2 = email + "\r\n" + firstname  + "\r\n" + lastname  + "\r\n"
  TRIES = 2**21
  THRESHOLD = 8

  tries = 0
  while true do
    tries = tries + 1
    puts "Try: #{tries}, worker #{worker}"
    t = Time.now
    s = TCPSocket.new('fulcrum.net.in.tum.de', 34151)
    r = s.recvfrom(12)[0]
    puts "Response code: " + r[2..3].unpack("n")[0].to_s
    puts "Raw response: " + r.inspect
    puts "Response bytes: " + r.bytes.inspect
    puts (Time.now - t).to_f

    challenge = r.bytes[4..12].pack("CCCCCCCC")
    t = Time.now
    count = 0
    for i in 0..TRIES do
      count = count + 1
      sha = sha256.digest(challenge + REQUEST_PART_1 + [0, count].pack("NN") + REQUEST_PART_2 + SHA_PADDING)
      if sha[0..3].unpack("N")[0] < THRESHOLD || sha[28..32].unpack("L")[0] < THRESHOLD
        puts "\n\n\n\n\n\nENOUGH ZEROES!!!!\n\n\n\n\n\n"
        break
      end
    end

    puts "Runtime: #{"%3.4f" % (Time.now - t).to_f}. Sha Bytes: " + sha.bytes.inspect
    if sha[0..3].unpack("N")[0] > THRESHOLD && sha[28..32].unpack("L")[0] > THRESHOLD
      puts "Threshold not reached"
      s.close
      next
    end

    puts "Left side: #{sha[0..3].unpack("N")[0]}, Right side: #{sha[28..32].unpack("L")[0]}"

    request = challenge + REQUEST_PART_1 + [0, count].pack("NN") + REQUEST_PART_2
    request = [request.size].pack("n") + ENROLL_REGISTER + request

    s.send(request, 0)
    r2 = s.recvfrom(100)[0]
    s.close
    begin
      response_code = r2[2..3].unpack("n")[0].to_s
    rescue NoMethodError
      puts "Timeout"
      next
    end
    puts "Response code: " + response_code
    raise Parallel:Kill if response_code != "683"
    puts "Raw 2nd response: " + r2.inspect
    puts "2nd response bytes: " + r2.bytes.inspect
  end

end
