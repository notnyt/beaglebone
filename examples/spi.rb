#!/usr/bin/env ruby
require 'beaglebone'

include  Beaglebone

#SPI test hooked up to MCP3008

#oo methods
spi = SPIDevice.new(:SPI0)

loop do
  # communicate with MCP3008
  # byte 1: start bit
  # byte 2: single(1)/diff(0),3 bites for channel, null pad
  # byte 3: don't care
  raw = spi.xfer([ 0b00000001, 0b10000000, 0].pack("C*"))
  data = raw.unpack("C*")

  val = ((data[1] & 0b00000011) << 8 ) | data[2]
  puts val


  raw = spi.xfer([ 0b00000001, 0b10010000, 0].pack("C*"))
  data = raw.unpack("C*")

  val = ((data[1] & 0b00000011) << 8 ) | data[2]
  puts val


  sleep 0.25
end

exit


#procedural methods

SPI.setup(:SPI0)

loop do
  # communicate with MCP3008
  # byte 1: start bit
  # byte 2: single(1)/diff(0),3 bites for channel, null pad
  # byte 3: don't care
  raw = SPI.xfer(:SPI0, [ 0b00000001, 0b10000000, 0].pack("C*"))
  data = raw.unpack("C*")

  val = ((data[1] & 0b00000011) << 8 ) | data[2]
  puts val


  raw = SPI.xfer(:SPI0, [ 0b00000001, 0b10010000, 0].pack("C*"))
  data = raw.unpack("C*")

  val = ((data[1] & 0b00000011) << 8 ) | data[2]
  puts val


  sleep 0.25
end

exit
