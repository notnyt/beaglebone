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
    - [Shift Registers](#shift-registers)
  - [Analog Inputs](#analog-inputs)
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

#### LEDs

#### Shift Registers

### Analog Inputs

### PWM

### UART

### I2C

### SPI

## Pin Reference

## License
Copyright (c) 2014 Rob Mosher.  Distributed under the GPL-v3 License.  See LICENSE for more information.
