module Beaglebone

  module SPI
    #some ioctl defines
    IOC_NONE  = 0
    IOC_WRITE = 1
    IOC_READ  = 2

    IOC_NRBITS = 8
    IOC_TYPEBITS =  8
    IOC_SIZEBITS = 14
    IOC_DIRBITS = 2

    IOC_NRSHIFT   = 0
    IOC_TYPESHIFT = IOC_NRSHIFT+IOC_NRBITS
    IOC_SIZESHIFT = IOC_TYPESHIFT+IOC_TYPEBITS
    IOC_DIRSHIFT  = IOC_SIZESHIFT+IOC_SIZEBITS

    #spi defines
    SPI_CPHA = 0x01
    SPI_CPOL = 0x02

    SPI_MODE_0 = (0|0)
    SPI_MODE_1 = (0|SPI_CPHA)
    SPI_MODE_2 = (SPI_CPOL|0)
    SPI_MODE_3 = (SPI_CPOL|SPI_CPHA)

    SPI_CS_HIGH   = 0x04
    SPI_LSB_FIRST = 0x08
    SPI_3WIRE     = 0x10
    SPI_LOOP      = 0x20
    SPI_NO_CS     = 0x40
    SPI_READY     = 0x80

    SPI_IOC_MAGIC = 'k'.ord

    SPI_IOC_RD_MODE = 2147576577 #ior(SPI_IOC_MAGIC, 1, 1)
    SPI_IOC_WR_MODE = 1073834753 #iow(SPI_IOC_MAGIC, 1, 1)

    SPI_IOC_RD_LSB_FIRST = 2147576578 #ior(SPI_IOC_MAGIC, 2, 1)
    SPI_IOC_WR_LSB_FIRST = 1073834754 #iow(SPI_IOC_MAGIC, 2, 1)

    SPI_IOC_RD_BITS_PER_WORD = 2147576579 #ior(SPI_IOC_MAGIC, 3, 1)
    SPI_IOC_WR_BITS_PER_WORD = 1073834755 #iow(SPI_IOC_MAGIC, 3, 1)

    SPI_IOC_RD_MAX_SPEED_HZ = 2147773188 #ior(SPI_IOC_MAGIC, 4, 4)
    SPI_IOC_WR_MAX_SPEED_HZ = 1074031364 #iow(SPI_IOC_MAGIC, 4, 4)

    SPI_IOC_MESSAGE_1 = 1075866368

    SPI_IOC_TRANSFER_STRUCT_SIZE = 32

    @spistatus = {}
    @spimutex = Mutex.new

    class << self

      attr_accessor :spistatus, :spimutex
      def xfer(spi, tx_data, readbytes=0, speed=nil, delay=nil, bpw=nil)
        check_spi_enabled(spi)

        speed = speed || get_spi_status(spi, :speed)
        delay = delay || 0
        bpw   = bpw || get_spi_status(spi, :bpw)

        if tx_data.size > readbytes
          readbytes = tx_data.size
        end

        rx_data = ' ' * readbytes

        lock_spi(spi) do
          spi_fd = get_spi_status(spi, :fd_spi)

          ### SPI IOC transfer structure
          # __u64       tx_buf;
          # __u64       rx_buf;
          #
          # __u32       len;
          # __u32       speed_hz;
          #
          # __u16       delay_usecs;
          # __u8        bits_per_word;
          # __u8        cs_change;
          # __u32       pad;
          ###

          msg = [ tx_data, 0,
                  rx_data, 0,
                  readbytes,
                  speed,
                  delay,
                  bpw,
                  0,
                  0].pack('pLpLLLSCCL')

          #ioctl call to begin data transfer
          spi_fd.ioctl(SPI_IOC_MESSAGE_1, msg)
          #speedup with defined int
          #spi_fd.ioctl(spi_ioc_message(1), msg)

        end
        rx_data
      end

      def file(spi)
        check_spi_enabled(spi)
        get_spi_status(spi, :fd_spi)
      end

      def set_speed(spi, speed)
        speed = speed.to_i
        raise ArgumentError, "Speed (#{speed.to_s}) must be a positive integer" unless speed > 0

        check_spi_enabled(spi)
        spi_fd = get_spi_status(spi, :fd_spi)

        spi_fd.ioctl(SPI_IOC_WR_MAX_SPEED_HZ, [speed].pack('L'))
        spi_fd.ioctl(SPI_IOC_RD_MAX_SPEED_HZ, [speed].pack('L'))
        set_spi_status(spi, :speed, speed)
      end

      def set_mode(spi, mode)
        check_spi_enabled(spi)
        raise ArgumentError, "Mode (#{mode.to_s}) is unknown" unless [SPI_MODE_0, SPI_MODE_1, SPI_MODE_2, SPI_MODE_3].include?(mode)
        spi_fd = get_spi_status(spi, :fd_spi)

        spi_fd.ioctl(SPI_IOC_WR_MODE, [mode].pack('C'))
        spi_fd.ioctl(SPI_IOC_RD_MODE, [mode].pack('C'))
      end

      def set_bpw(spi, bpw)
        bpw = bpw.to_i
        raise ArgumentError, "BPW (#{bpw.to_s}) must be a positive integer" unless bpw > 0

        check_spi_enabled(spi)
        spi_fd = get_spi_status(spi, :fd_spi)

        spi_fd.ioctl(SPI_IOC_WR_BITS_PER_WORD, [bpw].pack('C'))
        spi_fd.ioctl(SPI_IOC_RD_BITS_PER_WORD, [bpw].pack('C'))
        set_spi_status(spi, :bpw, bpw)
      end

      def setup(spi, mode=nil, speed=1000000, bpw=8)
        check_spi_valid(spi)

        #make sure spi not already enabled
        return if get_spi_status(spi)

        mode = mode || SPI_MODE_0

        spiinfo = SPIS[spi]

        #ensure dtb is loaded
        Beaglebone::device_tree_load("#{spiinfo[:devicetree]}") if spiinfo[:devicetree]

        #open the spi device.
        spi_fd = File.open("#{spiinfo[:dev]}#{SPIS[:counter]}.0", 'r+')

        set_spi_status(spi, :fd_spi, spi_fd)
        set_spi_status(spi, :mutex, Mutex.new)

        set_mode(spi, mode)
        set_bpw(spi, bpw)
        set_speed(spi, speed)

        SPIS[:counter] += 1

        spiinfo[:pins].each do |pin|
          Beaglebone::set_pin_status(pin, :spi, spiinfo[:id])
          Beaglebone::set_pin_status(pin, :type, :spi)
          Beaglebone::set_pin_status(pin, :fd_spi, spi_fd)
        end

      end

      def disable(spi)
        check_spi_valid(spi)
        check_spi_enabled(spi)

        SPIS[spi][:pins].each do |pin|
          disable_spi_pin(pin)
        end

        delete_spi_status(spi)

        #removing spi tree causes a crash... can't really disable.
        #Beaglebone::device_tree_unload("#{SPIS[spi][:devicetree]}") if SPIS[spi][:devicetree]

      end

      def cleanup
        #reset all spis we've used and unload the device tree
        spistatus.clone.keys.each { |spi| disable(spi)}
      end

      private

      def check_spi_valid(spi)
        raise ArgumentError, "Invalid spi Specified #{spi.to_s}" unless SPIS[spi] && SPIS[spi][:sclk]
        spiinfo = SPIS[spi.to_sym.upcase]

        unless spiinfo[:sclk] && [nil,:spi].include?(Beaglebone::get_pin_status(spiinfo[:sclk], :type))
          raise StandardError, "SCLK Pin for #{spi.to_s} in use"
        end

        unless spiinfo[:d0] && [nil,:spi].include?(Beaglebone::get_pin_status(spiinfo[:d0], :type))
          raise StandardError, "D0 Pin for #{spi.to_s} in use"
        end

        unless spiinfo[:d1] && [nil,:spi].include?(Beaglebone::get_pin_status(spiinfo[:d1], :type))
          raise StandardError, "D1 Pin for #{spi.to_s} in use"
        end

        unless spiinfo[:cs0] && [nil,:spi].include?(Beaglebone::get_pin_status(spiinfo[:cs0], :type))
          raise StandardError, "CS0 Pin for #{spi.to_s} in use"
        end
      end

      def lock_spi(spi)
        check_spi_enabled(spi)
        mutex = get_spi_status(spi, :mutex)

        mutex.synchronize do
          yield
        end
      end

      def check_spi_enabled(spi)
        raise ArgumentError, "spi not enabled #{spi.to_s}" unless get_spi_status(spi)
      end

      def disable_spi_pin(pin)
        Beaglebone::check_valid_pin(pin, :spi)

        Beaglebone::delete_pin_status(pin)
      end

      #ports of ioctl definitions
      def ioc(dir,type,nr,size)
        (((dir) << IOC_DIRSHIFT) |
            ((type) << IOC_TYPESHIFT) |
            ((nr) << IOC_NRSHIFT) |
            ((size) << IOC_SIZESHIFT))
      end

      def ior(type,nr,size)
        ioc(IOC_READ,(type),(nr),size)
      end

      def iow(type,nr,size)
        ioc(IOC_WRITE,(type),(nr),size)
      end

      def spi_msgsize(n)
        n*SPI_IOC_TRANSFER_STRUCT_SIZE < 1<<IOC_SIZEBITS ? n*SPI_IOC_TRANSFER_STRUCT_SIZE : 0
      end

      def spi_ioc_message(n)
        iow(SPI_IOC_MAGIC, 0, spi_msgsize(n))
      end

      def get_spi_status(spi, key = nil)
        spimutex.synchronize do
          if key
            spistatus[spi] ? spistatus[spi][key] : nil
          else
            spistatus[spi]
          end
        end
      end

      def set_spi_status(spi, key, value)
        spimutex.synchronize do
          spistatus[spi]    ||= {}
          spistatus[spi][key] = value
        end
      end

      def delete_spi_status(spi, key = nil)
        spimutex.synchronize do
          if key.nil?
            spistatus.delete(spi)
          else
            spistatus[spi].delete(key) if spistatus[spi]
          end
        end
      end

    end
  end

  #oo interface
  class SPIDevice
    def initialize(spi,  mode=nil, speed=1000000, bpw=8)
      @spi = spi
      SPI::setup(@spi, mode, speed, bpw)
    end

    def xfer(tx_data, readbytes=0, speed=nil, delay=nil, bpw=nil)
      SPI::xfer(@spi, tx_data, readbytes, speed, delay, bpw)
    end

    def disable
      SPI::disable(@spi)
    end

    def set_speed(speed)
      SPI::set_speed(@spi, speed)
    end

    def set_mode(mode)
      SPI::set_mode(@spi, mode)
    end

    def set_bpw(bpw)
      SPI::set_bpw(@spi, bpw)
    end

  end

end
