# Beaglebone Ruby Library

**Table of Contents**
- [Overview](#overview)
- [Installation](#installation)
  - [Installing Ruby](#installing-ruby)
  - [Installing Beaglebone Gem](#installing-beaglebone-gem)
  - [Updating Beaglebone Gem](#updating-beaglebone-gem)
- [Usage](#usage)
  - [Ruby in Cloud9](#ruby-in-cloud9)
- [Pin Information](#pin-information)
  - [GPIO Pins](#gpio-pins)
  - [Analog Pins](#analog-pins)
  - [PWM Pins](#pwm-pins)
  - [UART Pins](#uart-pins)
  - [I2C Pins](#i2c-pins)
  - [SPI Pins](#spi-pins)
- [Source Code Reference](#source-code-reference)
- [Examples (Object Oriented)](#examples-object-oriented)
  - [GPIO](#gpio)
    - [GPIO Writing](#gpio-writing)
    - [GPIO Reading](#gpio-reading)
    - [LEDs](#leds)
    - [Edge Triggers](#edge-triggers)
    - [Edge Triggers in the Background](#edge-triggers-in-the-background)
    - [Shift Registers](#shift-registers)
  - [Analog Inputs](#analog-inputs)
    - [Reading](#reading)
    - [Waiting for Change](#waiting-for-change)
    - [Waiting for Change in the Background](#waiting-for-change-in-the-background)
    - [Waiting for Threshold](#waiting-for-threshold)
    - [Waiting for Threshold in the Background](#waiting-for-Threshold-in-the-background)
  - [PWM](#pwm)
  - [UART](#uart)
    - [UART Writing](#uart-writing)
    - [UART Reading](#uart-reading)
    - [UART Reading and Iterating](#uart-reading-and-iterating)
    - [UART Reading and Iterating in the Background](#uart-reading-and-iterating-in-the-background)
  - [I2C](#i2c)
    - [I2C Writing](#i2c-writing)
    - [I2C Reading](#i2c-reading)
    - [LSM303DLHC Example](#lsm303dlhc-example)
  - [SPI](#spi)
    - [SPI Data Transfer](#spi-data-transfer)
    - [MCP3008 Example](#mcp3008-example)
- [Examples (Procedural)](#examples-procedural)
- [License](#license)

## Overview
The purpose of this library is to provide easy access to all of the IO features of the Beaglebone in a highly flexible programming language (Ruby).  This gem includes object oriented methods as well as procedural methods, so those familiar with Bonescript, the Adafruit Python library, or Arduino programming will be familiar with the syntax.  This was developed and tested on a Beaglebone Black running the official Debian images.  The code will need to be executed as root in order to function properly and utilize all of the features of the Beaglebone.

## Installation
### Installing Ruby
Ruby and Rubygems are required to use this gem.  To install, simply run the command below.  This will install Ruby 1.9.3 which includes Rubygems.

```
sudo apt-get install ruby
```

### Installing Beaglebone Gem
Once Ruby is installed installed, install the gem by running the command below.

```
sudo gem install beaglebone
```

### Updating Beaglebone Gem
Once the gem is installed, you can update to the latest version by running the command below.  New versions may contain bug fixes and new features.

```
sudo gem update beaglebone
```

## Usage
To use this gem, require it in the Ruby script.  An example follows

```ruby
#!/usr/bin/env ruby
require 'beaglebone'
include Beaglebone
```

### Ruby in Cloud9
Cloud9 has native Ruby support.  Name your files with the extension .rb to run Ruby in Cloud9

## Pin Information
The Beaglebone has two headers of IO pins.  Documentation on these pins is available [here](http://beagleboard.org/Support/bone101#headers).

### GPIO Pins
The beaglebone has a large number of GPIO pins.  These pins function at 3.3v.  Do not provide more than 3.3v to any GPIO pin or risk damaging the hardware.

There are built in _capes_ that have priority over the GPIO pins unless disabled.  These are for HDMI and the onboard eMMC.  It is documented [here](http://beagleboard.org/Support/bone101#headers-black).  It is possible to disable these _capes_ if you are not using them.

### Analog Pins
The beaglebone has 7 Analog inputs.  Documentation on these pins is available [here](http://beagleboard.org/Support/bone101#headers-analog).  These pins function at 1.8v.  Do not provide more than 1.8v to any Analog pin or risk damaging the hardware.  The header has pins available to provide a 1.8v for analog devices as well as a dedicated analog ground.

### PWM Pins
The beaglebone has 8 PWM pins.  Documentation on these pins is available [here](http://beagleboard.org/Support/bone101#headers-pwm).  These pins function at 3.3v.

Not all 8 pins may be used at the same time. You may use the following pins.

- P8_13 or P8_19
- P9_14 or P9_16
- P9_21 or P9_22
- P9_28 and P9_42

### UART Pins
The beaglebone has 5 UART devices available.  Documentation on these pins is available [here](http://beagleboard.org/Support/bone101#headers-serial).  These pins function at 3.3v.  Do not provide more than 3.3v to any UART pin or risk damaging the hardware.

UART3 only has a TX pin available.

UART5 TX and RX pins are unavailable by default, as the HDMI _cape_ claims those pins unless disabled.

### I2C Pins
The beaglebone has 2 I2C devices available.  Documentation on these pins is available [here](http://beagleboard.org/Support/bone101#headers-i2c).  These pins function at 3.3v.  Do not provide more than 3.3v to any I2C pin or risk damaging the hardware.

### SPI Pins
The beaglebone has 2 SPI devices available.  Documentation on these pins is available [here](http://beagleboard.org/Support/bone101#headers-spi).  These pins function at 3.3v.  Do not provide more than 3.3v to any SPI pin or risk damaging the hardware.

## Source Code Reference
A full Source Code reference is available [here](http://rubydoc.info/gems/beaglebone/1.0.5/frames).

## Examples (Object Oriented)
These examples will show the various ways to interact with the Beaglebones IO hardware.  They will need to be executed as root in order to function correctly.

### GPIO
The GPIO pins on the Beaglebone run at **3.3v**.  Do not provide more than 3.3v to any GPIO pin or risk damaging the hardware.

GPIO pins have two modes, input and output.  These modes are represented by the symbols **:IN** and **:OUT**.

GPIO pins have internal pullup and pulldown resistors.  These modes are represented by the symbols **:PULLUP**, **:PULLDOWN**, and **:NONE**.

GPIO pins have an adjustable slew rate.  These modes are represented by the symbols **:FAST** and **:SLOW**

To initialize the pin **P9_11**, pass the symbol for that pin and the mode to the **GPIOPin** constructor.

```ruby
# Initialize pin P9_11 in INPUT mode
# This method takes 4 arguments
# pin: The pin to initialize
# mode: The GPIO mode, :IN or :OUT
# pullmode: (optional) The pull mode, :PULLUP, :PULLDOWN, or :NONE
# slewrate: (optional) The slew rate, :FAST or :SLOW
p9_11 = GPIOPin.new(:P9_11, :IN, :PULLUP, :FAST)

# Initialize pin P9_12 in OUTPUT mode
p9_12 = GPIOPin.new(:P9_12, :OUT)

# Change pin P9_12 to INPUT mode
p9_12.set_gpio_mode(:IN)

# Disable pin P9_12
p9_12.disable_gpio_pin

# Unassign to prevent re-use
p9_12 = nil
```

#### GPIO Writing
To set the state of a GPIO pin, the method **#digital_write** is used.  The states that can be set are **:HIGH** to provide 3.3v and **:LOW** to provide ground.

```ruby
# Initialize pin P9_12 in OUTPUT mode
p9_12 = GPIOPin.new(:P9_12, :OUT)

# Provide 3.3v on pin P9_12
p9_12.digital_write(:HIGH)

# Provide ground on pin P9_12
p9_12.digital_write(:LOW)
```

#### GPIO Reading
To read the current state of a GPIO pin, the method **#digital_read** is used.  It will return the symbol **:HIGH** or **:LOW** depending on the state of the pin.

```ruby
# Initialize pin P9_11 in INPUT mode
p9_11 = GPIOPin.new(:P9_11, :IN)

# Get the current state of P9_11
state = p9_11.digital_read => :LOW
```

#### LEDs
The on-board LEDs are addressable via GPIO output.  They are available on pins **:USR0** through **:USR3**.

This example will blink each LED in order 5 times.

```ruby
# Create an led object for each LED
led1 = GPIOPin.new(:USR0, :OUT)
led2 = GPIOPin.new(:USR1, :OUT)
led3 = GPIOPin.new(:USR2, :OUT)
led4 = GPIOPin.new(:USR3, :OUT)

# Run the following block 5 times
5.times do
  # Iterate over each LED
  [led1,led2,led3,led4].each do |led|
    # Turn on the LED
    led.digital_write(:HIGH)
    # Delay 0.25 seconds
    sleep 0.25
    # Turn off the LED
    led.digital_write(:LOW)
  end
end
```

#### Edge Triggers
The Beaglebone can monitor for changes on a GPIO pin.  This is called an edge trigger.  Since this is interrupt based on the Beaglebone, waiting for a change does not waste CPU cycles by constantly polling the pin.

The following trigger types are supported
- Rising: Triggered when the state goes from low to high
- Falling: Triggered when the state goes from high to low
- Both: Triggered at any change in state
- None: Triggering is disabled

These trigger types are represented by the symbols :RISING, :FALLING, :BOTH, and :NONE

This example will wait for a rising edge to continue, then output the type of edge trigger that was detected.

```ruby
# Initialize pin P9_11 in INPUT mode
p9_11 = GPIOPin.new(:P9_11, :IN)

# Wait here until a rising edge is detected
edge = p9_11.wait_for_edge(:RISING) => :RISING

# Output the trigger type detected
puts "Saw a #{edge} edge"
```

#### Edge Triggers in the Background
To avoid blocking while waiting for an edge trigger, the method **#run_on_edge** will run a callback when an edge trigger is detected.  This method will spawn a new thread and wait for an edge trigger in the background.  Only one of these threads may be active per pin.

This example will detect edge triggers in the background and output information when triggered.

```ruby
# Initialize pin P9_11 in INPUT mode
p9_11 = GPIOPin.new(:P9_11, :IN)

# Define callback to run when an edge trigger is detected
# This method takes 3 arguments.
# pin: The pin that triggered the event
# edge: The event that triggered it
# count: How many times it has been triggered
callback = lambda { |pin,edge,count| puts "[#{count}] #{pin} #{edge}"}

# Run the callback every time a change in state is detected
# This method has two additional arguments that are optional.
# Timeout: How long to wait for an event before terminating the thread
# Repeats: How many times to run the event
# By default, it will run forever every time the specified trigger is detected
p9_11.run_on_edge(callback, :BOTH)

# This code will run immediately after the previous call, as it does not block
sleep 10

# Stop the background thread waiting for an edge trigger after 10 seconds
p9_11.stop_edge_wait

# This convenience method will run the callback only on the first detected change
p9_11.run_once_on_edge(callback, :BOTH)

# Change the trigger detection for the specified pin
p9_11.set_gpio_edge(:RISING)
```

#### Shift Registers
This library will support writing to shift registers using GPIO pins.  Create a **ShiftRegister** object by initializing it with the latch pin, clock pin, and data pin.

This example will trigger 8 pins of a shift register.

```ruby
# P9_11 is connected to the latch pin
# P9_12 is connected to the clock pin
# P9_13 is connected to the data pin

# Initialize shift register
shiftreg = ShiftRegister.new(:P9_11, :P9_12, :P9_13)

# Write value to shift register
shiftreg.shift_out(0b11111111)
```


### Analog Inputs
The Analog pins on the Beaglebone run at **1.8v**.  Do not provide more than 1.8v to any analog pin or risk damaging the hardware.  The header has pins available to provide a 1.8v for analog devices as well as a dedicated analog ground.  Analog pins are only capable of reading input values.

To initialize the pin **P9_33**, pass the symbol for that pin and the mode to the **AINPin** constructor.

```ruby
# Initialize pin P9_33 for Analog Input
p9_33 = AINPin.new(:P9_33)
```

#### Reading
To read the value from an analog pin, the method **#read** is used.  This will return a value between 0 and 1799.

```ruby
# Initialize pin P9_33 for Analog Input
p9_33 = AINPin.new(:P9_33)

# Read the input value in millivolts.
mv = p9_33.read => 1799
```

#### Waiting for Change
To wait for the value of an analog pin to change by a specified voltage, the method **#wait_for_change** is used.

**#wait_for_change** takes the following arguments.
- mv_change: The amount of change in millivolts required before returning
- interval: How often to poll the value of the pin in seconds
- mv_last: (optional) The initial value to use as a point to detect change

This method returns an array containing the initial voltage, the last polled voltage, and the number of times the pin was polled.

```ruby
# Initialize pin P9_33 for Analog Input
p9_33 = AINPin.new(:P9_33)

# Wait for 100mv of change on pin P9_33.  Poll 10 times a second
mv_start, mv_current, count = p9_33.wait_for_change(100, 0.1)
```

#### Waiting for Change in the Background
To avoid blocking while waiting for voltage change, the method **#run_on_change** will run a callback every time the specified change is detected.  This method will spawn a new thread and wait for change in the background.  The method **#run_once_on_change** is a convenience method to only be triggered once.  Only one of these threads may be active per pin.

This example waits for voltage change in the background and outputs information when change is detected.

```ruby
# Initialize pin P9_33 for Analog Input
p9_33 = AINPin.new(:P9_33)

# Define callback to run when condition is met
# This method takes 4 arguments.
# pin: The pin that triggered the event
# mv_last: The initial voltage used to determine change
# mv: The current voltage on the pin
# count: How many times it has been triggered
callback = lambda { |pin, mv_last, mv, count| puts "[#{count}] #{pin} #{mv_last} -> #{mv}" }

# Run the callback every time the specified voltage change is detected
# This method has one additional argument that is optional.
# Repeats: How many times to will run the event
# By default, it will run forever every time the specified condition is detected
# Detect 10mv of change polling 10 times a second.
p9_33.run_on_change(callback, 10, 0.1)

# This code will run immediately after the previous call, as it does not block
sleep 20

# Stop the background thread after 20 seconds
p9_33.stop_wait
```

#### Waiting for Threshold
To wait for the value of an analog pin to cross certain threshold voltages, the method **#wait_for_threshold** is used.

**#wait_for_threshold** takes the following arguments.
- mv_lower: The lower threshold value in millivolts
- mv_upper: The upper threshold value in millivolts
- mv_reset: The voltage change required to cross out of the lower or upper threshold ranges.
- interval: How often to poll the value of the pin in seconds
- mv_last: (optional) The initial value to use as a point to detect change
- state_last: (optional) The initial state to use as a point to detect change

Three states are available.
- :LOW: below or equal to mv_lower
- :MID: above mv_lower and below mv_upper
- :HIGH: above or equal to mv_upper

This method returns an array containing the initial voltage, the last polled voltage, the initial state, the last polled state, and the number of times the pin was polled.

```ruby
# Initialize pin P9_33 for Analog Input
p9_33 = AINPin.new(:P9_33)

# Wait for the voltage on pin P9_33 to go below 200mv or above 1600mv.
# To enter the :MID state from :HIGH or :LOW, it will have to cross the thresholds by at least 100mv.
# Poll 10 times a second
data = p9_33.wait_for_threshold(200, 1600, 100, 0.1) => [ 500, 150, :MID, :LOW, 53 ]

# Assign variables from array
mv_start, mv_current, state_start, state_current, count = data
```

#### Waiting for Threshold in the Background
To avoid blocking while waiting for a voltage threshold to be crossed, the method **#run_on_threshold** will run a callback every time the specified change is detected.  This method will spawn a new thread and wait for change in the background.  The method **#run_once_on_threshold** is a convenience method to only be triggered once.  Only one of these threads may be active per pin.

This example waits for voltage change in the background and outputs information when the specified threshold is crossed.

```ruby
# Initialize pin P9_33 for Analog Input
p9_33 = AINPin.new(:P9_33)

# Define callback to run when condition is met
# This method takes 6 arguments.
# pin: The pin that triggered the event
# mv_last: The initial voltage used to determine change
# mv: The current voltage on the pin
# state_last: The initial state to use as a point to detect change
# state: The current state of the pin
# count: How many times it has been triggered
callback = lambda { |pin, mv_last, mv, state_last, state, count|
  puts "[#{count}] #{pin} #{state_last} -> #{state}     #{mv_last} -> #{mv}"
}

# Run the callback every time the specified voltage threshold is crossed
# This method has one additional argument that is optional.
# Repeats: How many times to will run the event
# By default, it will run forever every time the specified condition is detected
# Wait for the voltage on pin P9_33 to go below 200mv or above 1600mv.
# To enter the :MID state from :HIGH or :LOW, it will have to cross the thresholds by at least 100mv.
# Poll 10 times a second
# Run callback when state changes
p9_33.run_on_threshold(callback, 200, 1600, 100, 0.1)

# This code will run immediately after the previous call, as it does not block
sleep 20

# Stop the background thread after 20 seconds
p9_33.stop_wait
```

### PWM
The beaglebone supports PWM (pulse width modulated) output on certain pins.  These pins output 3.3v.  The output is controlled based on frequency and duty cycle.

To initialize the pin **P9_14**, pass the symbol for that pin, the duty cycle, and the frequency in Hz to the **PWMPin** constructor.

This example shows how to control PWM output of a specified pin.

```ruby
# Initialize pin P9_14 for PWM output
# This pin will now output a square wave at 10Hz with a 90% duty cycle, non-inverted.
p9_14 = PWMPin.new(:P9_14, 90, 10, :NORMAL)

# Change frequency to 20Hz.  Duty cycle remains 90%
p9_14.set_frequency(20)

# Change the duty cycle to 50%
p9_14.set_duty_cycle(50)

# Adjust the frequency by setting the period in nanoseconds.
p9_14.set_period_ns(31250000)

# Adjust the duty cycle by setting the period in nanoseconds.
p9_14.set_duty_cycle_ns(31250000)

# Invert the output signal
p9_14.set_polarity(:INVERTED)

# Stop the output signal
p9_14.stop

# Resume the output signal
p9_14.run

# Disable the output signal
p9_14.disable_pwm_pin
```

### UART
The beaglebone has a number of UART devices.  These operate in TTL mode at 3.3v.  Do not provide more than 3.3v to the pins or risk damaging the hardware.

Please note, UART3 does not have an RX pin, and UART5 is only available if the HDMI device tree is not enabled.

To initialize the UART device **UART1**, pass the symbol for that device and the speed to the **UARTDevice** constructor.

```ruby
# Initialize the pins for device UART1 into UART mode.
uart1 = UARTDevice.new(:UART1, 9600)

# Change the speed of a UART device by calling #set_speed
uart1.set_speed(115200)

# Disable UART device
uart1.disable
```

#### UART Writing
Writing to a UART device is accomplished by calling the **#write** or **#writeln** methods
```ruby
# Initialize the pins for device UART1 into UART mode.
uart1 = UARTDevice.new(:UART1, 9600)

# Write data to a UART1
uart1.write("DATA DATA DATA!")

# Write data to UART1 followed by a line feed
uart1.writeln("A line feed follows")
```

#### UART Reading
There are many methods available for reading from UART devices.  These are blocking methods and will not return until the requested data is available.

```ruby
# Initialize the pins for device UART1 into UART mode.
uart1 = UARTDevice.new(:UART1, 9600)

# Read one character from UART1
c = uart1.readchar => "X"

# Read 10 characters from UART1
str = uart1.readchars(10) => "0123456789"

# Read a line from UART1
line = uart1.readline => "All the text up until the linefeed"
```

#### UART Reading and Iterating
Data read from the UART device may be iterated with the following methods.  These are blocking methods and will run until the loop is broken.

```ruby
# Initialize the pins for device UART1 into UART mode.
uart1 = UARTDevice.new(:UART1, 9600)

# Run block on every character read from UART1
uart1.each_char { |c| puts c }

# Run block on every 5 character read from UART1
uart1.each_char(5) { |str| puts str }

# Run block on each line read from UART1
uart1.each_line { |line| puts line }
```

#### UART Reading and Iterating in the Background
Data read from the UART device may be iterated in the background with the following methods.  The data read is passed to the specified callback.  These method will spawn a new thread and wait for data in the background.  Only one of these threads may be active per pin.

This example shows various methods of reading and processing data read from UART1 in the background.

```ruby
# Initialize the pins for device UART1 into UART mode.
uart1 = UARTDevice.new(:UART1, 9600)

# Define the callback to be run.  It takes 3 arguments
# uart: the UART device that triggered the callback
# data: the data read from the UART
# count: how many times this was triggered
callback = lambda { |uart, data, count| puts "[#{uart}:#{count}] #{data}" }

# Run callback for every character read
uart1.run_on_each_char(callback)

# Run callback for every 3 characters read
uart1.run_on_each_chars(callback, 3)

# Run callback for every line read
uart1.run_on_each_line(callback)

# Run callback once after a character is read
uart1.run_once_on_each_char(callback)

# Run callback once after 3 characters are read
uart1.run_once_on_each_chars(callback, 3)

# Run callback once after reading a line
uart1.run_once_on_each_line(callback)

# Stop the currently running background thread
uart1.stop_read_wait
```

### I2C
The beaglebone has a number of I2C devices.  These operate at 3.3v.  Do not provide more than 3.3v to the pins or risk damaging the hardware.

To initialize the I2C device **I2C2**, pass the symbol for that device to the **I2CDevice** constructor.

```ruby
# Initialize I2C device I2C2
i2c = I2CDevice.new(:I2C2)
```

#### I2C Writing
To write to an I2C device, the method **#write** is used.

**#write** takes the following arguments.
- address: address of slave device
- data: data to write

#### I2C Reading
To read from an I2C device, the method **#read** is used.

**#read** takes the following arguments.
- address: address of slave device
- bytes: bytes to read
- register: (optional) register to start reading from

#### LSM303DLHC Example

This example communicates with an [LSM303DLHC](https://www.adafruit.com/products/1120) Accelerometer/Compass/Thermometer device.

```ruby
#!/usr/bin/env ruby
require 'beaglebone'
include Beaglebone

# Initialize I2C device I2C2
i2c = I2CDevice.new(:I2C2)

# Put compass into continuous conversation mode
i2c.write(0x1e, [0x02, 0x00].pack("C*"))

# Enable temperatuer sensor, 15hz register update
i2c.write(0x1e, [0x00, 0b10010000].pack("C*") )

# Delay for the settings to take effect
sleep(0.1)

# Read axis data.  It is made up of 3 big endian signed shorts starting at register 0x03
raw = i2c.read(0x1e, 6, [0x03].pack("C*"))

# Coordinates are big endian signed shorts in x,z,y order
x,z,y = raw.unpack("s>*")

# Calculate angle of degrees from North
degrees = (Math::atan2(y, x) * 180) / Math::PI
degrees += 360 if degrees < 0

# Read 2 byte big endian signed short from temperature register
raw = i2c.read(0x1e, 2, [0x31].pack("C*"))

# Temperature is sent big endian, least significant digit last
temp = raw.unpack("s>").first

# Temperature data is 12 bits, last 4 are unused
temp = temp >> 4

# Each bit is 8c
temp /= 8

# Correction factor
temp += 18

# Convert to f
temp = (temp * 1.8 + 32).to_i

# Output data
puts "#{Time.now.strftime("%H:%M")}  Temperature: #{temp} degrees f        Direction: #{degrees.to_i} degrees"

# Disable I2C device
i2c.disable
```

### SPI
The beaglebone has a number of SPI devices.  These operate at 3.3v.  Do not provide more than 3.3v to the pins or risk damaging the hardware.

To initialize the SPI device **SPI0**, pass the symbol for that device to the **SPIDevice** constructor.

The optional arguments are available
- mode: SPI mode, :SPI_MODE_0 through :SPI_MODE_3
- speed: Speed of the SPI device
- bpw: Bits per word

```ruby
# Initialize SPI device SPI0
spi = SPIDevice.new(:SPI0, :SPI_MODE_0, 1000000, 8)

# You can change SPI  with the methods below.

# Set mode of SPI0
spi.set_mode(:SPI_MODE_3)

# Set speed of SPI0
spi.set_speed(100000)

# Set bits per word of SPI0
spi.set_bpw(10)

# Disable SPI device
spi.disable
```

#### SPI Data Transfer
To transfer data to an SPI device, the method **#xfer** is used.

**#xfer** takes the following arguments
- tx_data: data to transmit
- readbytes: (optional) number of bytes to read, otherwise it sizeof tx_data is used
- speed: (optional) speed of the transfer
- delay: (optional) delay
- bpw: (optonal) bits per word

**#xfer** returns the data read from the SPI device.

#### MCP3008 Example
This example communicates with an [MCP3008](http://www.adafruit.com/products/856) ADC device.

```ruby
#!/usr/bin/env ruby
require 'beaglebone'
include Beaglebone

# Initialize SPI device SPI0
spi = SPIDevice.new(:SPI0)

# communicate with MCP3008
# byte 1: start bit
# byte 2: single(1)/diff(0),3 bites for channel, null pad
# byte 3: don't care
# Read value from channel 0
raw = spi.xfer([ 0b00000001, 0b10000000, 0].pack("C*"))

# Split data read into an array of characters
data = raw.unpack("C*")

# The returned data is stored starting at the last two bits of the second byte
val = ((data[1] & 0b00000011) << 8 ) | data[2]

# Display the value of channel 0
puts "Value of channel 0: #{val}"

# Read value from channel 1
raw = spi.xfer([ 0b00000001, 0b10010000, 0].pack("C*"))

# Split data read into an array of characters
data = raw.unpack("C*")

# The returned data is stored starting at the last two bits of the second byte
val = ((data[1] & 0b00000011) << 8 ) | data[2]

# Display the value of channel 1
puts "Value of channel 1: #{val}"

# Disable SPI device
spi.disable
```

## Examples (Procedural)
This library supports _procedural_ methods as well as _object oriented_ methods.  They are virtually identical to the _object oriented_ methods, except the first argument they take is the pin.  If a callback is required, it is still passed first, before the pin.

The procedural versions of the examples are available in the file [procedural-examples.md](procedural-examples.md).

Instead of constructors, the following methods are used to initialize the pins and devices on the Beaglebone.

```ruby
# GPIOPin.new becomes
GPIO.pin_mode(:P9_12, :OUT)

# To set the state of the pin
GPIO.digital_write(:P9_12, :OUT)

# Analog pins do not require setup, and can be read at any time
AIN.read(:P9_33)

# PWMPin.new becomes
PWM.start(:P9_14, 90, 10, :NORMAL)

# UARTDevice.new becomes
UART.setup(:UART1, 9600)

# I2CDevice.new becomes
I2C.setup(:I2C2)

# SPIDevice.new becomes
SPI.setup(:SPI0)
```

## License
Copyright (c) 2014 Rob Mosher.  Distributed under the GPL-v3 License.  See [LICENSE](LICENSE) for more information.
