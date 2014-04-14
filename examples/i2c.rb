#!/usr/bin/env ruby
require 'beaglebone'



#i2c testing hooked up to LSM303DLHC

#oo method
i2c = I2CDevice.new(:I2C2)

#put mag into continuous conversation mode
i2c.write(0x1e, [0x02, 0x00].pack("C*"))

#enable temperatuer sensor, 15hz register update
i2c.write(0x1e, [0x00, "10010000".to_i(2)].pack("C*") )

#delay for the settings to take effect
sleep(0.1)

loop do

  #read axis data
  raw = i2c.read(0x1e, 6, [0x03].pack("C*"))

  #coordinates are signed shorts in x,z,y order
  x,z,y = raw.unpack("s>*")

  #calculate angle
  degrees = (Math::atan2(y, x) * 180) / Math::PI
  degrees += 360 if degrees < 0

  #read 2 bytes from temperature register
  raw = i2c.read(0x1e, 2, [0x31].pack("C*"))
  #temperature is sent big endian, lsd last
  temp = raw.unpack("S>").first
  #temp is 12 bits, last 4 are unused
  temp = temp >> 4

  #twos complement
  temp -= 65535 if temp > 32767

  #each bit is 8c
  temp /= 8

  #correction factor
  temp += 19

  #convert to f
  temp = (temp * 1.8 + 32).to_i


  puts "#{Time.now.strftime("%H:%M")}  temp: #{temp} degrees f        direction: #{degrees.to_i} degrees"
  sleep 1
end

exit


#procedural method


#i2c testing
I2C.setup(:I2C2)


#put mag into continuous conversation mode
I2C.write(:I2C2, 0x1e, [0x02, 0x00].pack("C*"))
#enable temperatuer sensor, 15hz register update
I2C.write(:I2C2, 0x1e, [0x00, "10010000".to_i(2)].pack("C*") )
#delay for the settings to take effect
sleep(0.1)


loop do

  #read axis data
  raw = I2C.read(:I2C2, 0x1e, 6, [0x03].pack("C*"))

  #coordinates are signed shorts in x,z,y order
  x,z,y = raw.unpack("s>*")

  #calculate angle
  degrees = (Math::atan2(y, x) * 180) / Math::PI
  degrees += 360 if degrees < 0

  #read 2 bytes from temperature register
  raw = I2C.read(:I2C2, 0x1e, 2, [0x31].pack("C*"))
  #temperature is sent big endian, lsd last
  temp = raw.unpack("S>").first
  #temp is 12 bits, last 4 are unused
  temp = temp >> 4

  #twos complement
  temp -= 65535 if temp > 32767

  #each bit is 8c
  temp /= 8

  #correction factor
  temp += 19

  #convert to f
  temp = (temp * 1.8 + 32).to_i


  puts "#{Time.now.strftime("%H:%M")}  temp: #{temp} degrees f        direction: #{degrees.to_i} degrees"
  sleep 60
end

exit
