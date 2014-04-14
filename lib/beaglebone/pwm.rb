# == pwm.rb
# This file contains the PWM control methods
module Beaglebone #:nodoc:
  # AIN
  # procedural methods for PWM control
  # == Summary
  # #start is called to enable a PWM pin
  module PWM

    # Polarity hash
    POLARITIES = { :NORMAL => 0, :INVERTED => 1 }

    class << self

      # Initialize a PWM pin
      #
      # == Attributes
      # +pin+ should be a symbol representing the header pin
      # +duty+ should specify the duty cycle
      # +frequency+ should specify cycles per second
      # +polarity+ optional, should specify the polarity, :NORMAL or :INVERTED
      # +run+ optional, if false, pin will be configured but will not run
      #
      # == Examples
      # PWM.start(:P9_14, 90, 10, :NORMAL)
      def start(pin, duty=nil, frequency=nil, polarity=nil, run=true)
        #make sure the pwm controller dtb is loaded
        Beaglebone::device_tree_load(TREES[:PWM][:global])

        Beaglebone::check_valid_pin(pin, :pwm)

        #if pin is enabled for something else, disable it
        if Beaglebone::get_pin_status(pin) && Beaglebone::get_pin_status(pin, :type) != :pwm
          Beaglebone::disable_pin(pin)
        end

        #load device tree for pin if not already loaded
        unless Beaglebone::get_pin_status(pin, :type) == :pwm
          Beaglebone::device_tree_load("#{TREES[:PWM][:pin]}#{pin}")
          Beaglebone::set_pin_status(pin, :type, :pwm)
        end

        duty_fd = File.open("#{pwm_directory(pin)}/duty", 'r+')
        period_fd = File.open("#{pwm_directory(pin)}/period", 'r+')
        polarity_fd = File.open("#{pwm_directory(pin)}/polarity", 'r+')
        run_fd = File.open("#{pwm_directory(pin)}/run", 'r+')

        Beaglebone::set_pin_status(pin, :fd_duty, duty_fd)
        Beaglebone::set_pin_status(pin, :fd_period, period_fd)
        Beaglebone::set_pin_status(pin, :fd_polarity, polarity_fd)
        Beaglebone::set_pin_status(pin, :fd_run, run_fd)


        read_period_value(pin)
        read_duty_value(pin)
        read_polarity_value(pin)

        run_fd.write('0')
        run_fd.flush

        set_polarity(pin, polarity) if polarity
        set_frequency(pin, frequency) if frequency
        set_duty_cycle(pin, duty) if duty

        if run
          run_fd.write('1')
          run_fd.flush
        end

        raise StandardError, "Could not start PWM: #{pin}" unless read_run_value(pin) == 1
        true
      end

      # Returns true if specified pin is enabled in PWM mode, else false
      def enabled?(pin)
        return true if Beaglebone::get_pin_status(pin, :type) == :pwm

        return false unless valid?(pin)
        if Dir.exists?(pwm_directory(pin))

          start(pin, nil, nil, nil, false)
          return true
        end
        false
      end

      # Stop PWM output on specified pin
      # == Attributes
      # +pin+ should be a symbol representing the header pin
      def stop(pin)
        Beaglebone::check_valid_pin(pin, :pwm)

        return false unless enabled?(pin)

        raise StandardError, "Pin is not PWM enabled: #{pin}" unless Beaglebone::get_pin_status(pin, :type) == :pwm

        run_fd = Beaglebone::get_pin_status(pin, :fd_run)

        raise StandardError, "Pin is not PWM enabled: #{pin}" unless run_fd

        run_fd.write('0')
        run_fd.flush

        raise StandardError, "Could not stop PWM: #{pin}" unless read_run_value(pin) == 0
        true
      end

      # Start PWM output on specified pin.  Pin must have been previously started
      # == Attributes
      # +pin+ should be a symbol representing the header pin
      def run(pin)
        Beaglebone::check_valid_pin(pin, :pwm)

        return false unless enabled?(pin)

        raise StandardError, "Pin is not PWM enabled: #{pin}" unless Beaglebone::get_pin_status(pin, :type) == :pwm

        run_fd = Beaglebone::get_pin_status(pin, :fd_run)

        raise StandardError, "Pin is not PWM enabled: #{pin}" unless run_fd

        run_fd.write('1')
        run_fd.flush

        raise StandardError, "Could not start PWM: #{pin}" unless read_run_value(pin) == 1
        true

      end

      # Set polarity on specified pin
      #
      # == Attributes
      # +pin+ should be a symbol representing the header pin
      # +polarity+ should specify the polarity, :NORMAL or :INVERTED
      # == Example
      # PWM.set_polarity(:P9_14, :INVERTED)
      def set_polarity(pin, polarity)
        check_valid_polarity(polarity)
        check_pwm_enabled(pin)

        polarity_fd = Beaglebone::get_pin_status(pin, :fd_polarity)
        raise StandardError, "Pin is not PWM enabled: #{pin}" unless polarity_fd

        polarity_fd.write(POLARITIES[polarity.to_sym].to_s)
        polarity_fd.flush

        raise StandardError, "Could not set polarity: #{pin}" unless read_polarity_value(pin) == POLARITIES[polarity.to_sym]

      end

      # Set duty cycle of specified pin in percentage
      #
      # == Attributes
      # +pin+ should be a symbol representing the header pin
      # +duty+ should specify the duty cycle in percentage
      # == Example
      # PWM.set_duty_cycle(:P9_14, 25)
      def set_duty_cycle(pin, duty, newperiod=nil)

        raise ArgumentError, "Duty cycle must be >= 0 and <= 100, #{duty} invalid" if duty < 0 || duty > 100
        check_pwm_enabled(pin)


        fd = Beaglebone::get_pin_status(pin, :fd_duty)
        raise StandardError, "Pin is not PWM enabled: #{pin}" unless fd

        period = newperiod || Beaglebone::get_pin_status(pin, :period)

        value = ((duty * period) / 100).to_i

        fd.write(value.to_s)
        fd.flush

        raise StandardError, "Could not set duty cycle: #{pin} (#{value})" unless read_duty_value(pin) == value

        value

      end


      # Set duty cycle of specified pin in nanoseconds
      #
      # == Attributes
      # +pin+ should be a symbol representing the header pin
      # +duty+ should specify the duty cycle in nanoseconds
      # == Example
      # PWM.set_duty_cycle_ns(:P9_14, 2500000)
      def set_duty_cycle_ns(pin, duty)

        check_pwm_enabled(pin)

        fd = Beaglebone::get_pin_status(pin, :fd_duty)
        raise StandardError, "Pin is not PWM enabled: #{pin}" unless fd

        period = Beaglebone::get_pin_status(pin, :period)

        duty = duty.to_i

        if duty < 0 || duty > period
          raise ArgumentError, "Duty cycle ns must be >= 0 and <= #{period} (current period), #{duty} invalid"
        end

        value = duty

        fd.write(value.to_s)
        fd.flush

        raise StandardError, "Could not set duty cycle: #{pin} (#{value})" unless read_duty_value(pin) == value

        value
      end

      # Set frequency of specified pin in cycles per second
      #
      # == Attributes
      # +pin+ should be a symbol representing the header pin
      # +frequency+ should specify the frequency in cycles per second
      # == Example
      # PWM.set_frequency(:P9_14, 100)
      def set_frequency(pin, frequency)
        frequency = frequency.to_i
        raise ArgumentError, "Frequency must be > 0 and <= 1000000000, #{frequency} invalid" if frequency < 1 || frequency > 1000000000
        check_pwm_enabled(pin)

        fd = Beaglebone::get_pin_status(pin, :fd_period)
        raise StandardError, "Pin is not PWM enabled: #{pin}" unless fd

        duty_ns = Beaglebone::get_pin_status(pin, :duty)
        duty_pct = Beaglebone::get_pin_status(pin, :duty_pct)

        value = (1000000000 / frequency).to_i

        #we can't set the frequency lower than the previous duty cycle
        #adjust if necessary
        if duty_ns > value
          set_duty_cycle(pin, Beaglebone::get_pin_status(pin, :duty_pct), value)
        end

        fd.write(value.to_s)
        fd.flush

        raise StandardError, "Could not set frequency: #{pin} (#{value})" unless read_period_value(pin) == value

        #adjust the duty cycle if we haven't already
        if duty_ns <= value
          set_duty_cycle(pin, duty_pct, value)
        end

        value
      end

      # Set frequency of specified pin based on period duration
      #
      # == Attributes
      # +pin+ should be a symbol representing the header pin
      # +period+ should specify the length of a cycle in nanoseconds
      # == Example
      # PWM.set_frequency_ns(:P9_14, 100000000)
      def set_period_ns(pin, period)
        period = period.to_i
        raise ArgumentError, "period must be > 0 and <= 1000000000, #{period} invalid" if period < 1 || period > 1000000000
        check_pwm_enabled(pin)

        fd = Beaglebone::get_pin_status(pin, :fd_period)
        raise StandardError, "Pin is not PWM enabled: #{pin}" unless fd

        duty_ns = Beaglebone::get_pin_status(pin, :duty)
        value = period.to_i

        #we can't set the frequency lower than the previous duty cycle
        #adjust if necessary
        if duty_ns > value
          set_duty_cycle(pin, Beaglebone::get_pin_status(pin, :duty_pct), value)
        end

        fd.write(value.to_s)
        fd.flush

        raise StandardError, "Could not set period: #{pin} (#{value})" unless read_period_value(pin) == value

        #adjust the duty cycle if we haven't already
        if duty_ns <= value
          set_duty_cycle(pin, Beaglebone::get_pin_status(pin, :duty_pct), value)
        end

        value
      end

      #reset all PWM pins we've used to IN and unexport them
      def cleanup
        get_pwm_pins.each { |x| disable_pwm_pin(x) }
      end


      # Return an array of PWM pins in use
      #
      # == Example
      # PWM.get_pwm_pins => [:P9_13, :P9_14]
      def get_pwm_pins
        Beaglebone.pinstatus.clone.select { |x,y| x if y[:type] == :pwm}.keys
      end

      # Disable a PWM pin
      # == Attributes
      # +pin+ should be a symbol representing the header pin
      def disable_pwm_pin(pin)
        Beaglebone::check_valid_pin(pin, :pwm)
        Beaglebone::delete_pin_status(pin) if Beaglebone::device_tree_unload("#{TREES[:PWM][:pin]}#{pin}")
      end

      private

      #ensure pin is valid pwm pin
      def valid?(pin)
        #check to see if pin exists
        pin = pin.to_sym.upcase

        return false unless PINS[pin]
        return false unless PINS[pin][:pwm]

        true
      end

      #ensure pin is pwm enabled
      def check_pwm_enabled(pin)
        raise StandardError, "Pin is not PWM enabled: #{pin}" unless enabled?(pin)
      end

      #read run file
      def read_run_value(pin)
        check_pwm_enabled(pin)

        fd = Beaglebone::get_pin_status(pin, :fd_run)
        raise StandardError, "Pin is not PWM enabled: #{pin}" unless fd

        fd.rewind
        fd.read.strip.to_i
      end

      #read polarity file
      def read_polarity_value(pin)
        check_pwm_enabled(pin)

        fd = Beaglebone::get_pin_status(pin, :fd_polarity)
        raise StandardError, "Pin is not PWM enabled: #{pin}" unless fd

        fd.rewind
        value = fd.read.strip.to_i

        Beaglebone::set_pin_status(pin, :polarity, value)

      end

      #read duty file
      def read_duty_value(pin)
        check_pwm_enabled(pin)

        fd = Beaglebone::get_pin_status(pin, :fd_duty)
        raise StandardError, "Pin is not PWM enabled: #{pin}" unless fd

        fd.rewind
        value = fd.read.strip.to_i

        Beaglebone::set_pin_status(pin, :duty, value)
        Beaglebone::set_pin_status(pin, :duty_pct, ((value * 100) / Beaglebone::get_pin_status(pin, :period).to_i))

        value
      end

      #read period file
      def read_period_value(pin)
        check_pwm_enabled(pin)

        fd = Beaglebone::get_pin_status(pin, :fd_period)
        raise StandardError, "Pin is not PWM enabled: #{pin}" unless fd

        fd.rewind
        value = fd.read.strip.to_i

        Beaglebone::set_pin_status(pin, :period, value)
        Beaglebone::set_pin_status(pin, :duty_pct, ((Beaglebone::get_pin_status(pin, :duty).to_i * 100) / value).to_i)

        value
      end

      #return sysfs directory for pwm control
      def pwm_directory(pin)
        raise StandardError, 'Invalid Pin' unless valid?(pin)
        Dir.glob("/sys/devices/ocp.*/pwm_test_#{pin}.*").first
      end

      #ensure polarity is valid
      def check_valid_polarity(polarity)
        #check to see if mode is valid
        polarity = polarity.to_sym.upcase
        raise ArgumentError, "No such polarity: #{polarity.to_s}" unless POLARITIES.include?(polarity)
      end

    end
  end

  # Object Oriented PWM Implementation.
  # This treats the pin as an object.
  class PWMPin

    # Initialize a PWM pin
    #
    # == Attributes
    # +duty+ should specify the duty cycle
    # +frequency+ should specify cycles per second
    # +polarity+ optional, should specify the polarity, :NORMAL or :INVERTED
    # +run+ optional, if false, pin will be configured but will not run
    #
    # == Examples
    # p9_14 = PWMPin.new(:P9_14, 90, 10, :NORMAL)

    def initialize(pin, duty=nil, frequency=nil, polarity=nil, run=true)
      @pin = pin
      PWM::start(@pin, duty, frequency, polarity, run)
    end

    # Stop PWM output on pin
    def stop
      PWM::stop(@pin)
    end

    # Start PWM output on pin.  Pin must have been previously started
    def run
      PWM::run(@pin)
    end

    # Set polarity on pin
    #
    # == Attributes
    # +polarity+ should specify the polarity, :NORMAL or :INVERTED
    # == Example
    # p9_14.set_polarity(:INVERTED)
    def set_polarity(polarity)
      PWM::set_polarity(@pin, polarity)
    end

    # Set duty cycle of pin in percentage
    #
    # == Attributes
    # +duty+ should specify the duty cycle in percentage
    # == Example
    # p9_14.set_duty_cycle(25)
    def set_duty_cycle(duty, newperiod=nil)
      PWM::set_duty_cycle(@pin, duty, newperiod)
    end

    # Set duty cycle of pin in nanoseconds
    #
    # == Attributes
    # +duty+ should specify the duty cycle in nanoseconds
    # == Example
    # p9_14.set_duty_cycle_ns(2500000)
    def set_duty_cycle_ns(duty)
      PWM::set_duty_cycle_ns(@pin, duty)
    end

    # Set frequency of pin in cycles per second
    #
    # == Attributes
    # +frequency+ should specify the frequency in cycles per second
    # == Example
    # p9_14.set_frequency(100)
    def set_frequency(frequency)
      PWM::set_frequency(@pin, frequency)
    end

    # Set frequency of pin based on period duration
    #
    # == Attributes
    # +period+ should specify the length of a cycle in nanoseconds
    # == Example
    # p9_14.set_frequency_ns(100000000)
    def set_period_ns(period)
      PWM::set_period_ns(@pin, period)
    end

    # Disable PWM pin
    def disable_pwm_pin
      PWM::disable_pwm_pin(@pin)
    end
  end

end
