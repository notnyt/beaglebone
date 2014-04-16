# Beaglebone Ruby Library
Documentation is in progress and will be completed shortly.
Examples are available in the example directory.

**Table of Contents**
- [Overview](#overview)
- [Installation](#installation)
  - [Installing Ruby](#installing-ruby)
  - [Installing Beaglebone Gem](#installing-gem)
- [Usage](#usage)
- [Reference](#reference)
- [Examples](#examples)
  - [GPIO](#gpio)
    - [LEDs](#leds)
    - [Reading](#reading)
    - [Writing](#writing)
    - [Edge Triggers](#edge-triggers)
    - [Shift Registers](#shift-registers)
  - [Analog Inputs](#analog-inputs)
    - [Reading](#reading)
    - [Waiting for Change](#waiting-for-change)
    - [Waiting for Threshold](#waiting-for-threshold)
  - [PWM](#pwm)
  - [UART](#uart)
  - [I2C](#i2c)
  - [SPI](#spi)
- [Pin Reference](#pin-reference)
- [License](#license)

## Overview
The purpose of this library is to provide easy access to all of the IO features of the Beaglebone in a highly flexible programming language (Ruby).  This gem includes object oriented methods as well as procedural methods, so those familiar with Bonescript, the Adafruit Python library, or Arduino programming will be familiar with the syntax.  This was developed and tested on a Beaglebone Black running the official Debian images.  The code will need to be executed as root in order to function properly and utilize all of the features of the Beaglebone.

## Installation
### Installing Ruby
Ruby and Rubygems are required to use this gem.  To install, simply run the command below.  This will install Ruby 1.9.1 which includes Rubygems.

```
sudo apt-get install ruby
```

### Installing Gem
Once Ruby is installed installed, you can install the gem by running the command below.

```
sudo gem install beaglebone
```

## Usage
To use this gem, you need to require it in your Ruby code.  An example follows

```ruby
#!/usr/bin/env ruby
require 'beaglebone'
include Beaglebone
```

## Rereference
A full reference is available [here](http://rubydoc.info/gems/beaglebone/1.0.5/frames).

## Examples
These examples will show the various ways to interact with the Beaglebones IO hardware.  They will need to be executed as root in order to function correctly.

### GPIO
The GPIO pins on the Beaglebone run at 3.3v.  Do not provide more than this voltage to any pin or you will risk damaging the hardware.

GPIO pins have two modes, input and output.  These modes are represented by the symbols *:IN* and *:OUT*.

To initialize the pin *P9_11*, we pass the symbol for that pin and the mode to the *GPIOPin* constructor.

```ruby
# Initialize pin P9_11 in INPUT mode
p9_11 = GPIOPin.new(:P9_11, :IN)

# Initialize pin P9_12 in OUTPUT mode
p9_12 = GPIOPin.new(:P9_12, :OUT)

# Change pin P9_12 to INPUT mode
p9_12.set_gpio_mode(:IN)

# Disable pin P9_12
p9_12.disable_gpio_pin
# Unassign to prevent re-use
p9_12 = nil
```

#### Writing
To set the state of a GPIO pin, the method *#digital_write* is used.  The states we can set are *:HIGH* to provide 3.3v and *:LOW* to provide ground.

```ruby
# Initialize pin P9_12 in OUTPUT mode
p9_12 = GPIOPin.new(:P9_12, :OUT)

# Provide 3.3v on pin P9_12
p9_12.digital_write(:HIGH)

# Provide ground on pin P9_12
p9_12.digital_write(:LOW)
```

#### Reading
To read the current state of a GPIO pin, the method *#digital_read* is used.  It will return the symbol *:HIGH* or *:LOW* depending on the state of the pin.

```ruby
# Initialize pin P9_11 in INPUT mode
p9_11 = GPIOPin.new(:P9_11, :IN)

# Get the current state of P9_11
state = p9_11.digital_read => :LOW
```

#### LEDs
The on-board LEDs are addressable via GPIO output.  They are available on pins *:USR0* through *:USR3*.  This example will blink each LED in order 5 times.

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

#### Shift Registers
This library will also support writing to shift registers using GPIO pins.  We create a *ShiftRegister* object by initializing it with the latch pin, clock pin, and data pin.

```ruby
# P9_11 is connected to the latch pin
# P9_12 is connected to the clock pin
# P9_13 is connected to the data pin

# Initialize shift register
shiftreg = ShiftRegister.new(:P9_11, :P9_12, :P9_13)

# Write value to shift register
shiftreg.shiftout(0b11111111)
```


### Analog Inputs

### PWM

### UART

### I2C

### SPI

## Pin Reference

## License
Copyright (c) 2014 Rob Mosher.  Distributed under the GPL-v3 License.  See LICENSE for more information.
