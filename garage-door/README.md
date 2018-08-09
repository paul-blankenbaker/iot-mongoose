# A Mongoose OS (ESP32) Garage Door Opener

## Overview

This is a relatively simple application that allows a user to remotely
control a garage door by "pressing" the garage door button using a
relay connected to an ESP32 device.

**Security Warning** The default settings for this project (and
probably most Mongoose projects) are not secure!  Anyone that gains
access to your WIFI network will be able to trigger the relay once
they find the device. Refer to the Mongoose Security page
(https://mongoose-os.com/docs/userguide/security.md) for details on
enabling encryption, changing the HTTP port and requiring
authentication.

## How to install this app

- Install [mos tool](https://mongoose-os.com/software.html)

- Copy *conf.template.json* to conf1.NAME.json for your device, edit the
  new file and then copy *conf1.NAME.json* to *fs/conf1.json*. NOTE: This
  step is optional, but it allows you to customize your settings
  without using the standard `mos config-set` commands all of the
  time.

- Build and flash the project to your ESP32 device. If you do not have
  docker, drop the *--local* option for a cloud build. If you have a
  different device change the architecture argument (like: *--arch
  esp8266*), however be aware that this code has not been tested on
  other devices.

```sh
export MOS_PORT=/dev/ttyUSB0
mos build --arch esp32 --local && mos flash
```

- Open up the application in a browser (it should render the
  index.html document found under the fs directory). If AP mode is
  enabled, you should find it at http://192.168.4.1/. If you have the
  WIFI configured to connect to your local network, substitute its
  address for the 192.168.4.1. You may need to run `mos console` to
  find the local address if you did not assign a static address.

## Updating

This build includes the *ota-http-server* library. This means that you
should be able to update the software (firmware) remotely over the
network. This is particularily useful if you have mounted the device
in a location that makes connecting a USB cable difficult.

```sh
export MOS_IP=192.168.4.1
mos build --arch esp32 --local
curl -v -i -F filedata=@build/fw.zip http://${MOS_IP}/update
```

This will not work for the initial install. It only works for updating
the software.

NOTE: This is a security issue and requires a lot of trust in the
devices and people on your network. To disable this, remove the
*ota-http-server* library from the *mos.yml* file.

## Different Architectures

This application has been built, deployed and tested on a ESP32 board
from Adafruit. When building for alternate architectures, you may get
errors if you do not remove the *deps* and *build* directories before
building.

```sh
rm -fr deps build
mos build --arch esp8266 --local
```

## Application Configuration

Application specific settings are found in the "app" section of
the JSON configuration file *conf1.template.json*. The defaults are:

```json
{
 "app": {
  "relayPin": 13,
  "relayUpState": false,
  "relayDownMsecs": 200
 }
}
```

Unfortunately, comments can not be placed in the configuration file. Here is the definition of each setting that you can adjust:

| Key            |                                                            |
| -------------- | -----------------------------------------------------------|
| relayPin       | The GPIO pin on your board that is connected to the relay. NOTE: The default is 13 which may not be what you want in your final product. Often 13 is tied to an on-board status LED, which is nice for initial testing, but you may or may not want the blinking LED on your final install. The choice of the pin can be critical. You want to make sure that you select a GPIO pin that is not used for multiple purposes or does not start in a well known state at boot time (sometimes GPIO pins can be used for serial port lines at initial boot and then repurposed once the software is loaded - you must avoid those pins). Pins 13, 27, 33, 15, 32 and 14 on the [Adafruit HUZZAH32](https://learn.adafruit.com/adafruit-huzzah32-esp32-feather/pinouts) are all probably usable. |
| relayUpState   | State to set the GPIO pin to so the relay remains open (keeps garage button in unpressed up state). |
| relayDownMsecs | How many milliseconds to close the relay in an attempt to emulate someone pressing the garage door button. |
