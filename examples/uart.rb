#!/usr/bin/env ruby
require 'beaglebone'

#uart example
#oo method
uart5 = UARTDevice.new(:UART5, 9600)

uart5.writeln("TEST")

puts uart5.readchars(10)
puts uart5.readchar
puts uart5.readline

callback = lambda { |uart, line, count| puts "[#{uart}:#{count}] #{line} "}
#uart5.run_on_each_chars(callback, 3, 3)
#uart5.run_on_each_chars(callback, 3)
#uart5.run_on_each_char(callback, 3)
#uart5.run_once_on_each_chars(callback, 3)
#uart5.run_once_on_each_char(callback)
#uart5.run_on_each_chars(callback, 2)
uart5.run_on_each_line(callback)

sleep(5)
uart5.stop_read_wait


uart5.each_chars(2) { |c| puts c }
#uart5.each_line { |line| puts line }

uart5.disable

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
