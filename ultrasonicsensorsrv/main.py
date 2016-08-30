#!/usr/bin/python

import subprocess
import sys
import os
import signal
import ultrasonic_process
from sys import platform


def get_python_script_path():
    return "{}/{}".format(os.path.dirname(os.path.realpath('__file__')), "us_service.py")


def get_data_file_path():
    return "{}/{}".format(os.path.dirname(os.path.realpath('__file__')), "process_id.dat")


def kill_process():
    if not os.path.isfile(get_data_file_path()):
        return

    with open(get_data_file_path(), "r") as f:
        process_id = f.read()
        try:
            os.kill(int(process_id), signal.SIGKILL)
        except Exception as e:
            print "FAILED TO KILL PROCESS {}".format(e.message)

    os.remove(get_data_file_path())


def start_process():
    process = subprocess.Popen([sys.executable, get_python_script_path()])
    with open(get_data_file_path(), "w") as f:
        f.write(str(process.pid))

if __name__ == '__main__':
    print __file__

    if platform != "darwin":
        ultrasonic_process.UltrasonicProcess.cleanup()

    kill_process()

    if len(sys.argv) == 2:
        command = str(sys.argv[1])

        if command.lower() == "start":
            start_process()