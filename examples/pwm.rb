#!/usr/bin/env ruby
require 'beaglebone'

include  Beaglebone

#pwm example

#oo method
p9_14 = PWMPin.new(:P9_14, 90, 10, :NORMAL)
sleep 1
p9_14.set_frequency(20)
sleep(1)
p9_14.set_duty_cycle(95)
sleep(1)
p9_14.set_duty_cycle(50)
sleep(1)
p9_14.set_frequency(2)
sleep(1)
p9_14.stop
sleep(1)
p9_14.run
sleep(1)
p9_14.set_frequency(32)
sleep(1)
p9_14.set_duty_cycle(94)
sleep(1)
p9_14.set_period_ns(31250000)
p9_14.set_duty_cycle_ns(31250000)
p9_14.set_period_ns(31249999)
p9_14.set_duty_cycle(10)
p9_14.set_polarity(:INVERTED)

p9_14.disable_pwm_pin
exit


#procedural method
PWM.start(:P9_14, 90, 10, :NORMAL)
sleep(1)
PWM.set_frequency(:P9_14, 20)
sleep(1)
PWM.set_duty_cycle(:P9_14, 95)
sleep(1)
PWM.set_duty_cycle(:P9_14, 50)
sleep(1)
PWM.set_frequency(:P9_14, 2)
sleep(1)
PWM.stop(:P9_14)
sleep(1)
PWM.run(:P9_14)
sleep(1)
PWM.set_frequency(:P9_14, 32)
sleep(1)
PWM.set_duty_cycle(:P9_14, 94)
sleep(1)
PWM.set_period_ns(:P9_14, 31250000)
PWM.set_duty_cycle_ns(:P9_14, 31250000)
PWM.set_period_ns(:P9_14, 31249999)
PWM.set_duty_cycle(:P9_14, 10)
PWM.set_polarity(:P9_14, :INVERTED)
sleep(1)
PWM.cleanup
exit
