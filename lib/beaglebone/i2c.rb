module Beaglebone

  module I2C

    I2C_SLAVE = 0x0703

    @i2cstatus = {}
    @i2cmutex = Mutex.new

    class << self
      attr_accessor :i2cstatus, :i2cmutex

      def write(i2c, address, data)
        check_i2c_enabled(i2c)

        lock_i2c(i2c) do
          i2c_fd = get_i2c_status(i2c, :fd_i2c)

          #set the slave address to communicate with
          i2c_fd.ioctl(I2C_SLAVE, address)

          i2c_fd.syswrite(data)
        end

      end

      def read(i2c, address, bytes=1, register=nil)
        check_i2c_enabled(i2c)

        data = ''
        lock_i2c(i2c) do
          i2c_fd = get_i2c_status(i2c, :fd_i2c)

          #set the slave address to communicate with
          i2c_fd.ioctl(I2C_SLAVE, address)

          i2c_fd.syswrite(register) if register

          data = i2c_fd.sysread(bytes)
        end

        data
      end

      def file(i2c)
        check_i2c_enabled(i2c)
        get_i2c_status(i2c, :fd_i2c)
      end

      def setup(i2c)
        check_i2c_valid(i2c)

        #make sure i2c not already enabled
        return if get_i2c_status(i2c)

        i2cinfo = I2CS[i2c]

        #ensure dtb is loaded
        Beaglebone::device_tree_load("#{i2cinfo[:devicetree]}") if i2cinfo[:devicetree]

        #open the i2c device
        i2c_fd = File.open(i2cinfo[:dev], 'r+')

        Beaglebone::set_pin_status(i2cinfo[:scl], :i2c, i2cinfo[:id])
        Beaglebone::set_pin_status(i2cinfo[:scl], :type, :i2c)
        Beaglebone::set_pin_status(i2cinfo[:scl], :fd_i2c, i2c_fd)

        Beaglebone::set_pin_status(i2cinfo[:sda], :i2c, i2cinfo[:id])
        Beaglebone::set_pin_status(i2cinfo[:sda], :type, :i2c)
        Beaglebone::set_pin_status(i2cinfo[:sda], :fd_i2c, i2c_fd)

        set_i2c_status(i2c, :fd_i2c, i2c_fd)
        set_i2c_status(i2c, :mutex, Mutex.new)
      end

      def disable(i2c)
        check_i2c_valid(i2c)
        check_i2c_enabled(i2c)

        disable_i2c_pin(I2CS[i2c][:sda]) if I2CS[i2c][:sda]
        disable_i2c_pin(I2CS[i2c][:scl]) if I2CS[i2c][:scl]

        delete_i2c_status(i2c)

        #removing i2c tree causes a crash... can't really disable.
        #Beaglebone::device_tree_unload("#{I2CS[i2c][:devicetree]}") if I2CS[i2c][:devicetree]

      end

      def cleanup
        #reset all i2cs we've used and unload the device tree
        i2cstatus.clone.keys.each { |i2c| disable(i2c)}
      end

      private

      def disable_i2c_pin(pin)
        Beaglebone::check_valid_pin(pin, :i2c)

        Beaglebone::delete_pin_status(pin)
      end

      def check_i2c_valid(i2c)
        raise ArgumentError, "Invalid i2c Specified #{i2c.to_s}" unless I2CS[i2c] && I2CS[i2c][:sda]
        i2cinfo = I2CS[i2c.to_sym.upcase]

        unless i2cinfo[:scl] && [nil,:i2c].include?(Beaglebone::get_pin_status(i2cinfo[:scl], :type))
          raise StandardError, "SCL Pin for #{i2c.to_s} in use"
        end

        unless i2cinfo[:sda] && [nil,:i2c].include?(Beaglebone::get_pin_status(i2cinfo[:sda], :type))
          raise StandardError, "SDA Pin for #{i2c.to_s} in use"
        end

      end

      def check_i2c_enabled(i2c)
        raise ArgumentError, "i2c not enabled #{i2c.to_s}" unless get_i2c_status(i2c)
      end

      def lock_i2c(i2c)
        check_i2c_enabled(i2c)
        mutex = get_i2c_status(i2c, :mutex)

        mutex.synchronize do
          yield
        end
      end

      def get_i2c_status(i2c, key = nil)
        i2cmutex.synchronize do
          if key
            i2cstatus[i2c] ? i2cstatus[i2c][key] : nil
          else
            i2cstatus[i2c]
          end
        end
      end

      def set_i2c_status(i2c, key, value)
        i2cmutex.synchronize do
          i2cstatus[i2c]    ||= {}
          i2cstatus[i2c][key] = value
        end
      end

      def delete_i2c_status(i2c, key = nil)
        i2cmutex.synchronize do
          if key.nil?
            i2cstatus.delete(i2c)
          else
            i2cstatus[i2c].delete(key) if i2cstatus[i2c]
          end
        end
      end

    end
  end

  #oo interface
  class I2CDevice

    def initialize(i2c)
      @i2c = i2c
      I2C::setup(@i2c)
    end

    def read(address, bytes=1, register=nil)
      I2C::read(@i2c, address, bytes, register)
    end

    def write(address, data)
      I2C::write(@i2c, address, data)
    end

    def disable
      I2C::disable(@i2c)
    end

    def file
      I2C::file(@i2c)
    end

  end

end
