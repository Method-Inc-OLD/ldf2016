
import flask
from flask import request, jsonify, render_template, Response
from flask_restful import Resource, reqparse
import json
import logging
import datetime
import httplib2
import urllib
import ConfigParser
import utils
import constants
from data_manager import DataManager

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

""" base class """

class BaseHandler(Resource):

    config_parser = None
    data_manager = None

    def get_data_manager(self):
        if self.data_manager is None:
            self.data_manager = DataManager()

        return self.data_manager

    def get_config(self, key):
        if self.config_parser is None:
            self.config_parser = ConfigParser.RawConfigParser()
            self.config_parser.read(utils.get_full_file_path(constants.config_file))

        return self.config_parser.get(constants.config_section, key)

    def fetch_instagram_access_token(self, code):

        h = httplib2.Http()

        post_data = {'client_id': self.get_config('instagram_client_id'),
                     'client_secret': self.get_config('instagram_client_secret'),
                     'grant_type': 'authorization_code',
                     'redirect_uri': self.get_config('instafram_redirect_url'),
                     'code': code}

        headers = {'Content-type': 'application/x-www-form-urlencoded'}

        uri = "https://api.instagram.com/oauth/access_token"

        utils.Logger.info("requesting oauth token {}".format(uri))

        resp, content = h.request(uri=uri,
                                  method="POST",
                                  body=urllib.urlencode(post_data),
                                  headers=headers)

        utils.Logger.info("received response for access_token request {}".format(content))

        return json.loads(content)



""" default handler """


class DefaultHandler(Resource):

    def get(self):
        return "Hello world"


    def post(self):
        return "Hello world"


""" """

class Authenticate(BaseHandler):

    request_parser = reqparse.RequestParser()
    request_parser.add_argument('service', type=str)

    def get(self):
        args = self.request_parser.parse_args()

        if "service" not in args or args["service"] is None:
            raise InvalidUsage('Missing or invalid parameters', status_code=400)

        if args["service"].lower() == "instagram":
            auth_url = "https://api.instagram.com/oauth/authorize/?client_id={}&redirect_uri={}&response_type=code&scope=public_content".format(
                self.get_config("instagram_client_id"),
                self.get_config("instafram_redirect_url")
            )
            return flask.redirect(auth_url)

        raise InvalidUsage('Unknown service', status_code=400)

""" """


class InstagramOAuthHandler(BaseHandler):

    request_parser = reqparse.RequestParser()
    request_parser.add_argument('code', type=str)

    def get(self):
        args = self.request_parser.parse_args()

        if "code" not in args:
            raise InvalidUsage('Missing or invalid parameters', status_code=400)
            return

        utils.Logger.info("Authentication code returned {}".format(args["code"]))

        authentication_details = self.fetch_instagram_access_token(code=args["code"])

        if authentication_details is not None and "access_token" in authentication_details:
            self.get_data_manager().put_authenticated_account(
                service="instagram",
                account_details=authentication_details
            )

            return Response(
                response={'status': 'ok', "message": "account successfully registered"},
                status=200,
                mimetype="application/json"
            )
        else:
            raise InvalidUsage('Error while trying to obtain autehntication details', status_code=400)



