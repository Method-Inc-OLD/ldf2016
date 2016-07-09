import ConfigParser
import datetime
from pymongo import MongoClient, TEXT
from pymongo.errors import OperationFailure
import json
import sys
import re
import utils
import constants
import os
import utils
import constants


class DataManager(object):

    def __init__(self):
        self.config_parser = ConfigParser.RawConfigParser()
        self.config_parser.read(utils.get_full_file_path(constants.config_file))

        self.client = None

    def connect(self):
        print self.config_parser.get(constants.config_section, "mongodb_connection")
        self.client = MongoClient(self.config_parser.get(constants.config_section, "mongodb_connection"))

    def get_db(self):
        if self.client is None:
            self.connect()

        return self.client.instacolour

    def get_authenticated_accounts(self, service="instagram"):
        utils.Logger.info("getting get_authenticated_accounts for service {}".format(
            service
        ))

        authenticated_accounts = []

        try:
            collection = self.get_db()["authenticated_accounts"]

            service_authenticated_accounts = collection.find({"service": service})

            for service_authenticated_account in service_authenticated_accounts:
                authenticated_accounts.append(service_authenticated_account)

        except OperationFailure as e:
            utils.Logger.error(e.details)

        return authenticated_accounts

    def put_authenticated_account(self, service="instagram", account_details={}):
        account_details["service"] = service
        account_details["created_on"] = datetime.datetime.now()

        utils.Logger.info("put_authenticated_account {}".format(
            account_details
        ))

        try:
            collection = self.get_db()["authenticated_accounts"]

            item_id = collection.insert_one(account_details).inserted_id

        except OperationFailure as e:
            utils.Logger.error(e.details)
            return -1

        return item_id

    def put_post(self, post):
        created_on = datetime.datetime.now()

        utils.Logger.info("put_post {}".format(
            post
        ))

        post['created_on'] = created_on

        try:
            collection = self.get_db()["posts"]

            item_id = collection.insert_one(post).inserted_id

        except OperationFailure as e:
            utils.Logger.error(e.details)
            return -1

        return item_id

    def get_users_posts(self, username):

        posts = []

        try:
            collection = self.get_db()["posts"]

            users_posts = collection.find({"users_username": username})

            for post in users_posts:
                posts.append(post)

        except OperationFailure as e:
            utils.Logger.error(e.details)

        return posts

    def get_all_posts(self):

        posts = []

        try:
            collection = self.get_db()["posts"]

            all_posts = collection.find()

            for post in all_posts:
                posts.append(post)

        except OperationFailure as e:
            utils.Logger.error(e.details)

        return posts

    def get_all_post_ids(self):

        posts = []

        try:
            collection = self.get_db()["posts"]

            all_posts = collection.find(projection=["id"])

            for post in all_posts:
                posts.append(post["id"])

        except OperationFailure as e:
            utils.Logger.error(e.details)

        return posts

if __name__ == '__main__':
    print __file__

    dm = DataManager()
    #print dm.get_authenticated_accounts()[0]["access_token"]
    print dm.get_all_post_ids()

