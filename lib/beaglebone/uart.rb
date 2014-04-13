module Beaglebone
  module UART
    SPEEDS = [ 110, 300, 600, 1200, 2400, 4800, 9600, 14400, 19200, 28800, 38400, 56000, 57600, 115200 ]
    @uartstatus = {}
    @uartmutex = Mutex.new

    class << self
      attr_accessor :uartstatus, :uartmutex

      def readchar(uart)
        readchars(uart, 1)
      end

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

      def each_char(uart)
        loop do
          data = readchars(uart, 1)
          yield data
        end

      end

      def each_chars(uart, chars)
        loop do
          data = readchars(uart, chars)
          yield data
        end
      end

      def each_line(uart)
        loop do
          data = readline(uart)
          yield data
        end
      end

      def writeln(uart, data)
        write(uart, data + "\n")
      end

      def write(uart, data)
        check_uart_enabled(uart)

        pin_tx = UARTS[uart][:tx]

        Beaglebone::check_valid_pin(pin_tx, :uart)

        fd = Beaglebone::get_pin_status(pin_tx, :fd_uart)

        ret = fd.write(data)
        fd.flush

        ret
      end

      def run_once_on_each_line(callback, uart)
        run_on_each_line(callback, uart, 1)
      end

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

      def run_once_on_each_char(callback, uart)
        run_once_on_each_chars(callback, uart, 1)
      end

      def run_once_on_each_chars(callback, uart, chars=1)
        run_on_each_chars(callback, uart, chars, 1)
      end

      def run_on_each_char(callback, uart, repeats=nil)
        run_on_each_chars(callback, uart, 1, repeats)
      end

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

      def set_speed(uart, speed)
        check_uart_valid(uart)
        check_speed_valid(speed)

        uartinfo = UARTS[uart]
        system("stty -F #{uartinfo[:dev]} #{speed}")
      end

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

      def disable(uart)
        check_uart_valid(uart)
        check_uart_enabled(uart)

        stop_read_wait(uart)

        disable_uart_pin(UARTS[uart][:rx]) if UARTS[uart][:rx]
        disable_uart_pin(UARTS[uart][:tx]) if UARTS[uart][:tx]

        delete_uart_status(uart)
      end

      #stop background read
      def stop_read_wait(uart)
        thread = get_uart_status(uart, :thread)

        thread.exit if thread
        thread.join if thread
      end

      def cleanup
        #reset all UARTs we've used and unload the device tree
        uartstatus.clone.keys.each { |uart| disable(uart)}
      end

      private

      def get_uart_status(uart, key = nil)
        uartmutex.synchronize do
          if key
            uartstatus[uart] ? uartstatus[uart][key] : nil
          else
            uartstatus[uart]
          end
        end
      end

      def set_uart_status(uart, key, value)
        uartmutex.synchronize do
          uartstatus[uart]    ||= {}
          uartstatus[uart][key] = value
        end
      end

      def delete_uart_status(uart, key = nil)
        uartmutex.synchronize do
          if key.nil?
            uartstatus.delete(uart)
          else
            uartstatus[uart].delete(key) if uartstatus[uart]
          end
        end
      end

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

      def check_uart_enabled(uart)
        raise ArgumentError, "UART not enabled #{uart.to_s}" unless get_uart_status(uart)
      end

      def ensure_read_lock(uart)
        #ensure we're the only ones reading
        if get_uart_status(uart, :thread) && get_uart_status(uart, :thread) != Thread.current
          raise StandardError, "Already waiting for data on uart: #{uart}"
        end

        if get_uart_status(uart, :waiting) && get_uart_status(uart, :thread) != Thread.current
          raise StandardError, "Already waiting for data on uart: #{uart}"
        end
      end

      def check_speed_valid(speed)
        raise ArgumentError, "Invalid speed specified: #{speed}" unless SPEEDS.include?(speed)
      end

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

  #oo interface
  class UARTDevice
    def initialize(uart, speed=9600)
      @uart = uart
      UART::setup(@uart, speed)
    end

    def set_speed(speed)
      UART::set_speed(@uart, speed)
    end

    def write(data)
      UART::write(@uart, data)
    end

    def writeln(data)
      UART::writeln(@uart, data)
    end

    def readchar
      UART::readchar(@uart)
    end

    def readchars(bytes)
      UART::readchars(@uart, bytes)
    end

    def readline
      UART::readline(@uart)
    end

    def each_char(&block)
      UART::each_char(@uart, &block)
    end

    def each_chars(chars, &block)
      UART::each_chars(@uart, chars, &block)
    end

    def each_line(&block)
      UART::each_line(@uart, &block)
    end

    def run_on_each_line(callback, repeats=nil)
      UART::run_on_each_line(callback, @uart, repeats)
    end

    def run_once_on_each_line(callback)
      UART::run_once_on_each_line(callback, @uart)
    end

    def run_on_each_char(callback, repeats=nil)
      UART::run_on_each_char(callback, @uart, repeats)
    end

    def run_once_on_each_char(callback)
      UART::run_once_on_each_char(callback, @uart)
    end

    def run_on_each_chars(callback, chars=1, repeats=nil)
      UART::run_on_each_chars(callback, @uart, chars, repeats)
    end

    def run_once_on_each_chars(callback, chars=1)
      UART::run_once_on_each_chars(callback, @uart, chars)
    end

    def stop_read_wait
      UART::stop_read_wait(@uart)
    end

    def disable
      UART::disable(@uart)
    end

  end
end
