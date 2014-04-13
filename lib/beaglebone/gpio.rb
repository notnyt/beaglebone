module GPIO
  class << self
    MODES = [ :IN, :OUT ]
    STATES = { :HIGH => 1, :LOW => 0 }
    EDGES = [ :NONE, :RISING, :FALLING, :BOTH ]


    #configure the gpio pin mode
    def pin_mode(pin, mode)


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

      #export pin unless its an on board LED, if it isn't already exported
      if pininfo[:led]
        raise StandardError, "LEDs only support OUT mode: #{pin.to_s}" unless mode == :OUT
        File.open("#{gpio_directory(pin)}/trigger", 'w') { |f| f.write('gpio') }
      else
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

    #set the gpio value
    def digital_write(pin, state)
      check_valid_state(state)
      check_gpio_enabled(pin)

      raise StandardError, "PIN not in GPIO OUT mode: #{pin}" unless get_gpio_mode(pin) == :OUT

      fd = get_value_fd(pin)
      fd.write STATES[state.to_sym.upcase].to_s
      fd.flush
      Beaglebone::set_pin_status(pin, :state, state)
    end

    #stop background edge trigger
    def stop_edge_wait(pin)
      thread = Beaglebone::get_pin_status(pin, :thread)

      thread.exit if thread
      thread.join if thread
    end

    #run block on an edge trigger
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

    def run_once_on_edge(callback, pin, edge, timeout = nil)
      run_on_edge(callback, pin, edge, timeout, 1)
    end

    #set edge trigger to none
    def cleanup_edge_trigger(pin)
      if Beaglebone::get_pin_status(pin, :thread) == Thread.current
        set_gpio_edge(pin, :NONE)
        Beaglebone::delete_pin_status(pin, :thread)
      end
    end

    #wait for an edge trigger, dont clear trigger if disable is false
    def wait_for_edge(pin, edge, timeout = nil, disable=true)
      check_valid_edge(edge)
      raise ArgumentError, "Cannot wait for edge trigger NONE: #{pin}" if edge.to_sym.upcase == :NONE

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

    #read the gpio value
    def digital_read(pin)
      check_gpio_enabled(pin)

      raise StandardError, "PIN not in GPIO IN mode: #{pin}" unless get_gpio_mode(pin) == :IN

      fd = get_value_fd(pin)
      fd.rewind
      value = fd.read.to_s.strip
      state = STATES.key(value.to_i)

      Beaglebone::set_pin_status(pin, :state, state)
    end

    #reset all GPIO we've used to IN and unexport them
    def cleanup
      get_gpio_pins.each { |x| disable_gpio_pin(x) }
    end

    def valid?(pin)
      #check to see if pin exists
      pin = pin.to_sym.upcase

      return false unless PINS[pin]
      return false unless PINS[pin][:gpio]

      true
    end

    def enabled?(pin)

      return true if Beaglebone::get_pin_status(pin, :type) == :gpio

      return false unless valid?(pin)
      if Dir.exists?(gpio_directory(pin))

        Beaglebone::set_pin_status(pin, :type, :gpio)
        return true
      end

      false
    end

    #send data to a shift register
    def shift_out(latch_pin, clock_pin, data_pin, data, lsb=nil)
      raise ArgumentError, "data must be > 0 (#{date}" if data < 0
      digital_write(latch_pin, :LOW)

      binary = data.to_s(2)
      pad = 8 - (binary.size % 8 )
      binary = (' ' * pad) + binary

      binary.reverse! if lsb

      binary.each_char do |bit|
        digital_write(clock_pin, :LOW)
        digital_write(data_pin, bit == '0' ? :LOW : :HIGH)
        digital_write(clock_pin, :HIGH)
      end
      digital_write(latch_pin, :HIGH)
    end

    def get_gpio_state(pin)
      check_gpio_enabled(pin)

      state = Beaglebone::get_pin_status(pin, :state)
      return state if state

      digital_read(pin)
    end

    def get_gpio_mode(pin)
      check_gpio_enabled(pin)

      mode = Beaglebone::get_pin_status(pin, :mode)
      return mode if mode

      read_gpio_direction(pin)
    end

    def set_gpio_mode(pin, mode)
      Beaglebone::check_valid_pin(pin, :gpio)
      check_valid_mode(mode)
      check_gpio_enabled(pin)

      File.open("#{gpio_directory(pin)}/direction", 'w') { |f| f.write mode.to_s.downcase }
      Beaglebone::set_pin_status(pin, :mode, mode)
    end

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

    def read_gpio_edge(pin)
      check_gpio_enabled(pin)
      File.open("#{gpio_directory(pin)}/edge", 'r').read.to_s.strip
    end

    def get_gpio_edge(pin)
      check_gpio_enabled(pin)

      edge = Beaglebone::get_pin_status(pin, :trigger)
      return edge if edge

      read_gpio_edge(pin)
    end

    def check_valid_edge(edge)
      raise ArgumentError, "No such edge: #{edge.to_s}" unless EDGES.include?(edge)
    end

    def get_gpio_pins
      Beaglebone.pinstatus.clone.select { |x,y| x if y[:type] == :gpio && !PINS[x][:led] }.keys
    end

    def disable_gpio_pin(pin)

      Beaglebone::check_valid_pin(pin, :gpio)

      pininfo = PINS[pin]

      close_value_fd(pin)

      #close any running threads
      stop_edge_wait(pin)

      #write to unexport to disable gpio
      File.open('/sys/class/gpio/unexport', 'w') { |f| f.write(pininfo[:gpio]) }

      #remove status from hash so following enabled? call checks actual system
      Beaglebone::delete_pin_status(pin)

      #check to see if pin is GPIO enabled in /sys/class/gpio/
      raise StandardError, "GPIO was unable to uninitalize pin: #{pin.to_s}" if enabled?(pin)

    end

    private


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

    def check_valid_state(state)
      #check to see if mode is valid
      state = state.to_sym.upcase
      raise ArgumentError, "No such state: #{state.to_s}" unless STATES.include?(state)
    end

    def check_valid_mode(mode)
      #check to see if mode is valid
      mode = mode.to_sym.upcase
      raise ArgumentError, "No such mode: #{mode.to_s}" unless MODES.include?(mode)
    end

    def check_gpio_enabled(pin)
      Beaglebone::check_valid_pin(pin, :gpio)
      raise StandardError, "PIN not GPIO enabled: #{pin}" unless enabled?(pin)
    end

  end

  #oo interface
  class GPIOPin
    def initialize(pin, mode)
      @pin = pin

      GPIO::pin_mode(@pin, mode)
    end

    def digital_write(state)
      GPIO::digital_write(@pin, state)
    end

    def digital_read
      GPIO::digital_read(@pin)
    end

    def wait_for_edge(edge, timeout=nil)
      GPIO::wait_for_edge(@pin, edge, timeout)
    end

    def stop_edge_wait
      GPIO::stop_edge_wait(@pin)
    end

    def run_on_edge(callback, edge, timeout=nil, repeats=nil)
      GPIO::run_on_edge(callback, @pin, edge, timeout, repeats)
    end

    def run_once_on_edge(callback, edge, timeout=nil)
      GPIO::run_once_on_edge(callback, @pin, edge, timeout)
    end

    def get_gpio_state
      GPIO::get_gpio_state(@pin)
    end

    def get_gpio_mode
      GPIO::get_gpio_mode(@pin)
    end

    def set_gpio_mode(mode)
      GPIO::set_gpio_mode(@pin, mode)
    end

    def set_gpio_edge(edge, force=nil)
      GPIO::set_gpio_edge(@pin, edge, force)
    end

    def get_gpio_edge
      GPIO::get_gpio_edge(@pin)
    end

    def disable_gpio_pin
      GPIO::disable_gpio_pin(@pin)
    end

  end
end