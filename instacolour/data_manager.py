import ConfigParser
import datetime
import pymongo
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

            all_posts = collection.find().sort(
                [("datetime", pymongo.DESCENDING)]
            )

            for post in all_posts:
                del post['_id']
                # sort rgb_clusters by rgb
                post['rgb_clusters'].sort(key=lambda x: x, reverse=True)
                #post['rgb_clusters'] = sorted(post['rgb_clusters'], key=lambda x: x['population'], reverse=True)
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
                del post["_id"]
                posts.append(post["id"])

        except OperationFailure as e:
            utils.Logger.error(e.details)

        return posts

    def get_posts_with_no_cluster_analysis(self):
        posts = []

        try:
            collection = self.get_db()["posts"]

            all_posts = collection.find({"rgb_clusters": {"$exists": False}})

            for post in all_posts:
                posts.append(post)

        except OperationFailure as e:
            utils.Logger.error(e.details)

        return posts

    def get_colour_details_for_all_posts(self):
        posts = []

        try:
            collection = self.get_db()["posts"]

            all_posts = collection.find(
                {"rgb_clusters": {"$exists": True}},
                projection=["img_src", "likes", "rgb_clusters"]
            ).sort(
                [("created_on", pymongo.DESCENDING)]
            )

            for post in all_posts:
                post_obj = {
                    "img_src": post["img_src"],
                    "rgb_clusters": post["rgb_clusters"]
                }

                if "likes" in post:
                    post_obj["likes"] = post["likes"]
                else:
                    post_obj["likes"] = 0

                posts.append(post_obj)

        except OperationFailure as e:
            utils.Logger.error(e.details)

        return posts

    def update_post(self, post):

        try:
            collection = self.get_db()["posts"]
            collection.update({'_id': post["_id"]}, {"$set": post}, upsert=False)

        except OperationFailure as e:
            utils.Logger.error(e.details)


# if __name__ == '__main__':
#     print __file__
#
#     dm = DataManager()
#
#     posts = dm.get_all_posts()
#
#     for i in range(8):
#         print posts[i]

    #print dm.get_authenticated_accounts()[0]["access_token"]
    #print dm.get_all_post_ids()

    # from colour_clustering import ColourClustering
    # posts = dm.get_posts_with_no_cluster_analysis()
    #
    # print len(posts)
    # post = posts[0]
    # img_src = post["img_src"]
    # res = ColourClustering.colour_cluster(image_url=img_src, clusters=5)
    # if res is not None:
    #     post["rgb_clusters"] = res["colour_clusters"]
    #     dm.update_post(post)

    # posts = dm.get_colour_details_for_all_posts()
    # print posts[0]
    # colours = map(lambda a: a["colour"], posts[0]["rgb_clusters"])
    #
    # c = [122,211,12]
    # distances = [calc_distance(c, colour) for colour in colours]
    # distances.sort()
    # print distances[0]


    # import math
    #
    # c1 = [122, 24, 25]
    # c2 = [122,12, 12]
    # c = map(lambda a, b: a-b, c1, c2)
    # c = map(lambda a: a*a, c)
    # c = math.sqrt(reduce(lambda x,y: x+y, c))
    # print c

    # import numpy as np
    #
    # print np.array([[123,123,123], [111,111,111]])



# if __name__ == '__main__':
#     print __file__
#
#     dm = DataManager()
#     posts = dm.get_all_posts()
#     #print sorted(posts[0]['rgb_clusters'], key=lambda x: x['population'], reverse=True)
#     print posts[0]['rgb_clusters']


