# Beaglebone Ruby Library
<font color='red'>
Documentation is in progress and will be completed shortly.
Examples are available in the example directory.
</font>

**Table of Contents**
- [Overview](#overview)
- [Installation](#installation)
  - [Installing Ruby](#installing-ruby)
  - [Installing Beaglebone Gem](#installing-gem)
- [Usage](#usage)
- [Examples](#examples)
  - [GPIO](#gpio)
  - [Shift Registers](#shift-registers)
  - [Analog Inputs](#analog-inputs)
  - [PWM](#pwm)
  - [UART](#uart)
  - [I2C](#i2c)
  - [SPI](#spi)
- [Pin Reference](#pin-reference)

## Overview
The purpose of this library is to provide easy access to all of the IO features of the Beaglebone in a highly flexible programming language (Ruby).  This gem includes object oriented methods as well as procedural methods, so those familiar with Bonescript, the Adafruit Python library, or Arduino programming will be familiar with the syntax.  This was developed and tested on a Beaglebone Black running the official Debian images.  The code will need to be executed as root in order to function properly and utilize all of the features of the Beaglebone.

## Installation
### Installing Ruby
Ruby and Rubygems are required to use this gem.  To install, simply run the command below.  This will install Ruby 1.9.1 which includes Rubygems.

```
sudo apt-get install ruby
```

### Installing Gem
Once installed, you can install the gem by running

```
sudo gem install beaglebone
```

## Usage
To use this gem, you need to require it in your ruby code.  An example follows

```
#!/usr/bin/env ruby
require 'beaglebone'
include Beaglebone
```

## Examples

### GPIO

#### Shift Registers

### Analog Inputs

### PWM

### UART

### I2C

### SPI

## Pin Reference
