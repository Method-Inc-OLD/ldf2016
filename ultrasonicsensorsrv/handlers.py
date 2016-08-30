
import flask
import io
from flask import request, jsonify, render_template, Response, send_file
from flask_restful import Resource, reqparse
import json
import logging
import datetime
import httplib2
import urllib
import math


""" Error handler """


class InvalidUsage(Exception):
    status_code = 400

    def __init__(self, message, status_code=None, payload=None):
        Exception.__init__(self)
        self.message = message
        if status_code is not None:
            self.status_code = status_code

        self.payload = payload

    def to_dict(self):
        rv = dict(self.payload or ())
        rv['message'] = self.message
        return rv