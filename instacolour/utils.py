import os
import socket
import logging
import sys

class Logger(object):
    log = None

    @staticmethod
    def init_logging():
        if Logger.log is not None:
            return Logger.log

        """ setup logging """
        Logger.log = logging.getLogger(__name__)
        out_hdlr = logging.StreamHandler(sys.stdout)
        out_hdlr.setFormatter(logging.Formatter('%(asctime)s %(message)s'))
        out_hdlr.setLevel(logging.INFO)
        Logger.log.addHandler(out_hdlr)
        Logger.log.setLevel(logging.INFO)

    @staticmethod
    def info(message=""):
        Logger.init_logging()
        Logger.log.info(message)

    @staticmethod
    def warning(message=""):
        Logger.init_logging()
        Logger.log.warning(message)

    @staticmethod
    def error(message=""):
        Logger.init_logging()
        Logger.log.error(message)

def get_full_file_path(file_path):
    return "{}/{}".format(os.path.dirname(os.path.realpath('__file__')), file_path)


def is_connected(remote_server='www.google.com'):
    try:
        # see if we can resolve the host name -- tells us if there is
        # a DNS listening
        host = socket.gethostbyname(remote_server)
        # connect to the host -- tells us if the host is actually
        # reachable
        s = socket.create_connection((host, 80), 2)
        return True

    except:
        pass

    return False