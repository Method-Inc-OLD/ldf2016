
import threading
import time
import RPi.GPIO as GPIO


class UltrasonicProcess(object):

    def __init__(self):
        self.running = False
        self._distance = 0.0

        self.GPIO_TRIGGER = 23
        self.GPIO_ECHO = 24

        self.thread = None

    def start(self):
        if self.running:
            return

        self.running = True

        self.thread = threading.Thread(target=self.run_loop)
        # self.thread.daemon = True
        self.thread.start()

    def stop(self):
        self.running = False

    @property
    def distance(self):
        return self._distance

    @staticmethod
    def cleanup():
        GPIO.cleanup()

    def run_loop(self):
        print("starting ultrasonic run loop")

        GPIO.setmode(GPIO.BCM)

        # Set pins as output and input
        GPIO.setup(self.GPIO_TRIGGER, GPIO.OUT)  # Trigger
        GPIO.setup(self.GPIO_ECHO, GPIO.IN)  # Echo

        # Set trigger to False (Low)
        GPIO.output(self.GPIO_TRIGGER, False)

        while self.running:
            self._distance = self.measure_average()
            time.sleep(1)

        GPIO.cleanup()

    def measure_average(self):
        # This function takes 3 measurements and
        # returns the average.
        distance1 = self.measure()
        time.sleep(0.1)
        distance2 = self.measure()
        time.sleep(0.1)
        distance3 = self.measure()
        distance = distance1 + distance2 + distance3
        distance /= 3
        return distance

    def measure(self):
        # This function measures a distance
        GPIO.output(self.GPIO_TRIGGER, True)
        time.sleep(0.00001)
        GPIO.output(self.GPIO_TRIGGER, False)
        start = time.time()

        while GPIO.input(self.GPIO_ECHO) == 0:
            start = time.time()

        while GPIO.input(self.GPIO_ECHO) == 1:
            stop = time.time()

        elapsed = stop - start
        distance = (elapsed * 34300) / 2

        return distance

if __name__ == '__main__':
    us_process = UltrasonicProcess()
    us_process.start()
    print "starting"
    for _ in range(1,10):
        time.sleep(2)
        print "distance {}".format(us_process.distance)

    us_process.stop()
    print "exiting"
