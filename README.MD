# London Design Festival 2016 

## Description 
TODO...


## Projects 
### PixelExplode 
WebGL experiments to manipulate pixels 

### instacolour
Instagram Crawler 

#### Increasing memory size
https://www.raspberrypi.org/forums/viewtopic.php?f=81&t=60024

$ sudo raspi-config

#### Overclocking 
https://www.raspberrypi.org/forums/viewtopic.php?f=66&t=138123

$ sudo nano /boot/config.txt

arm_freq=1350
over_voltage=5
gpu_freq=550

# sdram overclock
sdram_freq=550
sdram_schmoo=0x02000020
over_voltage_sdram_p=6
over_voltage_sdram_i=4
over_voltage_sdram_c=4

## Fixing resolution issues 
https://www.raspberrypi.org/forums/viewtopic.php?f=67&t=25933 // to find group and mode 
http://weblogs.asp.net/bleroy/getting-your-raspberry-pi-to-output-the-right-resolution // to set the above values in the config 

pi@instacolour1:~ $ tvservice -m CEA
Group CEA has 2 modes:
           mode 4: 1280x720 @ 60Hz 16:9, clock:74MHz progressive 
  (prefer) mode 16: 1920x1080 @ 60Hz 16:9, clock:148MHz progressive 
pi@instacolour1:~ $ tvservice -m DMT
Group DMT has 1 modes:
           mode 4: 640x480 @ 60Hz 4:3, clock:25MHz progressive 

## VNC (Remote Login)
https://www.raspberrypi.org/documentation/remote-access/vnc/
http://www.howtogeek.com/141157/how-to-configure-your-raspberry-pi-for-remote-shell-desktop-and-file-transfer/all/
https://www.raspberrypi.org/documentation/remote-access/vnc/mac.md

## To run Processing from Command line: 
$ export DISPLAY=":0" OR export DISPLAY=:0
$ processing-java --output=/tmp/processing --force --sketch=Instasketch2 --run
processing-java --output=/tmp/processing --force --sketch=Instasketch2 --present --no-java


