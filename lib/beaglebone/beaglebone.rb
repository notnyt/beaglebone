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

      :P8_3  => { :gpio => 38, :mmc => 'mmc1_dat6' },
      :P8_4  => { :gpio => 39, :mmc => 'mmc1_dat7' },
      :P8_5  => { :gpio => 34, :mmc => 'mmc1_dat2' },
      :P8_6  => { :gpio => 35, :mmc => 'mmc1_dat3' },

      :P8_7  => { :gpio => 66, :timer => 'timer4' },
      :P8_8  => { :gpio => 67, :timer => 'timer7' },
      :P8_9  => { :gpio => 69, :timer => 'timer5' },
      :P8_10 => { :gpio => 68, :timer => 'timer6' },

      :P8_11 => { :gpio => 45 },
      :P8_12 => { :gpio => 44 },

      # You can emable PWM as listed below
      # P8_13 *OR* P8_19 (EHRPWM2B, EHRPWM2A),
      # P9_14 *OR* P9_16 (EHRPWM1A, EHRPWM1B),
      # P9_21 *OR* P9_22 (EHRPWM0B, EHRPWM0A).
      # there are also ecap pwms on pins P9_28 and P9_42

      :P8_13 => { :gpio => 23, :pwm => 'pwm_2b', :pwm_id => 2, :pwm_mux => 4 },

      :P8_14 => { :gpio => 26 },
      :P8_15 => { :gpio => 47 },
      :P8_16 => { :gpio => 46 },
      :P8_17 => { :gpio => 27 },
      :P8_18 => { :gpio => 66 },

      :P8_19 => { :gpio => 22, :pwm => 'pwm_2a', :pwm_id => 2, :pwm_mux => 4 },

      # You can only use the mmc pins if booting from SD and disabling mmc
      # mmc reset behavior is unclear
      # Best option is to not use the MMC1_CLK and MMC1_CMD signals at all and tie them low.
      :P8_20 => { :gpio => 63, :mmc => 'mmc1_cmd' },
      :P8_21 => { :gpio => 62, :mmc => 'mmc1_clk' },
      :P8_22 => { :gpio => 37, :mmc => 'mmc1_dat5' },
      :P8_23 => { :gpio => 36, :mmc => 'mmc1_dat4' },
      :P8_24 => { :gpio => 33, :mmc => 'mmc1_dat1' },
      :P8_25 => { :gpio => 32, :mmc => 'mmc1_dat0' },

      :P8_26 => { :gpio => 61 },
      :P8_27 => { :gpio => 86, :lcd => 'lcd_vsync' },
      :P8_28 => { :gpio => 88, :lcd => 'lcd_pclk' },
      :P8_29 => { :gpio => 87, :lcd => 'lcd_hsync' },
      :P8_30 => { :gpio => 89, :lcd => 'lcd_ac_bias' },
      :P8_31 => { :gpio => 10, :lcd => 'lcd_data14', :uart => 'uart5_ctsn', :uart_id => 5 },
      :P8_32 => { :gpio => 11, :lcd => 'lcd_data15', :uart => 'uart5_rtsn', :uart_id => 5 },
      :P8_33 => { :gpio => 9, :lcd => 'lcd_data13', :uart => 'uart4_rtsn', :uart_id => 4 },
      :P8_34 => { :gpio => 81, :lcd => 'lcd_data11', :pwm => 'pwm_1b', :pwm_id => 1, :pwm_mux => 2, :uart => 'uart3_rtsn', :uart_id => 3 },
      :P8_35 => { :gpio => 8, :lcd => 'lcd_data12', :uart => 'uart4_ctsn' },
      :P8_36 => { :gpio => 80, :lcd => 'lcd_data10', :pwm => 'pwm_1a', :pwm_id => 1, :pwm_mux => 2, :uart => 'uart3_ctsn', :uart_id => 3 },
      :P8_37 => { :gpio => 78, :lcd => 'lcd_data8', :uart => 'uart5_txd', :uart_id => 5 },
      :P8_38 => { :gpio => 79, :lcd => 'lcd_data9', :uart => 'uart5_rxd', :uart_id => 5 },
      :P8_39 => { :gpio => 76, :lcd => 'lcd_data6' },
      :P8_40 => { :gpio => 77, :lcd => 'lcd_data7' },
      :P8_41 => { :gpio => 74, :lcd => 'lcd_data4' },
      :P8_42 => { :gpio => 75, :lcd => 'lcd_data5' },
      :P8_43 => { :gpio => 72, :lcd => 'lcd_data2' },
      :P8_44 => { :gpio => 73, :lcd => 'lcd_data3' },
      :P8_45 => { :gpio => 70, :lcd => 'lcd_data0', :pwm => 'pwm_2a', :pwm_id => 2, :pwm_mux => 3 },
      :P8_46 => { :gpio => 71, :lcd => 'lcd_data1', :pwm => 'pwm_2b', :pwm_id => 2, :pwm_mux => 3 },

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

      :P9_11 => { :gpio => 30, :uart => 'uart4_rxd', :uart_id => 4 },
      :P9_12 => { :gpio => 60 },
      :P9_13 => { :gpio => 31, :uart => 'uart4_txd', :uart_id => 4 },
      :P9_14 => { :gpio => 40, :pwm => 'pwm_1a', :pwm_id => 1, :pwm_mux => 6 },
      :P9_15 => { :gpio => 48 },
      :P9_16 => { :gpio => 51, :pwm => 'pwm_1b', :pwm_id => 1, :pwm_mux => 6 },
      #17 and 18 are not currently working for gpio in 3.8
      :P9_17 => { :gpio => 4, :i2c => 'i2c1_scl', :i2c_id => 1, :spi => 'spi0_cs0', :spi_id => 0 },
      :P9_18 => { :gpio => 5, :i2c => 'i2c1_sda', :i2c_id => 1, :spi => 'spi0_d1', :spi_id => 0 },
      :P9_19 => { :i2c => 'i2c2_scl', :i2c_id => 2, :uart => 'uart1_rtsn', :uart_id => 1, :spi => 'spi1_cs1', :spi_id => 1 },
      :P9_20 => { :i2c => 'i2c2_sda', :i2c_id => 2, :uart => 'uart1_ctsn', :uart_id => 1, :spi => 'spi1_cs0', :spi_id => 1 },
      :P9_21 => { :gpio => 3, :pwm => 'pwm_0b', :pwm_id => 0, :pwm_mux => 3, :i2c => 'i2c2_scl', :i2c_id => 2, :uart => 'uart2_txd', :uart_id => 2, :spi => 'spi0_d0', :spi_id => 0 },
      :P9_22 => { :gpio => 2, :pwm => 'pwm_0a', :pwm_id => 0, :pwm_mux => 3, :i2c => 'i2c2_sda', :i2c_id => 2, :uart => 'uart2_rxd', :uart_id => 2, :spi => 'spi0_sclk', :spi_id => 0 },
      :P9_23 => { :gpio => 49 },
      :P9_24 => { :gpio => 15, :i2c => 'i2c1_scl', :i2c_id => 1, :uart => 'uart1_txd', :uart_id => 1 },
      :P9_25 => { :gpio => 117 },
      :P9_26 => { :gpio => 14, :i2c => 'i2c1_sda', :i2c_id => 2, :uart => 'uart1_rxd', :uart_id => 1 },
      :P9_27 => { :gpio => 125 },
      :P9_28 => { :gpio => 123, :pwm => 'ecappwm2', :pwm_id => 3, :pwm_mux => 4, :ecap => 2, :spi => 'spi1_cs0', :spi_id => 1 },
      :P9_29 => { :gpio => 121, :pwm => 'pwm_0b', :pwm_id => 0, :pwm_mux => 1, :spi => 'spi1_d0', :spi_id => 1 },
      :P9_30 => { :gpio => 122, :spi => 'spi1_d1', :spi_id => 1 },
      :P9_31 => { :gpio => 120, :pwm => 'pwm_0a', :pwm_id => 0, :pwm_mux => 1, :spi => 'spi1_sclk', :spi_id => 1 },

      :P9_32 => { :vdd_adc => 'analog output 1.8v' },
      :P9_33 => { :analog => 4 },
      :P9_34 => { :gnda_adc => 'analog ground' },
      :P9_35 => { :analog => 6 },
      :P9_36 => { :analog => 5 },
      :P9_37 => { :analog => 2 },
      :P9_38 => { :analog => 3 },
      :P9_39 => { :analog => 0 },
      :P9_40 => { :analog => 1 },

      :P9_41 => { :gpio => 20 },
      :P9_42 => { :gpio => 7, :pwm => 'ecappwm0', :pwm_id => 4, :pwm_mux => 0, :ecap => 0, :uart => 'uart3_txd', :uart_id => 3, :spi => 'spi1_sclk', :spi_id => 1 },
      :P9_43 => { :dgnd => 'ground' },
      :P9_44 => { :dgnd => 'ground' },
      :P9_45 => { :dgnd => 'ground' },
      :P9_46 => { :dgnd => 'ground' },
  }.freeze

  # Generic device trees
  TREES = {
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
      pin = pin.to_sym.upcase
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

      raise StandardError, "Unable to load device tree: #{name}" unless device_tree_loaded?(name)
      sleep(0.25)
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

