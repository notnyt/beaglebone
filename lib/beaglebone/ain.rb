module Beaglebone
  module AIN
    class << self
      RANGE = (0..1799)

      def read(pin)
        Beaglebone::check_valid_pin(pin, :analog)

        Beaglebone::set_pin_status(pin, :type, :analog)

        ain_fd = Beaglebone::get_pin_status(pin, :fd_ain)

        unless ain_fd
          #ensure dtb is loaded
          Beaglebone::device_tree_load(TREES[:ADC][:global])

          #open the AIN analog input file
          pininfo = PINS[pin]

          ain_file = Dir.glob("/sys/devices/ocp.*/helper.*/AIN#{pininfo[:analog]}").first
          #ain_file = Dir.glob("/sys/bus/iio/devices/iio:device0/in_voltage#{pininfo[:analog]}_raw").first
          ain_fd = File.open(ain_file, 'r')

          Beaglebone::set_pin_status(pin, :fd_ain, ain_fd)
        end

        ain_fd.rewind
        ain_fd.read.strip.to_i
      end

      def get_analog_pins
        Beaglebone.pinstatus.clone.select { |x,y| x if y[:type] == :analog}.keys
      end

      def disable_analog_pin(pin)
        Beaglebone::check_valid_pin(pin, :analog)
        Beaglebone::delete_pin_status(pin)
      end

      def cleanup
        #reset all GPIO we've used to IN and unexport them
        get_analog_pins.each { |x| disable_analog_pin(x) }
      end

      def stop_wait(pin)
        thread = Beaglebone::get_pin_status(pin, :thread)

        thread.exit if thread
        thread.join if thread
      end

      #run block on an edge trigger
      def run_on_change(callback, pin, mv_change=10, interval=0.01, repeats=nil)

        raise StandardError, "Already waiting for change on pin: #{pin}" if Beaglebone::get_pin_status(pin, :waiting)
        raise StandardError, "Already waiting for thread on pin: #{pin}" if Beaglebone::get_pin_status(pin, :thread)

        thread = Thread.new(callback, pin, mv_change, interval, repeats) do |c, p, mvc, i, r|
          begin
            count = 0
            mvl = nil
            loop do

              mvl,mv,itr = wait_for_change(p, mvc, i, mvl)

              c.call(p, mvl, mv, count) if c

              #if there was no delay in the wait_for_change, delay now.
              sleep(interval) if itr == 0

              mvl = mv
              count += 1
              break if r && count >= r
            end
          rescue => ex
            puts ex
            puts ex.backtrace
          ensure
            Beaglebone::delete_pin_status(p, :thread)
            Beaglebone::delete_pin_status(p, :waiting)
          end
        end

        Beaglebone::set_pin_status(pin, :thread, thread)
      end

      def run_once_on_change(callback, pin, mv_change=10, interval=0.01)
        run_on_change(callback, pin, mv_change, interval, 1)
      end

      def run_on_threshold(callback, pin, mv_lower, mv_upper, mv_reset=10, interval=0.01, repeats=nil)

        raise StandardError, "Already waiting for change on pin: #{pin}" if Beaglebone::get_pin_status(pin, :waiting)
        raise StandardError, "Already waiting for thread on pin: #{pin}" if Beaglebone::get_pin_status(pin, :thread)

        thread = Thread.new(callback, pin, mv_lower, mv_upper, mv_reset, interval, repeats) do |c, p, mvl, mvu, mvr, i, r|
          begin
            count = 0
            mv_last = nil
            state_last = nil
            loop do

              mv_last,mv,state_last,state,itr = wait_for_threshold(p, mvl, mvu, mvr, i, mv_last, state_last)

              c.call(p, mv_last, mv, state_last, state, count) if c

              #if there was no delay in the wait_for_change, delay now.
              sleep(interval) if itr == 0

              mv_last = mv
              state_last = state
              count += 1
              break if r && r >= count
            end
          rescue => ex
            puts ex
            puts ex.backtrace
          ensure
            Beaglebone::delete_pin_status(p, :thread)
            Beaglebone::delete_pin_status(p, :waiting)
          end
        end

        Beaglebone::set_pin_status(pin, :thread, thread)
      end

      def run_once_on_threshold(callback, pin, mv_lower, mv_upper, mv_reset=10, interval=0.01)
        run_on_threshold(callback, pin, mv_lower, mv_upper, mv_reset, interval, 1)
      end

      #noinspection RubyScope
      def wait_for_threshold(pin, mv_lower, mv_upper, mv_reset=10, interval=0.01, mv_last=nil, state_last=nil)
        Beaglebone::check_valid_pin(pin, :analog)
        raise ArgumentError, "mv_upper needs to be between 0 and 1800: #{pin} (#{mv_upper})" unless (0..1800).include?(mv_upper)
        raise ArgumentError, "mv_lower needs to be between 0 and 1800: #{pin} (#{mv_lower})" unless (0..1800).include?(mv_lower)
        raise ArgumentError, "mv_lower needs to be <= mv_upper: #{pin} (#{mv_lower}:#{mv_upper})" unless mv_lower <= mv_upper
        raise ArgumentError, "mv_reset needs to be between 0 and 1800: #{pin} (#{mv_reset})" unless (0..1800).include?(mv_reset)

        #ensure we're the only ones waiting for this trigger
        if Beaglebone::get_pin_status(pin, :thread) && Beaglebone::get_pin_status(pin, :thread) != Thread.current
          raise StandardError, "Already waiting for change on pin: #{pin}"
        end

        if Beaglebone::get_pin_status(pin, :waiting) && Beaglebone::get_pin_status(pin, :thread) != Thread.current
          raise StandardError, "Already waiting for change on pin: #{pin}"
        end

        Beaglebone::set_pin_status(pin, :waiting, true)

        mv_last = read(pin) unless mv_last

        if mv_last >= mv_upper
          state_last = :HIGH
        elsif mv_last <= mv_lower
          state_last = :LOW
        else
          state_last = :MID
        end unless state_last

        state = :UNKNOWN
        count = 0
        loop do
          mv = read(pin)

          if state_last == :LOW
            #state remains low unless it crosses into high, or above mv_low + mv_reset
            if mv >= mv_upper && mv >= mv_lower + mv_reset
              state = :HIGH
            elsif mv >= mv_lower + mv_reset
              state = :MID
            else
              state = :LOW
            end
          elsif state_last == :HIGH
            #state remains high unless it crosses into low, or below mv_high - mv_reset
            if mv <= mv_lower && mv <= mv_upper - mv_reset
              state = :LOW
            elsif mv <= mv_upper - mv_reset
              state = :MID
            else
              state = :HIGH
            end
          elsif state_last == :MID
            #state changes from normal by crossing into upper or lower
            if mv >= mv_upper
              state = :HIGH
            elsif mv <= mv_lower
              state = :LOW
            else
              state = :MID
            end
          end

          #if we've detected a change of state
          if state != state_last
            Beaglebone::delete_pin_status(pin, :waiting)
            return [ mv_last, mv, state_last, state, count ]
          end

          sleep interval

          count += 1
        end

        Beaglebone::delete_pin_status(pin, :waiting)
        [ mv_last, -1, state_last, state_last, count ]

      end

      #loop with sleep of interval after each read, return after voltage changes more than mv_change mv
      def wait_for_change(pin, mv_change, interval, mv_last=nil)

        Beaglebone::check_valid_pin(pin, :analog)
        raise ArgumentError, "mv_change needs to be between 0 and 1800: #{pin} (#{mv_change})" unless (0..1800).include?(mv_change)

        #ensure we're the only ones waiting for this trigger
        if Beaglebone::get_pin_status(pin, :thread) && Beaglebone::get_pin_status(pin, :thread) != Thread.current
          raise StandardError, "Already waiting for change on pin: #{pin}"
        end

        if Beaglebone::get_pin_status(pin, :waiting) && Beaglebone::get_pin_status(pin, :thread) != Thread.current
          raise StandardError, "Already waiting for change on pin: #{pin}"
        end


        Beaglebone::set_pin_status(pin, :waiting, true)
        mv_last = read(pin) unless mv_last

        change_max = [mv_last - 0, 1799 - mv_last].max

        mv_change = change_max if mv_change > change_max

        count = 0
        loop do
          mv = read(pin)

          #if we've detected the change or hit the edge of the range
          if (mv - mv_last).abs >= mv_change

            Beaglebone::delete_pin_status(pin, :waiting)
            return [ mv_last, mv, count ]
          end

          sleep interval

          count += 1
        end

        Beaglebone::delete_pin_status(pin, :waiting)
        [ mv_last, -1, count ]
      end

    end
  end

  #oo interface
  class AINPin
    def initialize(pin)
      @pin = pin
    end

    def read
      AIN::read(@pin)
    end

    def disable_analog_pin
      AIN::disable_analog_pin(@pin)
    end

    def stop_wait
      AIN::stop_wait(@pin)
    end

    def run_on_change(callback, mv_change=10, interval=0.01, repeats=nil)
      AIN::run_on_change(callback, @pin, mv_change, interval, repeats)
    end

    def run_once_on_change(callback, mv_change=10, interval=0.01)
      AIN::run_once_on_change(callback, @pin, mv_change, interval)
    end

    def run_on_threshold(callback, mv_lower, mv_upper, mv_reset=10, interval=0.01, repeats=nil)
      AIN::run_on_threshold(callback, @pin, mv_lower, mv_upper, mv_reset, interval, repeats)
    end

    def run_once_on_threshold(callback, mv_lower, mv_upper, mv_reset=10, interval=0.01)
      AIN::run_once_on_threshold(callback, @pin, mv_lower, mv_upper, mv_reset, interval)
    end

    def wait_for_threshold(mv_lower, mv_upper, mv_reset=10, interval=0.01, mv_last=nil, state_last=nil)
      AIN::wait_for_threshold(@pin, mv_lower, mv_upper, mv_reset, interval, mv_last, state_last)
    end

    def wait_for_change(mv_change, interval, mv_last=nil)
      AIN::wait_for_change(@pin, mv_change, interval, mv_last)
    end

  end
end
