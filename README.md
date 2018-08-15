# iot-mongoose

This repository contains notes and experiments involving [Mongoose
OS](https://mongoose-os.com/) on embedded devices (like the
[ESP32](https://www.espressif.com/en/products/hardware/esp32/overview)).

# mos Tips

The *mos* command is used for building, deploying and
diagnostics. Here are some handy things to remember.

## MOS_PORT

The *MOS_PORT* environment variable can be set so that you do not need
to specify it all of the time when running the various *mos* commands.

```sh
export MOS_PORT=/dev/ttyUSB0
```

If your device is configured for network access and RPC over
WebSockets, you can set your *MOS_PORT* so that many of the commands
(including the *mos* IDE) will work remotely:

```sh
export MOS_PORT=ws://10.8.68.44/rpc
```

Unfortunately, as far as I can tell, the ```mos console``` command
does not work remotely (*MOS_PORT* should be set to a USB device, not
a WebSocket).

## List *mos* Commands

```sh
mos --help
```

## List *mos* Commands and Options

```sh
mos --helpfull 2>&1 | less
```

## Start *mos* IDE (User Interface)

```sh
mos ui
```

## Console

```sh
mos console
```

NOTE: As far as I can tell this requires a direct USB connection to an
ESP32 (no remote access).

## Build and Deploy

Cloud Build (requires Internet)

```sh
mos build
```

Local Build (requires ability to run Docker)

```sh
mos build --local
```

Deploy over USB connection:

```sh
mos flash
```

Deploy over the air (using a network connection). The project must
include supporting libraries for this to work (*ota-http-server*). The
firmware file should be found at *build/fw.zip* after a successful
build.

```sh
export MOS_IP=192.168.4.1
curl -v -i -F filedata=@build/fw.zip http://${MOS_IP}/update
```

## File Management

```sh
mos ls -l
mos get index.html > /tmp/index.html
mos put /tmp/index.html trash.html
mos rm trash.html
```

## RPC

```sh
mos call RPC.List
mos call Config.Get
mos call Sys.GetInfo
mos call Sys.Reboot
```
