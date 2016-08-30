
## Websockets
sudo pip install git+https://github.com/dpallot/simple-websocket-server.git

## Ultrasonic Sensor
http://www.raspberrypi-spy.co.uk/2012/12/ultrasonic-distance-measurement-using-python-part-1/

### Sanity check with GPIO
https://thepihut.com/blogs/raspberry-pi-tutorials/27968772-turning-on-an-led-with-your-raspberry-pis-gpio-pins

## Raspberry Pi setup 
Setup hostname for Pi (.local) 
http://www.howtogeek.com/167190/how-and-why-to-assign-the-.local-domain-to-your-raspberry-pi/

## Logging onto the Raspberry Pi
$ ssh pi@instacolour1.local
password: raspberry

### Copying to the PI
scp -rp ultrasonicsensorsrv pi@instacolour1.local:/home/pi/

$ chmod 755 launcher.sh

## Flask Socket
https://github.com/miguelgrinberg/Flask-SocketIO
http://blog.miguelgrinberg.com/post/easy-websockets-with-flask-and-gevent
https://flask-socketio.readthedocs.io/en/latest/

## Stopping going to sleep
http://www.raspberry-projects.com/pi/pi-operating-systems/raspbian/gui/disable-screen-sleep

## Kiosk mode
https://github.com/elalemanyo/raspberry-pi-kiosk-screen

https://www.danpurdy.co.uk/web-development/raspberry-pi-kiosk-screen-tutorial/

## Alternative browsers 
http://computers.tutsplus.com/articles/how-to-install-alternative-web-browsers-on-the-raspberry-pi--mac-60717
Installing Chromium on Jessie 
https://www.raspberrypi.org/forums/viewtopic.php?t=121195

## PyGame 
http://www.pygame.org/hifi.html
https://www.raywenderlich.com/24252/beginning-game-programming-for-teens-with-python
https://pythonprogramming.net/pygame-python-3-part-1-intro/

## Helper commands 

Finding and killing the process 
$ ps aux | grep ultra 
$ sudo kill -9 PID