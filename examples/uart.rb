#!/usr/bin/env ruby
require 'beaglebone'

#uart example
#oo method
uart1 = UARTDevice.new(:uart1, 9600)

uart1.writeln("TEST")

puts uart1.readchars(10)
puts uart1.readchar
puts uart1.readline

callback = lambda { |uart, line, count| puts "[#{uart}:#{count}] #{line} "}
#uart1.run_on_each_chars(callback, 3, 3)
#uart1.run_on_each_chars(callback, 3)
#uart1.run_on_each_char(callback, 3)
#uart1.run_once_on_each_chars(callback, 3)
#uart1.run_once_on_each_char(callback)
#uart1.run_on_each_chars(callback, 2)
uart1.run_on_each_line(callback)

sleep(5)
uart1.stop_read_wait


uart1.each_chars(2) { |c| puts c }
#uart1.each_line { |line| puts line }

uart1.disable

exit




#procedural method
UART.setup(:UART1, 9600)

UART.write(:UART1, "test1")

#puts UART.readchars(:UART1, 10)
#puts UART.readchar(:UART1)
#puts UART.readline(:UART1)

callback = lambda { |uart, line, count| puts "[#{uart}:#{count}] #{line} "}
#UART.run_on_each_chars(callback, :UART1, 3, 3)
#UART.run_on_each_chars(callback, :UART1, 3)
#UART.run_on_each_char(callback, :UART1, 3)
#UART.run_once_on_each_chars(callback, :UART1, 3)
#UART.run_once_on_each_char(callback, :UART1)
#UART.run_on_each_chars(callback, :UART1, 2)
UART.run_on_each_line(callback, :UART1)

sleep(5)
UART.stop_read_wait(:UART1)


UART.each_chars(:UART1, 2) { |c| puts c }
#UART.each_line(:UART1) { |line| puts line }

UART.cleanup

exit
