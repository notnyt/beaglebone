#!/usr/bin/env ruby
require 'beaglebone'

include  Beaglebone

#SPI test hooked up to MCP3008

#oo methods

# Initialize SPI device SPI0
spi = SPIDevice.new(:SPI0)

# communicate with MCP3008
# byte 1: start bit
# byte 2: single(1)/diff(0),3 bites for channel, null pad
# byte 3: don't care
# Read value from channel 0
raw = spi.xfer([ 0b00000001, 0b10000000, 0].pack("C*"))

# Split data read into an array of characters
data = raw.unpack("C*")

# The returned data is stored starting at the last two bits of the second byte
val = ((data[1] & 0b00000011) << 8 ) | data[2]

# Display the value of channel 0
puts "Value of channel 0: #{val}"

# Read value from channel 1
raw = spi.xfer([ 0b00000001, 0b10010000, 0].pack("C*"))

# Split data read into an array of characters
data = raw.unpack("C*")

# The returned data is stored starting at the last two bits of the second byte
val = ((data[1] & 0b00000011) << 8 ) | data[2]

# Display the value of channel 1
puts "Value of channel 1: #{val}"

# Disable SPI device
spi.disable
exit


#procedural methods

SPI.setup(:SPI0)

# communicate with MCP3008
# byte 1: start bit
# byte 2: single(1)/diff(0),3 bites for channel, null pad
# byte 3: don't care
# Read value from channel 0
raw = SPI.xfer(:SPI0, [ 0b00000001, 0b10000000, 0].pack("C*"))

# Split data read into an array of characters
data = raw.unpack("C*")

# The returned data is stored starting at the last two bits of the second byte
val = ((data[1] & 0b00000011) << 8 ) | data[2]

# Display the value of channel 0
puts "Value of channel 0: #{val}"

# Read value from channel 1
raw = SPI.xfer(:SPI0, [ 0b00000001, 0b10010000, 0].pack("C*"))
# Split data read into an array of characters
data = raw.unpack("C*")

# The returned data is stored starting at the last two bits of the second byte
val = ((data[1] & 0b00000011) << 8 ) | data[2]

# Display the value of channel 1
puts "Value of channel 1: #{val}"

SPI.disable(:SPI0)
exit
