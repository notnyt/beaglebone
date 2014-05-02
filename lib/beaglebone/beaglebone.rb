# This is the main module for this gem.  You generally do not want to call these methods directly.
module Beaglebone
  # Hash of pins and their uses
  PINS = {
      :USR0  => { :gpio => 53, :led => 'usr0' },
      :USR1  => { :gpio => 54, :led => 'usr1' },
      :USR2  => { :gpio => 55, :led => 'usr2' },
      :USR3  => { :gpio => 56, :led => 'usr3' },

      :P8_1  => { :dgnd => 'Digital Ground' },
      :P8_2  => { :dgnd => 'Digital Ground' },

      :P8_3  => { :gpio => 38, :gpiofunc => 'gpio1_6', :muxoffset => '0x018', :mmc => 'mmc1_dat6' },
      :P8_4  => { :gpio => 39, :gpiofunc => 'gpio1_7', :muxoffset => '0x01c', :mmc => 'mmc1_dat7' },
      :P8_5  => { :gpio => 34, :gpiofunc => 'gpio1_2', :muxoffset => '0x008', :mmc => 'mmc1_dat2' },
      :P8_6  => { :gpio => 35, :gpiofunc => 'gpio1_3', :muxoffset => '0x00c', :mmc => 'mmc1_dat3' },

      :P8_7  => { :gpio => 66, :gpiofunc => 'gpio2_2', :muxoffset => '0x090', :timer => 'timer4' },
      :P8_8  => { :gpio => 67, :gpiofunc => 'gpio2_3', :muxoffset => '0x094', :timer => 'timer7' },
      :P8_9  => { :gpio => 69, :gpiofunc => 'gpio2_5', :muxoffset => '0x09c', :timer => 'timer5' },
      :P8_10 => { :gpio => 68, :gpiofunc => 'gpio2_4', :muxoffset => '0x098', :timer => 'timer6' },

      :P8_11 => { :gpio => 45, :gpiofunc => 'gpio1_13', :muxoffset => '0x034' },
      :P8_12 => { :gpio => 44, :gpiofunc => 'gpio1_12', :muxoffset => '0x030' },

      # You can emable PWM as listed below
      # P8_13 *OR* P8_19 (EHRPWM2B, EHRPWM2A),
      # P9_14 *OR* P9_16 (EHRPWM1A, EHRPWM1B),
      # P9_21 *OR* P9_22 (EHRPWM0B, EHRPWM0A).
      # there are also ecap pwms on pins P9_28 and P9_42

      :P8_13 => { :gpio => 23, :gpiofunc => 'gpio0_23', :muxoffset => '0x024', :pwm => 'pwm_2b', :pwm_id => 2, :pwm_mux => 4 },

      :P8_14 => { :gpio => 26, :gpiofunc => 'gpio0_26', :muxoffset => '0x028' },
      :P8_15 => { :gpio => 47, :gpiofunc => 'gpio1_15', :muxoffset => '0x03c' },
      :P8_16 => { :gpio => 46, :gpiofunc => 'gpio1_14', :muxoffset => '0x038' },
      :P8_17 => { :gpio => 27, :gpiofunc => 'gpio0_27', :muxoffset => '0x02c' },
      :P8_18 => { :gpio => 65, :gpiofunc => 'gpio2_1',  :muxoffset => '0x08c' },

      :P8_19 => { :gpio => 22, :gpiofunc => 'gpio0_22', :muxoffset => '0x020', :pwm => 'pwm_2a', :pwm_id => 2, :pwm_mux => 4 },

      # You can only use the mmc pins if booting from SD and disabling mmc
      # mmc reset behavior is unclear
      # Best option is to not use the MMC1_CLK and MMC1_CMD signals at all and tie them low.
      :P8_20 => { :gpio => 63, :gpiofunc => 'gpio1_31', :muxoffset => '0x084', :mmc => 'mmc1_cmd' },
      :P8_21 => { :gpio => 62, :gpiofunc => 'gpio1_30', :muxoffset => '0x080', :mmc => 'mmc1_clk' },
      :P8_22 => { :gpio => 37, :gpiofunc => 'gpio1_5',  :muxoffset => '0x014', :mmc => 'mmc1_dat5' },
      :P8_23 => { :gpio => 36, :gpiofunc => 'gpio1_4',  :muxoffset => '0x010', :mmc => 'mmc1_dat4' },
      :P8_24 => { :gpio => 33, :gpiofunc => 'gpio1_1',  :muxoffset => '0x004', :mmc => 'mmc1_dat1' },
      :P8_25 => { :gpio => 32, :gpiofunc => 'gpio1_0',  :muxoffset => '0x000', :mmc => 'mmc1_dat0' },

      :P8_26 => { :gpio => 61, :gpiofunc => 'gpio1_29', :muxoffset => '0x07c' },
      :P8_27 => { :gpio => 86, :gpiofunc => 'gpio2_22', :muxoffset => '0x0e0', :lcd => 'lcd_vsync' },
      :P8_28 => { :gpio => 88, :gpiofunc => 'gpio2_24', :muxoffset => '0x0e8', :lcd => 'lcd_pclk' },
      :P8_29 => { :gpio => 87, :gpiofunc => 'gpio2_23', :muxoffset => '0x0e4', :lcd => 'lcd_hsync' },
      :P8_30 => { :gpio => 89, :gpiofunc => 'gpio2_25', :muxoffset => '0x0ec', :lcd => 'lcd_ac_bias' },
      :P8_31 => { :gpio => 10, :gpiofunc => 'gpio0_10', :muxoffset => '0x0d8', :lcd => 'lcd_data14', :uart => 'uart5_ctsn', :uart_id => 5 },
      :P8_32 => { :gpio => 11, :gpiofunc => 'gpio0_11', :muxoffset => '0x0dc', :lcd => 'lcd_data15', :uart => 'uart5_rtsn', :uart_id => 5 },
      :P8_33 => { :gpio => 9,  :gpiofunc => 'gpio0_9',  :muxoffset => '0x0d4', :lcd => 'lcd_data13', :uart => 'uart4_rtsn', :uart_id => 4 },
      :P8_34 => { :gpio => 81, :gpiofunc => 'gpio2_17', :muxoffset => '0x0cc', :lcd => 'lcd_data11', :pwm => 'pwm_1b', :pwm_id => 1, :pwm_mux => 2, :uart => 'uart3_rtsn', :uart_id => 3 },
      :P8_35 => { :gpio => 8,  :gpiofunc => 'gpio0_8',  :muxoffset => '0x0d0', :lcd => 'lcd_data12', :uart => 'uart4_ctsn' },
      :P8_36 => { :gpio => 80, :gpiofunc => 'gpio2_16', :muxoffset => '0x0c8', :lcd => 'lcd_data10', :pwm => 'pwm_1a', :pwm_id => 1, :pwm_mux => 2, :uart => 'uart3_ctsn', :uart_id => 3 },
      :P8_37 => { :gpio => 78, :gpiofunc => 'gpio2_14', :muxoffset => '0x0c0', :lcd => 'lcd_data8', :uart => 'uart5_txd', :uart_id => 5 },
      :P8_38 => { :gpio => 79, :gpiofunc => 'gpio2_15', :muxoffset => '0x0c4', :lcd => 'lcd_data9', :uart => 'uart5_rxd', :uart_id => 5 },
      :P8_39 => { :gpio => 76, :gpiofunc => 'gpio2_12', :muxoffset => '0x0b8', :lcd => 'lcd_data6' },
      :P8_40 => { :gpio => 77, :gpiofunc => 'gpio2_13', :muxoffset => '0x0bc', :lcd => 'lcd_data7' },
      :P8_41 => { :gpio => 74, :gpiofunc => 'gpio2_10', :muxoffset => '0x0b0', :lcd => 'lcd_data4' },
      :P8_42 => { :gpio => 75, :gpiofunc => 'gpio2_11', :muxoffset => '0x0b4', :lcd => 'lcd_data5' },
      :P8_43 => { :gpio => 72, :gpiofunc => 'gpio2_8',  :muxoffset => '0x0a8', :lcd => 'lcd_data2' },
      :P8_44 => { :gpio => 73, :gpiofunc => 'gpio2_9',  :muxoffset => '0x0ac', :lcd => 'lcd_data3' },
      :P8_45 => { :gpio => 70, :gpiofunc => 'gpio2_6',  :muxoffset => '0x0a0', :lcd => 'lcd_data0', :pwm => 'pwm_2a', :pwm_id => 2, :pwm_mux => 3 },
      :P8_46 => { :gpio => 71, :gpiofunc => 'gpio2_7',  :muxoffset => '0x0a4', :lcd => 'lcd_data1', :pwm => 'pwm_2b', :pwm_id => 2, :pwm_mux => 3 },

      :P9_1  => { :dgnd => 'ground' },
      :P9_2  => { :dgnd => 'ground' },
      :P9_3  => { :vdd_3v3 => '3.3 volts' },
      :P9_4  => { :vdd_3v3 => '3.3 volts' },
      :P9_5  => { :vdd_5v => '5 volts' },
      :P9_6  => { :vdd_5v => '5 volts' },
      :P9_7  => { :sys_5v => '5 volts' },
      :P9_8  => { :sys_5v => '5 volts' },
      :P9_9  => { :pwr_but => 'power button' },
      :P9_10 => { :sys_resetn => 'reset button' },

      :P9_11 => { :gpio => 30, :gpiofunc => 'gpio0_30', :muxoffset => '0x070', :uart => 'uart4_rxd', :uart_id => 4 },
      :P9_12 => { :gpio => 60, :gpiofunc => 'gpio1_28', :muxoffset => '0x078' },
      :P9_13 => { :gpio => 31, :gpiofunc => 'gpio0_31', :muxoffset => '0x074', :uart => 'uart4_txd', :uart_id => 4 },
      :P9_14 => { :gpio => 50, :gpiofunc => 'gpio1_18', :muxoffset => '0x048', :pwm => 'pwm_1a', :pwm_id => 1, :pwm_mux => 6 },
      :P9_15 => { :gpio => 48, :gpiofunc => 'gpio1_16', :muxoffset => '0x040' },
      :P9_16 => { :gpio => 51, :gpiofunc => 'gpio1_19', :muxoffset => '0x04c', :pwm => 'pwm_1b', :pwm_id => 1, :pwm_mux => 6 },
      # these gpio values for P9_17 and P9_18 are swapped due to http://bugs.elinux.org/issues/81
      :P9_17 => { :gpio => 5, :gpiofunc => 'gpio0_5', :muxoffset => '0x15c', :i2c => 'i2c1_scl', :i2c_id => 1, :spi => 'spi0_cs0', :spi_id => 0 },
      :P9_18 => { :gpio => 4, :gpiofunc => 'gpio0_4', :muxoffset => '0x158', :i2c => 'i2c1_sda', :i2c_id => 1, :spi => 'spi0_d1', :spi_id => 0 },
      :P9_19 => { :i2c => 'i2c2_scl', :i2c_id => 2, :uart => 'uart1_rtsn', :uart_id => 1, :spi => 'spi1_cs1', :spi_id => 1 },
      :P9_20 => { :i2c => 'i2c2_sda', :i2c_id => 2, :uart => 'uart1_ctsn', :uart_id => 1, :spi => 'spi1_cs0', :spi_id => 1 },
      :P9_21 => { :gpio => 3, :gpiofunc => 'gpio0_3', :muxoffset => '0x154', :pwm => 'pwm_0b', :pwm_id => 0, :pwm_mux => 3, :i2c => 'i2c2_scl', :i2c_id => 2, :uart => 'uart2_txd', :uart_id => 2, :spi => 'spi0_d0', :spi_id => 0 },
      :P9_22 => { :gpio => 2, :gpiofunc => 'gpio0_2', :muxoffset => '0x150', :pwm => 'pwm_0a', :pwm_id => 0, :pwm_mux => 3, :i2c => 'i2c2_sda', :i2c_id => 2, :uart => 'uart2_rxd', :uart_id => 2, :spi => 'spi0_sclk', :spi_id => 0 },
      :P9_23 => { :gpio => 49, :gpiofunc => 'gpio1_17', :muxoffset => '0x044' },
      :P9_24 => { :gpio => 15, :gpiofunc => 'gpio0_15', :muxoffset => '0x184', :i2c => 'i2c1_scl', :i2c_id => 1, :uart => 'uart1_txd', :uart_id => 1 },
      :P9_25 => { :gpio => 117, :gpiofunc => 'gpio3_21', :muxoffset => '0x1ac', :mcasp => 'mcasp0_ahclkx' },
      :P9_26 => { :gpio => 14, :gpiofunc => 'gpio0_14', :muxoffset => '0x180', :i2c => 'i2c1_sda', :i2c_id => 2, :uart => 'uart1_rxd', :uart_id => 1 },
      :P9_27 => { :gpio => 115, :gpiofunc => 'gpio3_19', :muxoffset => '0x1a4' },
      :P9_28 => { :gpio => 113, :gpiofunc => 'gpio3_17', :muxoffset => '0x19c', :pwm => 'ecappwm2', :pwm_id => 3, :pwm_mux => 4, :ecap => 2, :spi => 'spi1_cs0', :spi_id => 1, :mcasp => 'mcasp0_ahclkr' },
      :P9_29 => { :gpio => 111, :gpiofunc => 'gpio3_15', :muxoffset => '0x194', :pwm => 'pwm_0b', :pwm_id => 0, :pwm_mux => 1, :spi => 'spi1_d0', :spi_id => 1, :mcasp => 'mcasp0_fsx' },
      :P9_30 => { :gpio => 112, :gpiofunc => 'gpio3_16', :muxoffset => '0x198', :spi => 'spi1_d1', :spi_id => 1 },
      :P9_31 => { :gpio => 110, :gpiofunc => 'gpio3_14', :muxoffset => '0x190', :pwm => 'pwm_0a', :pwm_id => 0, :pwm_mux => 1, :spi => 'spi1_sclk', :spi_id => 1, :mcasp => 'mcasp0_aclkx' },

      :P9_32 => { :vdd_adc => 'analog output 1.8v' },
      :P9_33 => { :analog => 4 },
      :P9_34 => { :gnda_adc => 'analog ground' },
      :P9_35 => { :analog => 6 },
      :P9_36 => { :analog => 5 },
      :P9_37 => { :analog => 2 },
      :P9_38 => { :analog => 3 },
      :P9_39 => { :analog => 0 },
      :P9_40 => { :analog => 1 },

      :P9_41 => { :gpio => 20, :gpiofunc => 'gpio0_20', :muxoffset => '0x1b4' },
      :P9_42 => { :gpio => 7, :gpiofunc => 'gpio0_7', :muxoffset => '0x164', :pwm => 'ecappwm0', :pwm_id => 4, :pwm_mux => 0, :ecap => 0, :uart => 'uart3_txd', :uart_id => 3, :spi => 'spi1_sclk', :spi_id => 1 },
      :P9_43 => { :dgnd => 'ground' },
      :P9_44 => { :dgnd => 'ground' },
      :P9_45 => { :dgnd => 'ground' },
      :P9_46 => { :dgnd => 'ground' },
  }.freeze

  # Generic device trees
  TREES = {
      :GPIO => { :global => nil, :pin => 'GPIO_' },
      :UART => { :global => nil, :pin => 'BB-UART' },
      :ADC  => { :global => 'BB-ADC', :pin => nil },
      :PWM  => { :global => 'am33xx_pwm', :pin => 'bone_pwm_' },
  }.freeze

  # UART device hash
  UARTS = {
      :UART1 => { :id => 1, :rx => :P9_26, :tx => :P9_24, :dev => '/dev/ttyO1' },
      :UART2 => { :id => 2, :rx => :P9_22, :tx => :P9_21, :dev => '/dev/ttyO2' },
      :UART3 => { :id => 3, :rx => nil,    :tx => :P9_42, :dev => '/dev/ttyO3' },
      :UART4 => { :id => 4, :rx => :P9_11, :tx => :P9_13, :dev => '/dev/ttyO4' },
      :UART5 => { :id => 5, :rx => :P8_38, :tx => :P8_37, :dev => '/dev/ttyO5' },
  }.freeze

  # I2C device hash
  I2CS = {
      :I2C0  => { :id => 0, :dev => '/dev/i2c-0' },
      :I2C1  => { :id => 2, :dev => '/dev/i2c-2', :scl => :P9_17, :sda => :P9_18, :devicetree => 'BB-I2C1' },
      :I2C2  => { :id => 1, :dev => '/dev/i2c-1', :scl => :P9_19, :sda => :P9_20 },
      #alternate pins for i2c1
      :I2C1A => { :id => 2, :dev => '/dev/i2c-2', :scl => :P9_24, :sda => :P9_26, :devicetree => 'BB-I2C1A1' },
  }.freeze

  # SPI device hash
  SPIS = {
      :counter => 1,
      :SPI0    => { :id => 0, :dev => '/dev/spidev', :devicetree => 'BB-SPIDEV0',
                    :cs0 => :P9_17, :sclk => :P9_22, :d0 => :P9_21, :d1 => :P9_18,
                    :pins => [ :P9_17, :P9_18, :P9_21, :P9_22 ] },

      :SPI1    => { :id => 1, :dev => '/dev/spidev', :devicetree => 'BB-SPIDEV1',
                    :cs0 => :P9_28, :sclk => :P9_31, :d0 => :P9_29, :d1 => :P9_30,
                    :pins => [ :P9_28, :P9_29, :P9_30, :P9_31 ] },

      #alternate pins for SPI2
      :SPI1A   => { :id => 1, :dev => '/dev/spidev', :devicetree => 'BB-SPIDEV1A1',
                    :cs0 => :P9_20, :sclk => :P9_42, :d0 => :P9_29, :d1 => :P9_30,
                    :pins => [ :P9_20, :P9_29, :P9_30, :P9_42 ] },

  }

  @pinstatus = {}
  @pinmutex = Mutex.new
  @loaded_dtbs = []

  class << self
    attr_accessor :pinstatus, :pinmutex, :loaded_dtbs

    # @private
    # get hash entry for pin
    def get_pin_status(pin, key = nil)
      pinmutex.synchronize do
        if key
          pinstatus[pin] ? pinstatus[pin][key] : nil
        else
          pinstatus[pin]
        end
      end
    end

    # @private
    # set hash entry for pin
    def set_pin_status(pin, key, value)
      pinmutex.synchronize do
        pinstatus[pin]    ||= {}
        pinstatus[pin][key] = value
      end
    end

    # @private
    # delete pin's hash entry
    def delete_pin_status(pin, key = nil)
      pinmutex.synchronize do
        if key.nil?
          pinstatus.delete(pin)
        else
          pinstatus[pin].delete(key) if pinstatus[pin]
        end
      end
    end

    # disable pin
    def disable_pin(pin)
      status = get_pin_status(pin)

      if status
        case status[:type]
          when :gpio
            Beaglebone::GPIO.disable_gpio_pin(pin)
          when :pwm
            Beaglebone::PWM.disable_pwm_pin(pin)
          else
            #we can't disable any other pin types at this time
            raise StandardError, "Cannot disable pin: #{pin} in #{status[:type]} mode"
        end
      end
    end

    # check if a pin of given type is valid
    def check_valid_pin(pin, type = nil)
      #check to see if pin exists
      raise ArgumentError, "No such PIN: #{pin.to_s}" unless PINS[pin]

      if type
        raise StandardError, "Pin does not support #{type}: #{pin.to_s}" unless PINS[pin][type]
      end
    end

    # return capemgr directory
    def get_capemgr_dir
      Dir.glob('/sys/devices/bone_capemgr.*').first
    end

    # check if device tree is loaded
    def device_tree_loaded?(name)
      !!File.open("#{get_capemgr_dir}/slots").read.match(/,#{name}$/)
    end

    # load a device tree
    def device_tree_load(name)
      return true if loaded_dtbs.include?(name)

      if device_tree_loaded?(name)
        loaded_dtbs << name
        return true
      end

      File.open("#{get_capemgr_dir}/slots", 'w') { |f| f.write(name) }
      sleep(0.25)
      raise StandardError, "Unable to load device tree: #{name}" unless device_tree_loaded?(name)
      true
    end

    # unload a device tree, return false if not loaded, return true if it unloads
    def device_tree_unload(name)
      return false unless device_tree_loaded?(name)

      dtb_id = File.open("#{get_capemgr_dir}/slots", 'r').read.scan(/^ ?(\d+): .*?,#{name}/).flatten.first

      File.open("#{get_capemgr_dir}/slots", 'w') { |f| f.write("-#{dtb_id}") }

      raise StandardError, "Unable to unload device tree: #{name}" if device_tree_loaded?(name)

      true
    end

    # cleanup all the things
    def cleanup
      Beaglebone::AIN.cleanup
      Beaglebone::PWM.cleanup
      Beaglebone::GPIO.cleanup
      Beaglebone::UART.cleanup
      Beaglebone::I2C.cleanup
      Beaglebone::SPI.cleanup
    end
  end
end

