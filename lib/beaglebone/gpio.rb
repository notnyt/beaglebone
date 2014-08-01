# == gpio.rb
# This file contains the GPIO methods

module Beaglebone #:nodoc:
  # == GPIO
  # procedural methods for GPIO control
  # == Summary
  # #pin_mode is called to initialize a pin.
  # Further basic functionality is available with #digital_read and #digital_write
  module GPIO
    class << self
      # GPIO modes
      MODES = [ :IN, :OUT ]
      # GPIO states
      STATES = { :HIGH => 1, :LOW => 0 }
      # Edge trigger options
      EDGES = [ :NONE, :RISING, :FALLING, :BOTH ]
      # Slew rates
      SLEWRATES = [ :SLOW, :FAST ]
      # pull modes
      PULLMODES = [ :PULLUP, :PULLDOWN, :NONE ]

      # dts template for GPIO pin
      GPIOTEMPLATE = '/*
 * This is a template-generated file
 */

/dts-v1/;
/plugin/;

/{
    compatible = "ti,beaglebone", "ti,beaglebone-black";
    part_number = "BS_PINMODE_!PIN_KEY!_!DATA!";

    exclusive-use =
        "!PIN_DOT_KEY!",
        "!PIN_FUNCTION!";

    fragment@0 {
        target = <&am33xx_pinmux>;
        __overlay__ {
            bs_pinmode_!PIN_KEY!_!DATA!: pinmux_bs_pinmode_!PIN_KEY!_!DATA! {
                pinctrl-single,pins = <!PIN_OFFSET! !DATA!>;
            };
        };
    };

    fragment@1 {
        target = <&ocp>;
        __overlay__ {
            bs_pinmode_!PIN_KEY!_!DATA!_pinmux {
                compatible = "bone-pinmux-helper";
                status = "okay";
                pinctrl-names = "default";
                pinctrl-0 = <&bs_pinmode_!PIN_KEY!_!DATA!>;
            };
        };
    };
};
'
      # Initialize a GPIO pin
      #
      # @param pin should be a symbol representing the header pin
      # @param mode should specify the mode of the pin, either :IN or :OUT
      # @param pullmode (optional) should specify the pull mode, :PULLUP, :PULLDOWN, or :NONE
      # @param slewrate (optional) should specify the slew rate, :FAST or :SLOW
      # @example
      #   GPIO.pin_mode(:P9_12, :OUT)
      #   GPIO.pin_mode(:P9_11, :IN, :PULLUP, :FAST)
      def pin_mode(pin, mode, pullmode = nil, slewrate = nil)

        #make sure a valid mode was passed
        check_valid_mode(mode)

        #make sure a valid pin was passed and that it supports GPIO
        Beaglebone::check_valid_pin(pin, :gpio)

        #get info from PINS hash
        pininfo = PINS[pin]

        #if pin is enabled for something else, disable it
        if Beaglebone::get_pin_status(pin) && Beaglebone::get_pin_status(pin, :type) != :gpio
          Beaglebone::disable_pin(pin)
        end

        pullmode = pullmode || :PULLUP
        slewrate = slewrate || :FAST

        raise ArgumentError, "Invalid Slew Rate (#{slewrate}) specified on: #{pin}" unless SLEWRATES.include?(slewrate)
        raise ArgumentError, "Invalid Pull Mode (#{pullmode}) specified on: #{pin}" unless PULLMODES.include?(pullmode)

        if mode == :IN and pullmode != :PULLUP and ( pininfo[:mmc] or pin == :P9_15 )
          raise ArgumentError, "Invalid Pull mode specified for pin: #{pin} (#{pullmode})"
        end

        #export pin unless its an on board LED, if it isn't already exported
        if pininfo[:led]
          raise StandardError, "LEDs only support OUT mode: #{pin.to_s}" unless mode == :OUT
          File.open("#{gpio_directory(pin)}/trigger", 'w') { |f| f.write('gpio') }
        else
          # if pin is not an onboard LED

          # create device tree overlay for this pin, do not force rebuild
          pin_data = create_device_tree(pin, mode, pullmode, slewrate, false)

          # unload previous dtb if loaded
          begin
            Beaglebone::device_tree_unload("#{TREES[:GPIO][:pin]}#{pin}_.*")
          rescue
            #
          end

          # load device tree overlay
          Beaglebone::device_tree_load("#{TREES[:GPIO][:pin]}#{pin}_0x#{pin_data.to_s(16)}")

          # export gpio pin
          File.open('/sys/class/gpio/export', 'w') { |f| f.write pininfo[:gpio] }
          #check to see if pin is GPIO enabled in /sys/class/gpio/
          raise StandardError, "GPIO was unable to initalize pin: #{pin.to_s}" unless enabled?(pin)

        end unless Beaglebone::get_pin_status(pin, :type) == :gpio

        #set pin mode
        unless pininfo[:led]
          set_gpio_mode(pin, mode)
          dir = read_gpio_direction(pin)
          raise StandardError, "GPIO was unable to set mode: #{pin.to_s} to #{mode.to_s} (#{dir})" if mode != dir
        end

        Beaglebone::set_pin_status(pin, :mode, mode)
      end

      # Sets a pin's output state
      #
      # @param pin should be a symbol representing the header pin
      # @param state should be a symbol representin the state, :HIGH or :LOW
      #
      # @example
      #   GPIO.digital_write(:P9_12, :HIGH)
      #   GPIO.digital_write(:P9_12, :LOW)
      def digital_write(pin, state)
        check_valid_state(state)
        check_gpio_enabled(pin)

        raise StandardError, "PIN not in GPIO OUT mode: #{pin}" unless get_gpio_mode(pin) == :OUT

        fd = get_value_fd(pin)
        fd.write STATES[state.to_sym].to_s
        fd.flush
        Beaglebone::set_pin_status(pin, :state, state)
      end

      # Reads a pin's input state and return that value
      #
      # @param pin should be a symbol representing the header pin, i.e. :P9_11
      #
      # @return [Symbol] :HIGH or :LOW
      #
      # @example
      #   GPIO.digital_read(:P9_11) => :HIGH
      def digital_read(pin)
        check_gpio_enabled(pin)

        raise StandardError, "PIN not in GPIO IN mode: #{pin}" unless get_gpio_mode(pin) == :IN

        fd = get_value_fd(pin)
        fd.rewind
        value = fd.read.to_s.strip
        state = STATES.key(value.to_i)

        Beaglebone::set_pin_status(pin, :state, state)
      end

      # Runs a callback on an edge trigger event.
      # This creates a new thread that runs in the background
      #
      # @param callback A method to call when the edge trigger is detected.  This method should take 3 arguments, the pin, the edge, and the counter
      # @param pin should be a symbol representing the header pin, i.e. :P9_11
      # @param edge should be a symbol representing the trigger type, e.g. :RISING, :FALLING, :BOTH
      # @param timeout is optional and specifies a time window to wait
      # @param repeats is optional and specifies the number of times the callback will be run
      #
      # @example
      #   GPIO.run_on_edge(lambda { |pin,edge,count| puts "[#{count}] #{pin} -- #{edge}" }, :P9_11, :RISING)
      def run_on_edge(callback, pin, edge, timeout = nil, repeats=nil)

        raise StandardError, "Already waiting for trigger on pin: #{pin}" if Beaglebone::get_pin_status(pin, :trigger)
        raise StandardError, "Already waiting for trigger on pin: #{pin}" if Beaglebone::get_pin_status(pin, :thread)

        thread = Thread.new(callback, pin, edge, timeout, repeats) do |c, p, e, t, r|
          begin
            count = 0
            loop do

              state = wait_for_edge(p, e, t, false)

              c.call(p, state, count) if c
              count += 1
              break if r && count >= r
            end
          rescue => ex
            puts ex
            puts ex.backtrace
          ensure
            cleanup_edge_trigger(p)
          end
        end

        Beaglebone::set_pin_status(pin, :thread, thread)
      end

      # Runs a callback one time on an edge trigger event.
      # This is a convenience method for run_on_edge
      # @see #run_on_edge
      def run_once_on_edge(callback, pin, edge, timeout = nil)
        run_on_edge(callback, pin, edge, timeout, 1)
      end

      # Stops any threads waiting for data on specified pin
      #
      # @param pin should be a symbol representing the header pin, i.e. :P9_11
      def stop_edge_wait(pin)
        thread = Beaglebone::get_pin_status(pin, :thread)

        thread.exit if thread
        thread.join if thread
      end

      # Wait for an edge trigger.
      # Returns the type that triggered the event, e.g. :RISING, :FALLING, :BOTH
      #
      # @returns [Symbol] :RISING, :FALLING, or :BOTH
      #
      # @param pin should be a symbol representing the header pin, i.e. :P9_11
      # @param edge should be a symbol representing the trigger type, e.g. :RISING, :FALLING, :BOTH
      # @param timeout is optional and specifies a time window to wait
      # @param disable is optional.  If set, edge trigger detection is cleared on return
      #
      # @example
      #   wait_for_edge(:P9_11, :RISING, 30) => :RISING
      def wait_for_edge(pin, edge, timeout = nil, disable=true)
        check_valid_edge(edge)
        raise ArgumentError, "Cannot wait for edge trigger NONE: #{pin}" if edge.to_sym == :NONE

        check_gpio_enabled(pin)
        raise StandardError, "PIN not in GPIO IN mode: #{pin}" unless get_gpio_mode(pin) == :IN

        #ensure we're the only ones waiting for this trigger
        if Beaglebone::get_pin_status(pin, :thread) && Beaglebone::get_pin_status(pin, :thread) != Thread.current
          raise StandardError, "Already waiting for trigger on pin: #{pin}"
        end

        if Beaglebone::get_pin_status(pin, :trigger) && Beaglebone::get_pin_status(pin, :thread) != Thread.current
          raise StandardError, "Already waiting for trigger on pin: #{pin}"
        end

        set_gpio_edge(pin, edge)

        fd = get_value_fd(pin)
        fd.read

        #select will return fd into the error set "es" if it recieves an interrupt
        _, _, es = IO.select(nil, nil, [fd], timeout)

        set_gpio_edge(pin, :NONE) if disable

        es ? digital_read(pin) : nil

      end

      # Resets all the GPIO pins that we have used and unexport them
      def cleanup
        get_gpio_pins.each { |x| disable_gpio_pin(x) }
      end

      # Returns true if specified pin is enabled in GPIO mode, else false
      def enabled?(pin)

        return true if Beaglebone::get_pin_status(pin, :type) == :gpio

        return false unless valid?(pin)
        if Dir.exists?(gpio_directory(pin))

          Beaglebone::set_pin_status(pin, :type, :gpio)
          return true
        end

        false
      end

      # Sends data to a shift register
      #
      # @param latch_pin should be a symbol representing the header pin, i.e. :P9_12
      # @param clock_pin should be a symbol representing the header pin, i.e. :P9_13
      # @param data_pin should be a symbol representing the header pin, i.e. :P9_14
      # @param data Integer value to write to the shift register
      # @param lsb optional, send least significant bit first if set
      #
      # @example
      #   GPIO.shift_out(:P9_11, :P9_12, :P9_13, 255)
      def shift_out(latch_pin, clock_pin, data_pin, data, lsb=nil)
        raise ArgumentError, "data must be > 0 (#{date}" if data < 0
        digital_write(latch_pin, :LOW)

        binary = data.to_s(2)
        pad = 8 - (binary.size % 8 )
        binary = ('0' * pad) + binary

        binary.reverse! if lsb

        binary.each_char do |bit|
          digital_write(clock_pin, :LOW)
          digital_write(data_pin, bit == '0' ? :LOW : :HIGH)
          digital_write(clock_pin, :HIGH)
        end
        digital_write(latch_pin, :HIGH)

        data
      end

      # Returns last known state from +pin+, reads state if unknown
      # @returns [Symbol] :HIGH or :LOW
      def get_gpio_state(pin)
        check_gpio_enabled(pin)

        state = Beaglebone::get_pin_status(pin, :state)
        return state if state

        digital_read(pin)
      end

      # Returns mode from +pin+, reads mode if unknown
      # @returns [Symbol] :IN or :OUT
      def get_gpio_mode(pin)
        check_gpio_enabled(pin)

        mode = Beaglebone::get_pin_status(pin, :mode)
        return mode if mode

        read_gpio_direction(pin)
      end

      # Set GPIO mode on an initialized pin
      #
      # @param pin should be a symbol representing the header pin
      # @param mode should specify the mode of the pin, either :IN or :OUT
      #
      # @example
      #   GPIO.set_gpio_mode(:P9_12, :OUT)
      #   GPIO.set_gpio_mode(:P9_11, :IN)
      def set_gpio_mode(pin, mode)
        Beaglebone::check_valid_pin(pin, :gpio)
        check_valid_mode(mode)
        check_gpio_enabled(pin)

        File.open("#{gpio_directory(pin)}/direction", 'w') { |f| f.write mode.to_s.downcase }
        Beaglebone::set_pin_status(pin, :mode, mode)
      end

      # Set GPIO edge trigger type on an initialized pin
      #
      # @param pin should be a symbol representing the header pin
      # @param edge should be a symbol representing the trigger type, e.g. :RISING, :FALLING, :BOTH
      # @param force is optional, if set will set the mode even if already set
      #
      # @example
      #   GPIO.set_gpio_edge(:P9_11, :RISING)
      def set_gpio_edge(pin, edge, force=nil)
        check_valid_edge(edge)
        Beaglebone::check_valid_pin(pin, :gpio)

        raise StandardError, "PIN not in GPIO IN mode: #{pin}" unless get_gpio_mode(pin) == :IN

        return if get_gpio_edge(pin) == edge && !force

        File.open("#{gpio_directory(pin)}/edge", 'w') { |f| f.write edge.to_s.downcase }
        testedge = read_gpio_edge(pin)
        if testedge != edge.to_s.downcase
          Beaglebone::delete_pin_status(pin, :trigger)
          raise StandardError, "GPIO was unable to set edge: #{pin.to_s} to #{edge.to_s}"
        end

        if edge.to_sym == :NONE
          Beaglebone::delete_pin_status(pin, :trigger)
        else
          Beaglebone::set_pin_status(pin, :trigger, edge.to_sym)
        end

      end

      # Returns the GPIO edge trigger type on an initialized pin
      # @return [Symbol] :NONE, :RISING, :FALLING, or :BOTH
      def get_gpio_edge(pin)
        check_gpio_enabled(pin)

        edge = Beaglebone::get_pin_status(pin, :trigger)
        return edge if edge

        read_gpio_edge(pin)
      end

      # Return an array of GPIO pins in use
      #
      # @return [Array<Symbol>]
      #
      # @example
      #   GPIO.get_gpio_pins => [:P9_12, :P9_13]
      def get_gpio_pins
        Beaglebone.pinstatus.clone.select { |x,y| x if y[:type] == :gpio && !PINS[x][:led] }.keys
      end

      # Disable a GPIO pin
      #
      # @param pin should be a symbol representing the header pin
      def disable_gpio_pin(pin)

        Beaglebone::check_valid_pin(pin, :gpio)

        pininfo = PINS[pin]

        close_value_fd(pin)

        #close any running threads
        stop_edge_wait(pin)

        #write to unexport to disable gpio
        File.open('/sys/class/gpio/unexport', 'w') { |f| f.write(pininfo[:gpio]) }

        #unload device tree
        Beaglebone::device_tree_unload("#{TREES[:GPIO][:pin]}#{pin}_.*") unless pininfo[:led]

        #remove status from hash so following enabled? call checks actual system
        Beaglebone::delete_pin_status(pin)

        #check to see if pin is GPIO enabled in /sys/class/gpio/
        raise StandardError, "GPIO was unable to uninitalize pin: #{pin.to_s}" if enabled?(pin)

      end

      private

      #ensure edge type is valid
      def check_valid_edge(edge)
        raise ArgumentError, "No such edge: #{edge.to_s}" unless EDGES.include?(edge)
      end

      #read gpio edge file
      def read_gpio_edge(pin)
        check_gpio_enabled(pin)
        File.open("#{gpio_directory(pin)}/edge", 'r').read.to_s.strip
      end

      #check if pin is valid to use as gpio pin
      def valid?(pin)
        #check to see if pin exists
        return false unless PINS[pin]
        return false unless PINS[pin][:gpio]

        true
      end

      #set edge trigger to none
      def cleanup_edge_trigger(pin)
        if Beaglebone::get_pin_status(pin, :thread) == Thread.current
          set_gpio_edge(pin, :NONE)
          Beaglebone::delete_pin_status(pin, :thread)
        end
      end

      #convenience method for getting gpio dir in /sys
      def gpio_directory(pin)
        raise StandardError, 'Invalid Pin' unless valid?(pin)
        #led's are in a special place
        if PINS[pin][:led]
          "/sys/class/leds/beaglebone:green:#{pin.to_s.downcase}"
        else
          #normal gpio pins
          "/sys/class/gpio/gpio#{PINS[pin][:gpio]}"
        end
      end

      #read gpio direction file
      def read_gpio_direction(pin)
        check_gpio_enabled(pin)

        Beaglebone::set_pin_status(pin, :mode, File.open("#{gpio_directory(pin)}/direction", 'r').read.to_s.strip.to_sym.upcase)
      end

      #return the open value fd, or open if needed
      def get_value_fd(pin)
        check_gpio_enabled(pin)

        fd = Beaglebone::get_pin_status(pin, :fd_value)
        return fd if fd

        pininfo = PINS[pin]

        #leds aren't normal gpio pins, we can toggle them on and off however.
        if pininfo[:led]
          fd = File.open("#{gpio_directory(pin)}/brightness", 'w+')
        else
          fd = File.open("#{gpio_directory(pin)}/value", 'w+')
        end

        Beaglebone::set_pin_status(pin, :fd_value, fd)
      end

      #close value fd if open
      def close_value_fd(pin)
        fd = Beaglebone::get_pin_status(pin, :fd_value)
        fd.close if fd
        Beaglebone::delete_pin_status(pin, :fd_value)
      end

      #ensure state is valid
      def check_valid_state(state)
        #check to see if mode is valid
        state = state.to_sym
        raise ArgumentError, "No such state: #{state.to_s}" unless STATES.include?(state)
      end

      #ensure mode is valid
      def check_valid_mode(mode)
        #check to see if mode is valid
        mode = mode.to_sym
        raise ArgumentError, "No such mode: #{mode.to_s}" unless MODES.include?(mode)
      end

      #ensure gpio pin is enabled
      def check_gpio_enabled(pin)
        Beaglebone::check_valid_pin(pin, :gpio)
        raise StandardError, "PIN not GPIO enabled: #{pin}" unless enabled?(pin)
      end

      def create_device_tree(pin, mode, pullmode, slewrate, force = false)
        #get info from PINS hash
        pininfo = PINS[pin]

        #generate data value for dts
        #Bit 15 PIN USAGE is an indicator and should be a 1 if the pin is used or 0 if it is unused.
        # Bits 14-7 RESERVED is not to be used and left as 0.
        # Bit 6 SLEW CONTROL 0=Fast 1=Slow
        # Bit 5 RX Enabled 0=Disabled 1=Enabled
        # Bit 4 PU/PD 0=Pulldown 1=Pullup.
        # Bit 3 PULLUP/DN 0=Pullup/pulldown enabled 1= Pullup/pulldown disabled
        # Bit 2-0 MUX MODE SELECT Mode 0-7. (refer to TRM)
        pin_data = 0
        pin_data |= 0b1000000 if slewrate == :SLOW
        pin_data |= 0b100000 if mode == :IN
        case pullmode
          when :PULLUP
            pin_data |= 0b10000
          when :NONE
            pin_data |= 0b1000
          else
            # default is pulldown enabled
        end
        #set mux mode, 7 is gpio
        pin_data |= 7

        dts = GPIOTEMPLATE.clone

        dts.gsub!('!PIN_KEY!', pin.to_s)
        dts.gsub!('!PIN_DOT_KEY!', pin.to_s.gsub('_', '.'))
        dts.gsub!('!PIN_FUNCTION!', pininfo[:gpiofunc])
        dts.gsub!('!PIN_OFFSET!', pininfo[:muxoffset])
        dts.gsub!('!DATA!', "0x#{pin_data.to_s(16)}")

        filename = "/lib/firmware/#{TREES[:GPIO][:pin]}#{pin}_0x#{pin_data.to_s(16)}-00A0"
        dts_fn = "#{filename}.dts"
        dtb_fn = "#{filename}.dtbo"

        # if we've already built this file, we don't need to do it again
        return pin_data if File.exists?(dtb_fn) && !force

        dts_file = File.open(dts_fn, 'w')
        dts_file.write(dts)
        dts_file.close

        system("dtc -O dtb -o #{dtb_fn} -b 0 -@ #{dts_fn}")

        pin_data
      end
    end
  end

  # Object Oriented GPIO Implementation.
  # This treats the pin as an object.
  class GPIOPin

    # Initialize a GPIO pin
    # Return's a GPIOPin object, setting the pin mode on initialization
    #
    # @param mode should specify the mode of the pin, either :IN or :OUT
    # @param pullmode (optional) should specify the pull mode, :PULLUP, :PULLDOWN, or :NONE
    # @param slewrate (optional) should specify the slew rate, :FAST or :SLOW
    #
    # @return [GPIOPin]
    #
    # @example
    #   p9_12 = GPIOPin.new(:P9_12, :OUT)
    #   p9_11 = GPIOPin.new(:P9_11, :IN)
    def initialize(pin, mode, pullmode = nil, slewrate = nil)
      @pin = pin

      GPIO::pin_mode(@pin, mode, pullmode, slewrate)
    end

    # Sets a pin's output state
    #
    # @param state should be a symbol representin the state, :HIGH or :LOW
    #
    # @example
    #   p9_12 = GPIOPin.new(:P9_12, :OUT)
    #   p9_12.digital_write(:HIGH)
    #   p9_12.digital_write(:LOW)
    def digital_write(state)
      GPIO::digital_write(@pin, state)
    end

    # Reads a pin's input state and return that value
    #
    # @return [Symbol] :HIGH or :LOW
    #
    # @example
    #   p9_11 = GPIOPin.new(:P9_12, :OUT)
    #   p9_11.digital_read => :HIGH
    def digital_read
      GPIO::digital_read(@pin)
    end

    # Runs a callback on an edge trigger event.
    # This creates a new thread that runs in the background
    #
    # @param callback A method to call when the edge trigger is detected.  This method should take 3 arguments, the pin, the edge, and the counter
    # @param edge should be a symbol representing the trigger type, e.g. :RISING, :FALLING, :BOTH
    # @param timeout is optional and specifies a time window to wait
    # @param repeats is optional and specifies the number of times the callback will be run
    #
    # @example
    #   p9_11 = GPIOPin.new(:P9_11, :IN)
    #   p9_11.run_on_edge(lambda { |pin,edge,count| puts "[#{count}] #{pin} -- #{edge}" }, :P9_11, :RISING)    def run_on_edge(callback, edge, timeout=nil, repeats=nil)
    def run_on_edge(callback, edge, timeout=nil, repeats=nil)
      GPIO::run_on_edge(callback, @pin, edge, timeout, repeats)
    end

    # Runs a callback one time on an edge trigger event.
    # this is a convenience method for run_on_edge
    # @see #run_on_edge
    def run_once_on_edge(callback, edge, timeout=nil)
      GPIO::run_once_on_edge(callback, @pin, edge, timeout)
    end

    # Stops any threads waiting for data on this pin
    #
    def stop_edge_wait
      GPIO::stop_edge_wait(@pin)
    end

    # Wait for an edge trigger.
    # Returns the type that triggered the event, e.g. :RISING, :FALLING, :BOTH
    #
    # @return [Symbol] :RISING, :FALLING, or :BOTH
    #
    # @param edge should be a symbol representing the trigger type, e.g. :RISING, :FALLING, :BOTH
    # @param timeout is optional and specifies a time window to wait
    #
    # @example
    #   p9_11 = GPIOPin.new(:P9_11, :IN)
    #   p9_11.wait_for_edge(:RISING, 30) => :RISING
    def wait_for_edge(edge, timeout=nil)
      GPIO::wait_for_edge(@pin, edge, timeout)
    end

    # Returns last known state from +pin+, reads state if unknown
    # @return [Symbol] :HIGH or :LOW
    def get_gpio_state
      GPIO::get_gpio_state(@pin)
    end

    # Returns mode from pin, reads mode if unknown
    # @return [Symbol] :IN or :OUT
    def get_gpio_mode
      GPIO::get_gpio_mode(@pin)
    end

    # Returns the GPIO edge trigger type
    # @return [Symbol] :NONE, :RISING, :FALLING, or :BOTH
    def get_gpio_edge
      GPIO::get_gpio_edge(@pin)
    end


    # Set GPIO mode on an initialized pin
    #
    # @param mode should specify the mode of the pin, either :IN or :OUT
    #
    # @example
    #   p9_12.set_gpio_mode(:OUT)
    #   p9_11.set_gpio_mode(:IN)
    def set_gpio_mode(mode)
      GPIO::set_gpio_mode(@pin, mode)
    end

    # Set GPIO edge trigger type
    #
    # @param edge should be a symbol representing the trigger type, e.g. :RISING, :FALLING, :BOTH
    # @param force is optional, if set will set the mode even if already set
    #
    # @example
    #   p9_11.set_gpio_edge(:RISING)
    def set_gpio_edge(edge, force=nil)
      GPIO::set_gpio_edge(@pin, edge, force)
    end

    # Disable GPIO pin
    def disable_gpio_pin
      GPIO::disable_gpio_pin(@pin)
    end

  end
end
