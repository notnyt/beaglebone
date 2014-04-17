TODO: convert this to procedural methods.

**Table of Contents**
- [Examples (Procedural)](#examples-procedural)
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

## Examples (Procedural)
These examples will show the various ways to interact with the Beaglebones IO hardware.  They will need to be executed as root in order to function correctly.

### GPIO
The GPIO pins on the Beaglebone run at **3.3v**.  Do not provide more than 3.3v to any GPIO pin or risk damaging the hardware.

GPIO pins have two modes, input and output.  These modes are represented by the symbols **:IN** and **:OUT**.

To initialize the pin **P9_11**, pass the symbol for that pin and the mode to the **GPIO.pin_mode** method.

```ruby
# Initialize pin P9_11 in INPUT mode
GPIO.pin_mode(:P9_11, :IN)

# Initialize pin P9_12 in OUTPUT mode
GPIO.pin_mode(:P9_12, :OUT)

# Change pin P9_12 to INPUT mode
GPIO.set_gpio_mode(:P9_12, :IN)

# Disable pin P9_12
GPIO.disable_gpio_pin(:P9_12)
```

#### GPIO Writing
To set the state of a GPIO pin, the method **GPIO.digital_write** is used.  The states that can be set are **:HIGH** to provide 3.3v and **:LOW** to provide ground.

```ruby
# Initialize pin P9_12 in OUTPUT mode
GPIO.pin_mode(:P9_12, :OUT)

# Provide 3.3v on pin P9_12
GPIO.digital_write(:P9_12, :HIGH)

# Provide ground on pin P9_12
GPIO.digital_write(:P9_12, :LOW)
```

#### GPIO Reading
To read the current state of a GPIO pin, the method **GPIO.digital_read** is used.  It will return the symbol **:HIGH** or **:LOW** depending on the state of the pin.

```ruby
# Initialize pin P9_11 in INPUT mode
GPIO.pin_mode(:P9_11, :IN)

# Get the current state of P9_11
state = GPIO.digital_read(:P9_11) => :LOW
```

#### LEDs
The on-board LEDs are addressable via GPIO output.  They are available on pins **:USR0** through **:USR3**.

This example will blink each LED in order 5 times.

```ruby
# Initialize each LED pin
leds = [ :USR0, :USR1, :USR2, :USR3 ]
leds.each do |ledpin|
  GPIO.pin_mode(ledpin, :OUT)
end


# Run the following block 5 times
5.times do
  # Iterate over each LED
  leds.each do |ledpin|
    # Turn on the LED
    GPIO.digital_write(ledpin, :HIGH)
    # Delay 0.25 seconds
    sleep 0.25
    # Turn off the LED
    GPIO.digital_write(ledpin, :LOW)
  end
end
```

#### Edge Triggers
The Beaglebone can also monitor for changes on a GPIO pin.  This is called an edge trigger.  Since this is interrupt based on the Beaglebone, waiting for a change does not waste CPU cycles by constantly polling the pin.

The following trigger types are supported
- Rising: Triggered when the state goes from low to high
- Falling: Triggered when the state goes from high to low
- Both: Triggered at any change in state
- None: Triggering is disabled

These trigger types are represented by the symbols :RISING, :FALLING, :BOTH, and :NONE

This example will wait for a rising edge to continue, then output the type of edge trigger that was detected.

```ruby
# Initialize pin P9_11 in INPUT mode
GPIO.pin_mode(:P9_11, :IN)

# Wait here until a rising edge is detected
edge = GPIO.wait_for_edge(:P9_11, :RISING) => :RISING

# Output the trigger type detected
puts "Saw a #{edge} edge"
```

#### Edge Triggers in the Background
To avoid blocking while waiting for an edge trigger, the method **GPIO.run_on_edge** will run a callback when an edge trigger is detected.  This method will spawn a new thread and wait for an edge trigger in the background.  Only one of these threads may be active per pin.

This example will detect edge triggers in the background and output information when triggered.

```ruby
# Initialize pin P9_11 in INPUT mode
GPIO.pin_mode(:P9_11, :IN)

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
GPIO.run_on_edge(callback, :P9_11, :BOTH)

# This code will run immediately after the previous call, as it does not block
sleep 10

# Stop the background thread waiting for an edge trigger after 10 seconds
GPIO.stop_edge_wait(:P9_11)

# This convenience method will run the callback only on the first detected change
GPIO.run_once_on_edge(callback, :P9_11, :BOTH)

# Change the trigger detection for the specified pin
GPIO.set_gpio_edge(:P9_11, :RISING)
```

#### Shift Registers
This library will also support writing to shift registers using GPIO pins.  Create a **ShiftRegister** object by initializing it with the latch pin, clock pin, and data pin.

This example will trigger 8 pins of a shift register.

```ruby
# P9_11 is connected to the latch pin
# P9_12 is connected to the clock pin
# P9_13 is connected to the data pin

# Initialize the pins connected to shift register
GPIO.pin_mode(:P9_11, :OUT)
GPIO.pin_mode(:P9_12, :OUT)
GPIO.pin_mode(:P9_13, :OUT)

# Write value to shift register
GPIO.shift_out(:P9_11, :P9_12, :P9_13, 0b11111111)
```

### Analog Inputs
The Analog pins on the Beaglebone run at **1.8v**.  Do not provide more than 1.8v to any analog pin or risk damaging the hardware.  The header has pins available to provide a 1.8v for analog devices as well as a dedicated analog ground.  Analog pins are only capable of reading input values.

Analog pins do not require setup, and can be read at any time

#### Reading
To read the value from an analog pin, the method **AIN.read** is used.  This will return a value between 0 and 1799.

```ruby
# Read the input value in millivolts.
mv = AIN.read(:P9_33) => 1799
```

#### Waiting for Change
To wait for the value of an analog pin to change by a specified voltage, the method **AIN.wait_for_change** is used.

**AIN.wait_for_change** takes the following arguments.
- pin: The symbol of the pin to monitor
- mv_change: The amount of change in millivolts required before returning
- interval: How often to poll the value of the pin in seconds
- mv_last: (optional) The initial value to use as a point to detect change

This method returns an array containing the initial voltage, the last polled voltage, and the number of times the pin was polled.

```ruby
# Wait for 100mv of change on pin P9_33.  Poll 10 times a second
mv_start, mv_current, count = AIN.wait_for_change(:P9_33, 100, 0.1)
```

#### Waiting for Change in the Background
To avoid blocking while waiting for voltage change, the method **AIN.run_on_change** will run a callback every time the specified change is detected.  This method will spawn a new thread and wait for change in the background.  The method **AIN.run_once_on_change** is a convenience method to only be triggered once.  Only one of these threads may be active per pin.

This example waits for voltage change in the background and outputs information when change is detected.

```ruby

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
AIN.run_on_change(callback, :P9_33, 10, 0.1)

# This code will run immediately after the previous call, as it does not block
sleep 20

# Stop the background thread after 20 seconds
AIN.stop_wait(:P9_33)
```

#### Waiting for Threshold
To wait for the value of an analog pin to cross certain threshold voltages, the method **AIN.wait_for_threshold** is used.

**AIN.wait_for_threshold** takes the following arguments.
- pin: The symbol of the pin to monitor
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
# Wait for the voltage on pin P9_33 to go below 200mv or above 1600mv.
# To enter the :MID state from :HIGH or :LOW, it will have to cross the thresholds by at least 100mv.
# Poll 10 times a second
data = AIN.wait_for_threshold(:P9_33, 200, 1600, 100, 0.1) => [ 500, 150, :MID, :LOW, 53 ]

# Assign variables from array
mv_start, mv_current, state_start, state_current, count = data
```

#### Waiting for Threshold in the Background
To avoid blocking while waiting for a voltage threshold to be crossed, the method **AIN.run_on_threshold** will run a callback every time the specified change is detected.  This method will spawn a new thread and wait for change in the background.  The method **AIN.run_once_on_threshold** is a convenience method to only be triggered once.  Only one of these threads may be active per pin.

This example waits for voltage change in the background and outputs information when the specified threshold is crossed.

```ruby
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
AIN.run_on_threshold(callback, :P9_33, 200, 1600, 100, 0.1)

# This code will run immediately after the previous call, as it does not block
sleep 20

# Stop the background thread after 20 seconds
AIN.stop_wait(:P9_33)
```

### PWM
The beaglebone supports PWM (pulse width modulated) output on certain pins.  These pins output 3.3v.  The output is controlled based on frequency and duty cycle.

To initialize the pin **P9_14**, pass the symbol for that pin, the duty cycle, and the frequency in Hz to the **PWM.start** method.

This example shows how to control PWM output of a specified pin.

```ruby
# Initialize pin P9_14 for PWM output
# This pin will now output a square wave at 10Hz with a 90% duty cycle.
PWM.start(:P9_14, 90, 10)

# Change frequency to 20Hz.  Duty cycle remains 90%
PWM.set_frequency(:P9_14, 20)

# Change the duty cycle to 50%
PWM.set_duty_cycle(:P9_14, 50)

# Adjust the frequency by setting the period in nanoseconds.
PWM.set_period_ns(:P9_14, 31250000)

# Adjust the duty cycle by setting the period in nanoseconds.
PWM.set_duty_cycle_ns(:P9_14, 31250000)

# Invert the output signal
PWM.set_polarity(:P9_14, :INVERTED)

# Stop the output signal
PWM.stop(:P9_14)

# Resume the output signal
PWM.run(:P9_14)

# Disable the output signal
PWM.disable_pwm_pin(:P9_14)
```

### UART
The beaglebone has a number of UART devices.  These operate in TTL mode at 3.3v.  Do not provide more than 3.3v to the pins or risk damaging the hardware.

Please note, UART3 does not have an RX pin, and UART5 is only available if the HDMI device tree is not enabled.

To initialize the UART device **UART1**, pass the symbol for that device and the speed to the **UART.setup** method.

```ruby
# Initialize the pins for device UART1 into UART mode.
UART.setup(:UART1, 9600)

# Change the speed of a UART device by calling #set_speed
UART.set_speed(:UART1, 115200)

# Disable UART device
UART.disable(:UART1)
```

#### UART Writing
Writing to a UART device is accomplished by calling the **UART.write** or **UART.writeln** methods
```ruby
# Initialize the pins for device UART1 into UART mode.
UART.setup(:UART1, 9600)

# Write data to a UART1
UART.write(:UART1, "DATA DATA DATA!")

# Write data to UART1 followed by a line feed
UART.writeln(:UART1, "A line feed follows")
```

#### UART Reading
There are many methods available for reading from UART devices.  These are blocking methods and will not return until the requested is available.

```ruby
# Initialize the pins for device UART1 into UART mode.
UART.setup(:UART1, 9600)

# Read one character from UART1
c = UART.readchar(:UART1) => "X"

# Read 10 characters from UART1
str = UART.readchars(:UART1, 10) => "0123456789"

# Read a line from UART1
line = UART.readline(:UART1) => "All the text up until the linefeed"
```

#### UART Reading and Iterating
Data read from the UART device may be iterated with the following methods.  These are blocking methods and will run until the loop is broken.

```ruby
# Initialize the pins for device UART1 into UART mode.
UART.setup(:UART1, 9600)

# Run block on every character read from UART1
UART.each_char(:UART1) { |c| puts c }

# Run block on every 5 character read from UART1
UART.each_char(:UART1, 5) { |str| puts str }

# Run block on each line read from UART1
UART.each_line(:UART1) { |line| puts line }
```

#### UART Reading and Iterating in the Background
Data read from the UART device may be iterated in the background with the following methods.  The data read is passed to the specified callback.  These method will spawn a new thread and wait for data in the background.  Only one of these threads may be active per pin.

This example shows various methods of reading and processing data read from UART1 in the background.

```ruby
# Initialize the pins for device UART1 into UART mode.
UART.setup(:UART1, 9600)

# Define the callback to be run.  It takes 3 arguments
# uart: the UART device that triggered the callback
# data: the data read from the UART
# count: how many times this was triggered
callback = lambda { |uart, data, count| puts "[#{uart}:#{count}] #{data}" }

# Run callback for every character read
UART.run_on_each_char(callback, :UART1)

# Run callback for every 3 characters read
UART.run_on_each_chars(callback, :UART1, 3)

# Run callback for every line read
UART.run_on_each_line(callback, :UART1)

# Run callback once after a character is read
UART.run_once_on_each_char(callback, :UART1)

# Run callback once after 3 characters are read
UART.run_once_on_each_chars(callback, :UART1, 3)

# Run callback once after reading a line
UART.run_once_on_each_line(callback, :UART1)

# Stop the currently running background thread
UART.stop_read_wait(:UART1)
```

### I2C
The beaglebone has a number of I2C devices.  These operate at 3.3v.  Do not provide more than 3.3v to the pins or risk damaging the hardware.

To initialize the I2C device **I2C2**, pass the symbol for that device to the **I2C.setup** method.

```ruby
# Initialize I2C device I2C2
I2CDevice.setup(:I2C2)
```

#### I2C Writing
To write to an I2C device, the method **I2C.write** is used.

**I2C.write** takes the following arguments.
- i2c: symbol of the I2C device to write to
- address: address of slave device
- data: data to write

#### I2C Reading
To read from an I2C device, the method **I2C.read** is used.

**I2C.read** takes the following arguments.
- i2c: symbol of the I2C device to read from
- address: address of slave device
- bytes: bytes to read
- register: (optional) register to start reading from

#### LSM303DLHC Example

This example communicates with an [LSM303DLHC](https://www.adafruit.com/products/1120) Accelerometer/Compass/Thermometer device.

```ruby
# Initialize I2C device I2C2
I2CDevice.setup(:I2C2)

# Put compass into continuous conversation mode
I2C.write(:I2C2, 0x1e, [0x02, 0x00].pack("C*"))

# Enable temperatuer sensor, 15hz register update
I2C.write(:I2C2, 0x1e, [0x00, 0b10010000].pack("C*") )

# Delay for the settings to take effect
sleep(0.1)

# Read axis data.  It is made up of 3 big endian signed shorts starting at register 0x03
raw = I2C.read(:I2C2, 0x1e, 6, [0x03].pack("C*"))

# Coordinates are big endian signed shorts in x,z,y order
x,z,y = raw.unpack("s>*")

# Calculate angle of degrees from North
degrees = (Math::atan2(y, x) * 180) / Math::PI
degrees += 360 if degrees < 0

# Read 2 byte big endian signed short from temperature register
raw = I2C.read(:I2C2, 0x1e, 2, [0x31].pack("C*"))

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
I2C.disable(:I2C2)
```

### SPI
The beaglebone has a number of SPI devices.  These operate at 3.3v.  Do not provide more than 3.3v to the pins or risk damaging the hardware.

To initialize the SPI device **SPI0**, pass the symbol for that device to the **SPI.setup** method.

The optional arguments are also available
- mode: SPI mode, :SPI_MODE_0 through :SPI_MODE_3
- speed: Speed of the SPI device
- bpw: Bits per word

```ruby
# Initialize SPI device SPI0
SPI.setup(:SPI0, :SPI_MODE_0, 1000000, 8)

# You can change SPI  with the methods below.

# Set mode of SPI0
SPI.set_mode(:SPI0, :SPI_MODE_3)

# Set speed of SPI0
SPI.set_speed(:SPI0, 100000)

# Set bits per word of SPI0
SPI.set_bpw(:SPI0, 10)

# Disable SPI device
SPI.disable(:SPI0)
```

#### SPI Data Transfer
To transfer data to an SPI device, the method **SPI.xfer** is used.

**SPI.xfer** takes the following arguments
- spi: symbol for the SPI device to use
- tx_data: data to transmit
- readbytes: (optional) number of bytes to read, otherwise it sizeof tx_data is used
- speed: (optional) speed of the transfer
- delay: (optional) delay
- bpw: (optonal) bits per word

**SPI.xfer** returns the data read from the SPI device.

#### MCP3008 Example
This example communicates with an [MCP3008](http://www.adafruit.com/products/856) ADC device.

```ruby
# Initialize SPI device SPI0
SPIDevice.new(:SPI0)

# communicate with MCP3008
# byte 1: start bit
# byte 2: single(1)/diff(0),3 bites for channel, null pad
# byte 3: don't care
# Read value from channel 0
raw = SPI.xfer(:SPI0, [ 0b00000001, 0b10000000, 0].pack("C*"))

# Split data read into an array of characters
data = raw.unpack("C*")

# The returned data is stored starting at the last two bits of the second byte
val = ((data[1] & 0b00000011) << 8 ) | data[2]

# Display the value of channel 0
puts "Value of channel 0: #{val}"

# Read value from channel 1
raw = SPI.xfer(:SPI0, [ 0b00000001, 0b10010000, 0].pack("C*"))

# Split data read into an array of characters
data = raw.unpack("C*")

# The returned data is stored starting at the last two bits of the second byte
val = ((data[1] & 0b00000011) << 8 ) | data[2]

# Display the value of channel 1
puts "Value of channel 1: #{val}"

# Disable SPI device
SPI.disable(:SPI0)
```
