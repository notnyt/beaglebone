module Beaglebone
  class ShiftRegister

    def initialize(latch_pin, clock_pin, data_pin, lsb=nil)

      @latch_pin = latch_pin
      @clock_pin = clock_pin
      @data_pin  = data_pin
      @lsb       = lsb

      GPIO::pin_mode(@latch_pin, :OUT)
      GPIO::pin_mode(@clock_pin, :OUT)
      GPIO::pin_mode(@data_pin, :OUT)
    end

    def shiftout(data, lsb=nil)
      GPIO::shift_out(@latch_pin, @clock_pin, @data_pin, data, lsb || @lsb)
    end

  end
end
