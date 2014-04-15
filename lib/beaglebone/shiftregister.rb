# == shiftregister.rb
# This file contains the shiftregister control methods
module Beaglebone #:nodoc:
  class ShiftRegister

    # Create a shiftregister object based on 3 GPIO pins
    #
    # @param latch_pin should be a symbol representing the header pin, i.e. :P9_12
    # @param clock_pin should be a symbol representing the header pin, i.e. :P9_13
    # @param data_pin should be a symbol representing the header pin, i.e. :P9_14
    # @param lsb optional, send least significant bit first if set
    #
    # @example
    #   shiftregister = ShiftRegister.new(:P9_11, :P9_12, :P9_13)
    def initialize(latch_pin, clock_pin, data_pin, lsb=nil)

      @latch_pin = latch_pin
      @clock_pin = clock_pin
      @data_pin  = data_pin
      @lsb       = lsb

      GPIO::pin_mode(@latch_pin, :OUT)
      GPIO::pin_mode(@clock_pin, :OUT)
      GPIO::pin_mode(@data_pin, :OUT)
    end

    # Send data to shift register
    #
    # @param data Integer value to write to the shift register
    # @param lsb optional, send least significant bit first if set
    #
    # @example
    #   shiftregister = ShiftRegister.new(:P9_11, :P9_12, :P9_13)
    #   shiftregister.shift_out(255)
    def shiftout(data, lsb=nil)
      GPIO::shift_out(@latch_pin, @clock_pin, @data_pin, data, lsb || @lsb)
    end

  end
end
