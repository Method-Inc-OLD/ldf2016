
import os
import logging
import sys

from flask import Flask, jsonify
from flask_restful import Api
from flask import render_template, send_from_directory
from flask.ext.cors import CORS

import ConfigParser
import utils
import constants


""" config """

config_parser = ConfigParser.RawConfigParser()
config_parser.read(utils.get_full_file_path(constants.config_file))

""" setup app """
app = Flask(__name__, static_url_path='/static/')
api = Api(app)

"""
Access-Control-Allow-Origin
https://flask-cors.readthedocs.io/en/latest/
"""
CORS(app)

import handlers

@app.errorhandler(handlers.InvalidUsage)
def handle_invalid_usage(error):
    response = jsonify(error.to_dict())
    response.status_code = error.status_code
    return response

api.add_resource(handlers.DefaultHandler,
                 '/',
                 '/index')

api.add_resource(handlers.Authenticate,
                 '/',
                 '/authenticate')

api.add_resource(handlers.InstagramOAuthHandler,
                 '/',
                 '/instagramauth')


# http://www.davidadamojr.com/handling-cors-requests-in-flask-restful-apis/
@app.after_request
def after_request(response):
  response.headers.add('Access-Control-Allow-Origin', '*')
  response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization')
  response.headers.add('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE')
  return response

if __name__ == '__main__':
    port = int(os.environ.get("PORT", 5000))
    app.run(host='0.0.0.0', port=port, debug=True)