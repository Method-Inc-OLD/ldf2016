
import ConfigParser
import os
from apscheduler.schedulers.blocking import BlockingScheduler
import requests
import json
import utils
import datetime


basedir = os.path.abspath(os.path.dirname(__file__))

sched = BlockingScheduler()

@sched.scheduled_job('cron', day_of_week='mon-sun', minute=10)
def timed_job():

    start_time = datetime.datetime.now()
    utils.Logger.info('Running timed_job - starting {}'.format(start_time))

    utils.Logger.info('Running timed_job - TODO - implement task')

    end_time = datetime.datetime.now()
    et = end_time - start_time
    utils.Logger.info('Finished timed_job, job took {} seconds'.format(et.seconds))

sched.start()