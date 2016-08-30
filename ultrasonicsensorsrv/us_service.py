
import os
import logging
import sys
from sys import platform

from flask import Flask, jsonify
from flask import render_template, send_from_directory
from flask_cors import CORS, cross_origin
from flask_socketio import SocketIO, emit

""" ultrasonic process """
if platform == "darwin":
    print "instantiating MockUltrasonicProcess"
    from mock_ultrasonic_process import MockUltrasonicProcess
    ultrasonic_process = MockUltrasonicProcess()

if platform != "darwin":
    print "instantiating UltrasonicProcess"
    from ultrasonic_process import UltrasonicProcess
    ultrasonic_process = UltrasonicProcess()

""" setup app """
app = Flask(__name__, static_url_path='/static/')
app.config['SECRET_KEY'] = 'colouringtheworld'

""" socket """

socketio = SocketIO(app)

""" constants """

basedir = os.path.abspath(os.path.dirname(__file__))
static_folder = os.path.join(app.root_path, 'static')

"""
Access-Control-Allow-Origin
https://flask-cors.readthedocs.io/en/latest/
"""
cors = CORS(app)

import handlers


@app.errorhandler(handlers.InvalidUsage)
def handle_invalid_usage(error):
    response = jsonify(error.to_dict())
    response.status_code = error.status_code
    return response


@app.route('/')
def root():
    return app.send_static_file('index.html')


@app.route('/<path:filename>')
def assets(filename):
  return send_from_directory(static_folder, filename)


@socketio.on('reading', namespace='/sense')
def wssemse_reading_message(message):
    emit('reading', {'data': ultrasonic_process.distance})


@socketio.on_error(namespace='/sense')
def wssense_on_error(e):
    print('An error has occurred: ' + str(e))


@socketio.on('connect', namespace='/sense')
def wssense_connect():
    #emit('message', {'data': 'Connected'})
    #emit('reading', {'data': 1.0})
    print('Client connected')


@socketio.on('disconnect', namespace='/sense')
def wssense_disconnect():
    print('Client disconnected')


# http://www.davidadamojr.com/handling-cors-requests-in-flask-restful-apis/
@app.after_request
def after_request(response):
    response.headers.add('Access-Control-Allow-Origin', '*')
    response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization,X-Requested-With')
    response.headers.add('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE')
    return response

if __name__ == '__main__':
    ultrasonic_process.start()

    port = int(os.environ.get("PORT", 5000))
    socketio.run(app, host='0.0.0.0', port=port, debug=True)

