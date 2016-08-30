
import threading
import time


class MockUltrasonicProcess(object):

    def __init__(self):
        self.running = False
        self._distance = 0.0

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
        dis = self._distance

        self._distance -= 10

        if self._distance < 1.0:
            self._distance = 200.0

        return dis

    def run_loop(self):

        while self.running:
            time.sleep(0.5)

