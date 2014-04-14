#!/usr/bin/env ruby
require 'beaglebone'

include  Beaglebone

###object oriented methods###
#flash leds
led1 = GPIOPin.new(:USR0, :OUT)
led2 = GPIOPin.new(:USR1, :OUT)
led3 = GPIOPin.new(:USR2, :OUT)
led4 = GPIOPin.new(:USR3, :OUT)

5.times do
  led1.digital_write(:HIGH)
  sleep 0.25
  led1.digital_write(:LOW)

  led2.digital_write(:HIGH)
  sleep 0.25
  led2.digital_write(:LOW)

  led3.digital_write(:HIGH)
  sleep 0.25
  led3.digital_write(:LOW)

  led4.digital_write(:HIGH)
  sleep 0.25
  led4.digital_write(:LOW)
end

exit

#basic GPIO reads and writes
p9_11 = GPIOPin.new(:P9_11, :IN)
p9_12 = GPIOPin.new(:P9_12, :OUT)

puts p9_11.digital_read
p9_12.digital_write(:HIGH)
puts p9_11.digital_read
p9_12.digital_write(:LOW)
puts p9_11.digital_read


exit

##gpio edge trigger with callback
p9_11 = GPIOPin.new(:P9_11, :IN)
p9_12 = GPIOPin.new(:P9_12, :OUT)

#toggle output pin randomly in a separate there
Thread.new do
  loop do
    sleep rand(100) / 100.0
    p9_12.digital_write(:LOW)
    sleep rand(100) / 100.0
    p9_12.digital_write(:HIGH)
  end
end

#run on edge trigger with callback
callback = lambda { |pin,edge,count| p9_11.stop_edge_wait if count == 10;puts "[#{count}] #{pin} #{edge}"}
p9_11.run_on_edge(callback, :BOTH)


sleep 10000
exit

#or without callback
loop do
  edge = p9_11.wait_for_edge(:RISING)
  puts "!! TRIGGERED ON #{edge}"

  edge = p9_11.wait_for_edge(:RISING)
  puts "!! TRIGGERED ON #{edge}"

  edge = p9_11.wait_for_edge(:BOTH)
  puts "!! TRIGGERED ON #{edge}"
end

#gpio edge trigger
p9_11 = GPIOPin.new(:P9_11, :IN)
p9_12 = GPIOPin.new(:P9_12, :OUT)

Thread.new do
  loop do
    sleep rand(100) / 100.0
    p9_12.digital_write(:LOW)
    sleep rand(100) / 100.0
    p9_12.digital_write(:HIGH)
  end
end


loop do
  edge = p9_11.wait_for_edge(:RISING)
  puts "!! TRIGGERED ON #{edge}"

  edge = p9_11.wait_for_edge(:RISING)
  puts "!! TRIGGERED ON #{edge}"

  edge = p9_11.wait_for_edge(:BOTH)
  puts "!! TRIGGERED ON #{edge}"
end



#shift register via gpio, specified latch, clock, and data pins
shiftreg = ShiftRegister.new(:P9_11, :P9_12, :P9_13)
data = 255
shiftreg.shiftout(data)

exit



###procedural methods###

#gpio edge trigger callback
GPIO.pin_mode(:P9_12, :OUT)
GPIO.pin_mode(:P9_11, :IN)
GPIO.run_on_edge(lambda { |pin,edge,count| puts "[#{count}] #{pin} -- #{edge}" }, :P9_11, :BOTH)

leds = [ :USR0, :USR1, :USR2, :USR3 ]
leds.each do |ledpin|
  GPIO.pin_mode(ledpin, :OUT)
end

x = 0
loop do
#gpio write to led pins
  leds.each do |ledpin|
    GPIO.digital_write(ledpin, :LOW)
  	sleep 0.25
    GPIO.digital_write(ledpin, :HIGH)
  end
	x += 1

	if x == 10
		GPIO.stop_edge_wait(:P9_11)
		puts 'STOP'
	end
  if x == 15
    GPIO.run_on_edge(lambda { |pin,edge,count| puts "[#{count}] #{pin} -- #{edge}" }, :P9_11, :BOTH)
		puts 'OK GO AGAIN'
		x = 0
	end

end


exit

#gpio edge trigger
GPIO.pin_mode(:P9_12, :OUT)
GPIO.pin_mode(:P9_11, :IN)

loop do
	edge = GPIO.wait_for_edge(:P9_11, :RISING)
	puts "!! TRIGGERED ON #{edge}"
end


#standard gpio setup and testing
GPIO.pin_mode(:P9_12, :OUT)
puts GPIO.enabled?(:P9_12)
puts GPIO.get_gpio_mode(:P9_12)

#gpio setup for led pins
leds = [ :USR0, :USR1, :USR2, :USR3 ]
leds.each do |ledpin|
	GPIO.pin_mode(ledpin, :OUT)
end

#gpio write to led pins
leds.each do |ledpin|
	GPIO.digital_write(ledpin, :LOW)
end


#gpio write
loop do
	GPIO.digital_write(:P9_12, :HIGH)
	sleep 0.25
	GPIO.digital_write(:P9_12, :LOW)
	sleep 0.25
end


GPIO.cleanup
exit

# gpio read
GPIO.pin_mode(:P9_12, :IN)
loop do
	puts GPIO.digital_read(:P9_12)
end
