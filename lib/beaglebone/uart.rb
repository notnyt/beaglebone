# == uart.rb
# This file contains UART methods
module Beaglebone #:nodoc:
  # == UART
  # Procedural methods for UART control
  # == Summary
  # #setup is called to initialize a UART device
  module UART
    # Valid UART speeds
    SPEEDS = [ 110, 300, 600, 1200, 2400, 4800, 9600, 14400, 19200, 28800, 38400, 56000, 57600, 115200 ]

    @uartstatus = {}
    @uartmutex = Mutex.new

    class << self
      attr_accessor :uartstatus, :uartmutex


      # Initialize a UART device
      #
      # @param uart should be a symbol representing the UART device
      # @param speed should be an integer thats a valid speed. @see SPEEDS
      #
      # @example
      #   UART.setup(:UART1, 9600)
      def setup(uart, speed=9600)
        check_uart_valid(uart)
        check_speed_valid(speed)

        #make sure uart not already enabled
        return if get_uart_status(uart)

        uartinfo = UARTS[uart]

        #ensure dtb is loaded
        Beaglebone::device_tree_load("#{TREES[:UART][:pin]}#{uartinfo[:id]}")

        #open the uart device
        uart_fd = File.open(uartinfo[:dev], 'r+')

        if uartinfo[:tx]
          Beaglebone::set_pin_status(uartinfo[:tx], :uart, uartinfo[:id])
          Beaglebone::set_pin_status(uartinfo[:tx], :type, :uart)
          Beaglebone::set_pin_status(uartinfo[:tx], :fd_uart, uart_fd)
        end

        if uartinfo[:rx]
          Beaglebone::set_pin_status(uartinfo[:rx], :uart, uartinfo[:id])
          Beaglebone::set_pin_status(uartinfo[:tx], :type, :uart)
          Beaglebone::set_pin_status(uartinfo[:rx], :fd_uart, uart_fd)
        end

        system("stty -F #{uartinfo[:dev]} raw")
        system("stty -F #{uartinfo[:dev]} #{speed}")

        set_uart_status(uart, :fd_uart, uart_fd)
      end

      # Set the speed of the UART
      #
      # @param speed should be an integer thats a valid speed. @see SPEEDS
      #
      # @example
      #   UART.set_speed(:UART1, 9600)
      def set_speed(uart, speed)
        check_uart_valid(uart)
        check_speed_valid(speed)

        uartinfo = UARTS[uart]
        system("stty -F #{uartinfo[:dev]} #{speed}")
      end

      # Write data to a UART device
      #
      # @param uart should be a symbol representing the UART device
      # @param data the data to write
      #
      # @return Integer the number of bytes written
      #
      # @example
      #   UART.write(:UART1, "1234") => 4
      def write(uart, data)
        check_uart_enabled(uart)

        pin_tx = UARTS[uart][:tx]

        Beaglebone::check_valid_pin(pin_tx, :uart)

        fd = Beaglebone::get_pin_status(pin_tx, :fd_uart)

        ret = fd.write(data)
        fd.flush

        ret
      end

      # Write a line data to a UART device.
      # This is a convenience method using #write
      # @see #write
      #
      # @param uart should be a symbol representing the UART device
      # @param data the data to write
      #
      # @return Integer the number of bytes written
      #
      # @example
      #   UART.writeln(:UART1, "1234") => 5
      def writeln(uart, data)
        write(uart, data + "\n")
      end

      # Read one character from a UART device
      #
      # @param uart should be a symbol representing the UART device
      #
      # @return String the character read from the UART device
      #
      # @example
      #   UART.readchars(:UART1) => "x"
      def readchar(uart)
        readchars(uart, 1)
      end

      # Read characters from a UART device
      #
      # @param uart should be a symbol representing the UART device
      # @param bytes number of bytes to read
      #
      # @return String the characters read from the UART device
      #
      # @example
      #   UART.readchars(:UART1, 2) => "xx"
      def readchars(uart, bytes)
        check_uart_enabled(uart)
        ensure_read_lock(uart)

        buffer = ''

        pin_rx = UARTS[uart][:rx]

        Beaglebone::check_valid_pin(pin_rx, :uart)

        fd = Beaglebone::get_pin_status(pin_rx, :fd_uart)

        set_uart_status(uart, :waiting, true)

        while bytes > 0 do
          buffer << fd.readchar
          bytes -= 1
        end
        set_uart_status(uart, :waiting, false)

        buffer
      end

      # Read a line from a UART device
      #
      # @param uart should be a symbol representing the UART device
      #
      # @return String the line read from the UART device
      #
      # @example
      #   UART.readline(:UART1) => "A line of text"
      def readline(uart)
        check_uart_enabled(uart)
        ensure_read_lock(uart)

        pin_rx = UARTS[uart][:rx]

        Beaglebone::check_valid_pin(pin_rx, :uart)

        fd = Beaglebone::get_pin_status(pin_rx, :fd_uart)

        set_uart_status(uart, :waiting, true)

        data = fd.readline.strip

        set_uart_status(uart, :waiting, false)

        data
      end

      # Read a character from a UART device and pass it to the specified block
      #
      # @param uart should be a symbol representing the UART device
      #
      # @example
      #   UART.each_char(:UART1) { |x| puts "read: #{x}" }
      def each_char(uart)
        loop do
          data = readchars(uart, 1)
          yield data
        end

      end

      # Read characters from a UART device and pass them to the specified block
      #
      # @param uart should be a symbol representing the UART device
      # @param chars should be the number of chars to read
      #
      # @example
      #   UART.each_chars(:UART1, 2) { |x| puts "read: #{x}" }
      def each_chars(uart, chars)
        loop do
          data = readchars(uart, chars)
          yield data
        end
      end


      # Read lines from a UART device and pass them to the specified block
      #
      # @param uart should be a symbol representing the UART device
      #
      # @example
      #   UART.each_line(:UART1) { |x| puts "read: #{x}" }
      def each_line(uart)
        loop do
          data = readline(uart)
          yield data
        end
      end

      # Runs a callback after receiving a line of data from a UART device
      # This creates a new thread that runs in the background
      #
      # @param callback A method to call when the data is received.  This method should take 3 arguments, the UART, the line read, and the counter
      # @param uart should be a symbol representing the UART device
      # @param repeats is optional and specifies the number of times the callback will be run
      #
      # @example
      #   callback = lambda { |uart, line, count| puts "[#{uart}:#{count}] #{line} "}
      #   UART.run_on_each_line(callback, :UART1)
      def run_on_each_line(callback, uart, repeats=nil)
        check_uart_enabled(uart)

        raise StandardError, "Already waiting for data on uart: #{uart}" if get_uart_status(uart, :waiting)
        raise StandardError, "Already waiting for data on uart: #{uart}" if get_uart_status(uart, :thread)

        thread = Thread.new(callback, uart, repeats) do |c, u, r|
          begin
            count = 0
            each_line(u) do |line|

              c.call(u, line, count) if c

              count += 1
              break if r && count >= r
            end
          rescue => ex
            puts ex
            puts ex.backtrace
          ensure
            delete_uart_status(u, :thread)
            set_uart_status(uart, :waiting, false)
          end
        end
        set_uart_status(uart, :thread, thread)
      end

      # Convenience method for run_on_each_line with repeats set to 1
      # @see #run_on_each_line
      def run_once_on_each_line(callback, uart)
        run_on_each_line(callback, uart, 1)
      end

      # Runs a callback after receiving data from a UART device
      # This creates a new thread that runs in the background
      #
      # @param callback A method to call when the data is received.  This method should take 3 arguments, the UART, the line read, and the counter
      # @param uart should be a symbol representing the UART device
      # @param chars should be the number of chars to read
      # @param repeats is optional and specifies the number of times the callback will be run
      #
      # @example
      #   callback = lambda { |uart, data, count| puts "[#{uart}:#{count}] #{data} "}
      #   UART.run_on_each_chars(callback, :UART1, 2)
      def run_on_each_chars(callback, uart, chars=1, repeats=nil)
        check_uart_enabled(uart)

        raise StandardError, "Already waiting for data on uart: #{uart}" if get_uart_status(uart, :waiting)
        raise StandardError, "Already waiting for data on uart: #{uart}" if get_uart_status(uart, :thread)

        thread = Thread.new(callback, uart, chars, repeats) do |c, u, ch, r|
          begin
            count = 0
            each_chars(u, ch) do |line|

              c.call(u, line, count) if c

              count += 1
              break if r && count >= r
            end
          rescue => ex
            puts ex
            puts ex.backtrace
          ensure
            delete_uart_status(u, :thread)
            set_uart_status(uart, :waiting, false)
          end
        end
        set_uart_status(uart, :thread, thread)
      end

      # Convenience method for run_on_each_chars with chars and repeats set to 1
      # @see #run_on_each_chars
      def run_once_on_each_char(callback, uart)
        run_once_on_each_chars(callback, uart, 1)
      end

      # Convenience method for run_on_each_chars with chars and repeats set to 1
      # @see #run_on_each_chars
      def run_once_on_each_chars(callback, uart, chars=1)
        run_on_each_chars(callback, uart, chars, 1)
      end

      # Convenience method for run_on_each_chars with chars set to 1
      # @see #run_on_each_chars
      def run_on_each_char(callback, uart, repeats=nil)
        run_on_each_chars(callback, uart, 1, repeats)
      end

      # Disable a UART device.
      #
      # @note device trees cannot be unloaded at this time without kernel panic.
      #
      # @param uart should be a symbol representing the UART device
      #
      # @example
      #   UART.disable(:UART1)
      def disable(uart)
        check_uart_valid(uart)
        check_uart_enabled(uart)

        stop_read_wait(uart)

        disable_uart_pin(UARTS[uart][:rx]) if UARTS[uart][:rx]
        disable_uart_pin(UARTS[uart][:tx]) if UARTS[uart][:tx]

        delete_uart_status(uart)
      end

      # Stops any threads waiting for data on the specified UART
      def stop_read_wait(uart)
        thread = get_uart_status(uart, :thread)

        thread.exit if thread
        thread.join if thread
      end

      # Disable all UART devices
      def cleanup
        #reset all UARTs we've used and unload the device tree
        uartstatus.clone.keys.each { |uart| disable(uart)}
      end

      private

      # return hash data for specified UART
      def get_uart_status(uart, key = nil)
        uartmutex.synchronize do
          if key
            uartstatus[uart] ? uartstatus[uart][key] : nil
          else
            uartstatus[uart]
          end
        end
      end

      # set hash data for specified UART
      def set_uart_status(uart, key, value)
        uartmutex.synchronize do
          uartstatus[uart]    ||= {}
          uartstatus[uart][key] = value
        end
      end

      # remove hash data for specified UART
      def delete_uart_status(uart, key = nil)
        uartmutex.synchronize do
          if key.nil?
            uartstatus.delete(uart)
          else
            uartstatus[uart].delete(key) if uartstatus[uart]
          end
        end
      end

      # ensure UART is valid
      def check_uart_valid(uart)
        raise ArgumentError, "Invalid UART Specified #{uart.to_s}" unless UARTS[uart]
        uartinfo = UARTS[uart.to_sym.upcase]

        unless uartinfo[:tx] && [nil,:uart].include?(Beaglebone::get_pin_status(uartinfo[:tx], :type))
          raise StandardError, "TX Pin for #{uart.to_s} in use"
        end

        unless uartinfo[:rx] && [nil,:uart].include?(Beaglebone::get_pin_status(uartinfo[:rx], :type))
          raise StandardError, "RX Pin for #{uart.to_s} in use"
        end

      end

      # ensure UART is enabled
      def check_uart_enabled(uart)
        raise ArgumentError, "UART not enabled #{uart.to_s}" unless get_uart_status(uart)
      end

      # ensure we have a read lock for the UART
      def ensure_read_lock(uart)
        #ensure we're the only ones reading
        if get_uart_status(uart, :thread) && get_uart_status(uart, :thread) != Thread.current
          raise StandardError, "Already waiting for data on uart: #{uart}"
        end

        if get_uart_status(uart, :waiting) && get_uart_status(uart, :thread) != Thread.current
          raise StandardError, "Already waiting for data on uart: #{uart}"
        end
      end

      # check to make sure the specified speed is valid
      def check_speed_valid(speed)
        raise ArgumentError, "Invalid speed specified: #{speed}" unless SPEEDS.include?(speed)
      end

      # disable a uart pin
      def disable_uart_pin(pin)
        Beaglebone::check_valid_pin(pin, :uart)

        id = Beaglebone::get_pin_status(pin, :uart)

        Beaglebone::delete_pin_status(pin)

        #removing uart tree causes a crash... can't really disable.
        return if true

        Beaglebone::device_tree_unload("#{TREES[:UART][:pin]}#{id}")

      end

    end
  end

  # Object Oriented UART Implementation.
  # This treats the UART device as an object.
  class UARTDevice
    # Initialize a UART device.  Returns a UARTDevice object
    #
    # @param uart should be a symbol representing the UART device
    # @param speed should be an integer thats a valid speed. @see SPEEDS
    #
    # @example
    #   uart1 = UARTDevice.new(:UART1, 9600)
    def initialize(uart, speed=9600)
      @uart = uart
      UART::setup(@uart, speed)
    end

    # Set the speed of the UART
    #
    # @param speed should be an integer thats a valid speed. @see SPEEDS
    #
    # @example
    #   uart1.set_speed(9600)
    def set_speed(speed)
      UART::set_speed(@uart, speed)
    end

    # Write data to a UART device
    #
    # @param data the data to write
    #
    # @return Integer the number of bytes written
    #
    # @example
    #   uart1.write("1234") => 4
    def write(data)
      UART::write(@uart, data)
    end

    # Write a line data to a UART device.
    # This is a convenience method using #write
    # @see #write
    #
    # @param data the data to write
    #
    # @return Integer the number of bytes written
    #
    # @example
    #   uart1.writeln("1234") => 5
    def writeln(data)
      UART::writeln(@uart, data)
    end

    # Read one character from a UART device
    #
    # @return String the character read from the UART device
    #
    # @example
    #   uart1.readchars => "x"
    def readchar
      UART::readchar(@uart)
    end

    # Read characters from a UART device
    #
    # @param bytes number of bytes to read
    #
    # @return String the characters read from the UART device
    #
    # @example
    #   uart1.readchars(2) => "xx"
    def readchars(bytes)
      UART::readchars(@uart, bytes)
    end

    # Read a line from a UART device
    #
    # @return String the line read from the UART device
    #
    # @example
    #   uart1.readline => "A line of text"
    def readline
      UART::readline(@uart)
    end

    # Read a character from a UART device and pass it to the specified block
    #
    # @example
    #   uart1.each_char { |x| puts "read: #{x}" }
    def each_char(&block)
      UART::each_char(@uart, &block)
    end

    # Read characters from a UART device and pass them to the specified block
    #
    # @param chars should be the number of chars to read
    #
    # @example
    #   uart1.each_chars(2) { |x| puts "read: #{x}" }
    def each_chars(chars, &block)
      UART::each_chars(@uart, chars, &block)
    end

    # Read lines from a UART device and pass them to the specified block
    #
    # @example
    #   uart1.each_line { |x| puts "read: #{x}" }
    def each_line(&block)
      UART::each_line(@uart, &block)
    end

    # Runs a callback after receiving a line of data from a UART device
    # This creates a new thread that runs in the background
    #
    # @param callback A method to call when the data is received.  This method should take 3 arguments, the UART, the line read, and the counter
    # @param repeats is optional and specifies the number of times the callback will be run
    #
    # @example
    #   callback = lambda { |uart, line, count| puts "[#{uart}:#{count}] #{line} "}
    #   uart1.run_on_each_line(callback)
    def run_on_each_line(callback, repeats=nil)
      UART::run_on_each_line(callback, @uart, repeats)
    end

    # Convenience method for run_on_each_line with repeats set to 1
    # @see #run_on_each_line
    def run_once_on_each_line(callback)
      UART::run_once_on_each_line(callback, @uart)
    end

    # Runs a callback after receiving data from a UART device
    # This creates a new thread that runs in the background
    #
    # @param callback A method to call when the data is received.  This method should take 3 arguments, the UART, the line read, and the counter
    # @param chars should be the number of chars to read
    # @param repeats is optional and specifies the number of times the callback will be run
    #
    # @example
    #   callback = lambda { |uart, data, count| puts "[#{uart}:#{count}] #{data} "}
    #   uart1.run_on_each_chars(callback, 2)
    def run_on_each_chars(callback, chars=1, repeats=nil)
      UART::run_on_each_chars(callback, @uart, chars, repeats)
    end

    # Convenience method for run_on_each_chars with chars and repeats set to 1
    # @see #run_on_each_chars
    def run_once_on_each_char(callback)
      UART::run_once_on_each_char(callback, @uart)
    end

    # Convenience method for run_on_each_chars with chars and repeats set to 1
    # @see #run_on_each_chars
    def run_once_on_each_chars(callback, chars=1)
      UART::run_once_on_each_chars(callback, @uart, chars)
    end

    # Convenience method for run_on_each_chars with chars set to 1
    # @see #run_on_each_chars
    def run_on_each_char(callback, repeats=nil)
      UART::run_on_each_char(callback, @uart, repeats)
    end

    # Stops any threads waiting for data on the specified UART
    def stop_read_wait
      UART::stop_read_wait(@uart)
    end

    # Disable a UART device.
    #
    # @note device trees cannot be unloaded at this time without kernel panic.
    def disable
      UART::disable(@uart)
    end

  end
end
