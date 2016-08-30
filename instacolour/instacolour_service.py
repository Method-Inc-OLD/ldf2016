
import os
import logging
import sys

from flask import Flask, jsonify
from flask_restful import Api
from flask import render_template, send_from_directory
from flask_cors import CORS, cross_origin

import ConfigParser
import utils
import constants


""" config """

config_parser = ConfigParser.RawConfigParser()
config_parser.read(utils.get_full_file_path(constants.config_file))

""" setup app """
app = Flask(__name__, static_url_path='/static/')
api = Api(app)

""" constants """

basedir = os.path.abspath(os.path.dirname(__file__))
static_folder = os.path.join(app.root_path, 'static')

"""
Access-Control-Allow-Origin
https://flask-cors.readthedocs.io/en/latest/
"""
# cors = CORS(app, resources={r"/*": {"origins": "*"}})
# cors = CORS(app)
#cors = CORS(app, resources={r"/api/*": {"origins": "*"}})
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

api.add_resource(handlers.Authenticate,
                 '/',
                 '/authenticate')

api.add_resource(handlers.InstagramOAuthHandler,
                 '/',
                 '/instagramauth')

api.add_resource(handlers.ColourClustersHandler,
                 '/api/colourclusters')

api.add_resource(handlers.VibrantColoursHandler,
                 '/api/vibrantcolours')

api.add_resource(handlers.ColouriseHandler,
                 '/api/colourise')

api.add_resource(handlers.NextImageHandler,
                 '/api/nextimage')

api.add_resource(handlers.AllImagesHandler,
                 '/api/allimages')

api.add_resource(handlers.SimilarImagesHandler,
                 '/api/similarimages')

api.add_resource(handlers.DominateColoursHandler,
                 '/api/dominatecolours')

api.add_resource(handlers.PaletteGridHandler,
                 '/api/palettegrid')


# http://www.davidadamojr.com/handling-cors-requests-in-flask-restful-apis/
@app.after_request
def after_request(response):
    #response.headers.add('Access-Control-Allow-Origin', '*')
    response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization,X-Requested-With')
    response.headers.add('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE')
    return response

if __name__ == '__main__':
    port = int(os.environ.get("PORT", 5000))
    app.run(host='0.0.0.0', port=port, debug=True)