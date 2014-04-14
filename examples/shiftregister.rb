#!/usr/bin/env ruby
require 'beaglebone'

include  Beaglebone

#shift reg via gpio

shiftreg = ShiftRegister.new(:P9_11, :P9_12, :P9_13)
data = 255
shiftreg.shiftout(data)

exit
