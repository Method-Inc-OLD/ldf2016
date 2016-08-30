
import flask
import io
from flask import request, jsonify, render_template, Response, send_file
from flask_restful import Resource, reqparse
import json
import logging
import datetime
import httplib2
import urllib
import urllib2
import ConfigParser
import utils
import constants
from data_manager import DataManager
from cpalette import CPalette
from colour_clustering import ColourClustering
import math
import numpy as np
import StringIO
import cv2
import colouriser
from colour_utils import ColourUtils
import random


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

    def fetch_image(self, image_url):
        user_agent = 'Mozilla/5.0 (Windows NT 6.1; Win64; x64)'
        headers = {'User-Agent': user_agent}
        req = urllib2.Request(image_url, headers=headers)
        res = urllib2.urlopen(req)
        arr = np.asarray(bytearray(res.read()), dtype=np.uint8)
        img = cv2.imdecode(arr, -1)
        return img


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


""" ColourClustersHandler """


class ColourClustersHandler(BaseHandler):

    request_parser = reqparse.RequestParser()
    request_parser.add_argument('image_url', type=str)
    request_parser.add_argument('clusters', type=int, default=5)
    request_parser.add_argument('minthresh', type=int, default=35)
    request_parser.add_argument('maxthresh', type=int, default=100)
    request_parser.add_argument('colourspace', type=str, default='rgb')
    request_parser.add_argument('mode', type=str, default='kmeans')

    def post(self):
        args = self.request_parser.parse_args()
        return self.process_request(args=args)

    def get(self):
        args = self.request_parser.parse_args()
        return self.process_request(args=args)

    def process_request(self, args):
        if "image_url" not in args:
            raise InvalidUsage('Missing or invalid parameters', status_code=400)
            return

        image_url = args.get("image_url")
        clusters = args.get("clusters", 5)
        colour_space = args.get("colourspace", 'rgb')
        min_thresh = args.get("minthresh", 35)
        max_thresh = args.get("maxthresh", 100)
        mode = args.get("mode", "kmeans")

        # utils.Logger.info("ColourClustersHandler {}".format(image_url))

        if mode == "palette":
            clusters = 16

            img = self.fetch_image(image_url=image_url)

            if img is None:
                raise InvalidUsage('Unable to fetch image from url', status_code=500)
                return

            cpalette = CPalette.generate(img, num_colours=clusters)
            result = self.create_response_from_palette(palette=self.format_palette(cpalette))

        else:
            result = ColourClustering.colour_cluster(
                clusters=clusters,
                image_url=image_url,
                colour_space=colour_space,
                min_thresh=min_thresh,
                max_thresh=max_thresh
            )

        print result

        if result is not None:
            result["status"] = "ok"
            return jsonify(result)
        else:
            raise InvalidUsage('Error while trying to obtain clusters from image, check url', status_code=400)

    def format_palette(self, palette):
        result = {}

        result["swatches"] = palette.get_swatches()

        result["highest_population"] = palette.highest_population
        if palette.vibrant_swatch is not None:
            result["vibrant_swatch"] = palette.vibrant_swatch.rgb.astype("uint8").tolist()

        if palette.muted_swatch is not None:
            result["muted_swatch"] = palette.muted_swatch.rgb.astype("uint8").tolist()

        if palette.dark_vibrant_swatch is not None:
            result["dark_vibrant_swatch"] = palette.dark_vibrant_swatch.rgb.astype("uint8").tolist()

        if palette.dark_muted_swatch is not None:
            result["dark_muted_swatch"] = palette.dark_muted_swatch.rgb.astype("uint8").tolist()

        if palette.light_vibrant_swatch is not None:
            result["light_vibrant_swatch"] = palette.light_vibrant_swatch.rgb.astype("uint8").tolist()

        if palette.light_muted_color is not None:
            result["light_muted_color"] = palette.light_muted_color.rgb.astype("uint8").tolist()

        return result

    def create_response_from_palette(self, palette):
        print "*** create_response_from_palette ***"

        result = {}
        result["colour_clusters"] = []

        cluster_counter = 0

        # reduce(lambda x, y: x+y, [1, 2, 3, 4, 5])
        #total_population = float(reduce(lambda a, b: a["population"] + b["population"], palette["swatches"]))
        populations = map(lambda a: a["population"], palette["swatches"])
        total_population = float(reduce(lambda a, b: a + b, populations))

        if "vibrant_swatch" in palette:
            cluster_counter += 1
            percentage = self.find_population_for_colour(palette["vibrant_swatch"], palette["swatches"]) / total_population
            result["colour_clusters"].append({
                "colour": palette["vibrant_swatch"],
                "percentage": round(percentage * 100., 2),
                "swatch": "vibrant_swatch"
            })

        if "light_muted_color" in palette:
            cluster_counter += 1
            percentage = self.find_population_for_colour(palette["light_muted_color"], palette["swatches"]) / total_population
            result["colour_clusters"].append({
                "colour": palette["light_muted_color"],
                "percentage": round(percentage * 100., 2),
                "swatch": "light_muted_color"
            })

        if "light_vibrant_swatch" in palette:
            cluster_counter += 1
            percentage = self.find_population_for_colour(palette["light_vibrant_swatch"], palette["swatches"]) / total_population
            result["colour_clusters"].append({
                "colour": palette["light_vibrant_swatch"],
                "percentage": round(percentage * 100., 2),
                "swatch": "light_vibrant_swatch"
            })

        if "dark_muted_swatch" in palette:
            cluster_counter += 1
            percentage = self.find_population_for_colour(palette["dark_muted_swatch"], palette["swatches"]) / total_population
            result["colour_clusters"].append({
                "colour": palette["dark_muted_swatch"],
                "percentage": round(percentage * 100., 2),
                "swatch": "dark_muted_swatch"
            })

        if "muted_swatch" in palette:
            cluster_counter += 1
            percentage = self.find_population_for_colour(palette["muted_swatch"], palette["swatches"]) / total_population
            result["colour_clusters"].append({
                "colour": palette["muted_swatch"],
                "percentage": round(percentage * 100., 2),
                "swatch": "muted_swatch"
            })

        if "dark_vibrant_swatch" in palette:
            cluster_counter += 1
            percentage = self.find_population_for_colour(palette["dark_vibrant_swatch"], palette["swatches"]) / total_population
            result["colour_clusters"].append({
                "colour": palette["dark_vibrant_swatch"],
                "percentage": round(percentage * 100., 2),
                "swatch": "dark_vibrant_swatch"
            })

        result["clusters"] = cluster_counter

        result["colour_clusters"].sort(key=lambda item: item["percentage"], reverse=True)

        return result

    def find_population_for_colour(self, rgb, swatches):
        for swatch in swatches:
            if rgb[0] == swatch["rgb"][0] and rgb[1] == swatch["rgb"][1] and rgb[2] == swatch["rgb"][2]:
                return float(swatch["population"])

        return 0.


""" VibrantColoursHandler """


class VibrantColoursHandler(BaseHandler):

    request_parser = reqparse.RequestParser()
    request_parser.add_argument('image_url', type=str)
    request_parser.add_argument('colours', type=int, default=7)

    def post(self):
        args = self.request_parser.parse_args()
        return self.process_request(args=args)

    def get(self):
        args = self.request_parser.parse_args()
        return self.process_request(args=args)

    def process_request(self, args):
        if "image_url" not in args:
            raise InvalidUsage('Missing or invalid parameters', status_code=400)
            return

        image_url = args.get("image_url")
        colours = args.get("colours", 7)

        if image_url is None or len(image_url) == 0:
            raise InvalidUsage('missing image_url', status_code=500)
            return

        img = self.fetch_image(image_url=image_url)

        img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

        if img is None or len(img) == 0 or (img.shape) == 0 or img.shape[0] == 0:
            raise InvalidUsage('Unable to fetch image from {}'.format(image_url), status_code=500)
            return

        #cpalette = CPalette.generate_with_mmcq(img, num_colours=colours)
        cpalette = CPalette.generate_with_android_colour_cut_quantizer(img, num_colours=colours)

        result = {
            "palette": cpalette.to_dict()
        }

        if result is not None:
            result["status"] = "ok"
            return jsonify(result)
        else:
            raise InvalidUsage('Error while trying to obtain clusters from image, check url', status_code=400)


""" ColouriseHandler """


class ColouriseHandler(BaseHandler):

    request_parser = reqparse.RequestParser()
    request_parser.add_argument('image_url', type=str)
    request_parser.add_argument('colours', type=int, default=7)
    request_parser.add_argument('swatch_index', type=int, default=0)

    def post(self):
        args = self.request_parser.parse_args()
        return self.process_request(args=args)

    def get(self):
        args = self.request_parser.parse_args()
        return self.process_request(args=args)

    def process_request(self, args):
        if "image_url" not in args:
            raise InvalidUsage('Missing or invalid parameters', status_code=400)
            return

        image_url = args.get("image_url")
        colours = args.get("colours", 7)
        requested_swatch_index = args.get("swatch_index", 0)

        if colours < 0 or colours > 255:
            raise InvalidUsage('invalid value for colours', status_code=500)
            return

        if requested_swatch_index < 0 or requested_swatch_index >= colours:
            raise InvalidUsage('invalid swatch index', status_code=500)
            return

        if image_url is None or len(image_url) == 0:
            raise InvalidUsage('missing image_url', status_code=500)
            return

        img = colouriser.Colouriser.colourise_image(image_url=image_url,
                                                    num_colours=colours,
                                                    requested_swatch_index=requested_swatch_index)

        if img is None or len(img) == 0 or (img.shape) == 0 or img.shape[0] == 0:
            raise InvalidUsage('Unable to fetch image from url', status_code=500)
            return

        # encode_param = [int(cv2.IMWRITE_PNG_COMPRESSION), 100]
        # result, encimg = cv2.imencode('.png', img, encode_param)

        encode_param = [int(cv2.IMWRITE_JPEG_QUALITY), 80]
        result, encimg = cv2.imencode('.jpg', img, encode_param)

        return send_file(io.BytesIO(encimg))


""" NextImageHandler """


class NextImageHandler(BaseHandler):

    request_parser = reqparse.RequestParser()
    request_parser.add_argument('randomly_select_from_top', type=int, default=0)

    def post(self):
        args = self.request_parser.parse_args()
        return self.process_request()

    def get(self):
        args = self.request_parser.parse_args()
        return self.process_request(args)

    def process_request(self, args):
        dm = self.get_data_manager()

        min_count = 0

        if "randomly_select_from_top" in args:
            min_count = args.get("randomly_select_from_top")
            min_count = random.randint(0, min_count)

        posts = dm.get_all_posts()

        next_image = None
        idx = 0
        valid_image_count = 0

        while idx < len(posts) and next_image is None:
            current_image = posts[idx]

            if self.validate_image(current_image):
                valid_image_count += 1
                if valid_image_count >= min_count:
                    next_image = current_image

            idx += 1

        result = {}

        if next_image is not None:
            result['next_image'] = next_image

        result["status"] = "ok" if next_image is not None else "error"
        return jsonify(result)

    def validate_image(self, image):
        if "rgb_clusters" not in image:
            return False

        if "palette" not in image:
            return False

        if "vibrant_swatch" not in image["palette"]:
            return False

        rgb_clusters = image["rgb_clusters"]

        if len(rgb_clusters) < 6:
            return False

        # make sure there is enough distance between each image
        rgb_colours = [item["rgb"] for item in rgb_clusters]

        # convert rgb to lab
        lab_colours = [self.rbg_to_lab(item) for item in rgb_colours]

        distances_matrix = np.zeros((len(lab_colours), len(lab_colours)))
        for i in range(len(lab_colours)):
            i_lab = lab_colours[i]

            for j in range(len(lab_colours)):
                j_lab = lab_colours[j]
                if i == j:
                    distances_matrix[i, j] = 999.
                else:
                    distances_matrix[i, j] = ColourUtils.euclidean_distance(i_lab, j_lab)

        min_distances = []
        for i in range(distances_matrix.shape[0]):
            min_distance = distances_matrix[i].min()
            min_distances.append(min_distance)

        min_distances = np.array(min_distances)

        return min_distances.std() > 5.

    def rbg_to_lab(self, rgb):
        lab = ColourUtils.rgb2lab(rgb)
        return np.array(lab)


""" AllImagesHandler """


class AllImagesHandler(BaseHandler):

    def get(self):
        posts = self.get_data_manager().get_colour_details_for_all_posts()

        # cluster mean
        cluster_count = 0.
        total_clusters = 0.
        for post in posts:
            if 'rgb_clusters' in post:
                cluster_count += 1.
                total_clusters += float(len(post['rgb_clusters']))

        cluster_mean = total_clusters / cluster_count

        result = {
            "status": "ok",
            "cluster_number_mean": cluster_mean,
            "images_count": len(posts),
            "images": posts
        }

        return jsonify(result)


""" SimilarImagesHandler """


class SimilarImagesHandler(BaseHandler):

    request_parser = reqparse.RequestParser()
    request_parser.add_argument('image_url', type=str)
    request_parser.add_argument('k', type=int, default=5)
    request_parser.add_argument('clusters', type=int, default=5)

    def get(self):
        args = self.request_parser.parse_args()

        if "image_url" not in args:
            raise InvalidUsage('Missing or invalid parameters', status_code=400)
            return

        image_url = args.get("image_url")
        k = args.get("k", 5)
        clusters = args.get("clusters", 5)

        colour_clusters_result = ColourClustering.colour_cluster(clusters=clusters, image_url=image_url)

        if colour_clusters_result is None:
            raise InvalidUsage('Error while trying to obtain clusters from image, check url', status_code=400)
            return

        result = {
            "status": "ok",
            "source": {
                "image_url": image_url,
                "colour_clusters": colour_clusters_result["colour_clusters"]
            },
            "similar_images": self.get_similar_images(
                colour_clusters=colour_clusters_result["colour_clusters"],
                k=k
            )
        }

        return jsonify(result)

    def post(self):
        args = self.request_parser.parse_args()

        if "image_url" not in args:
            raise InvalidUsage('Missing or invalid parameters', status_code=400)
            return

        image_url = args.get("image_url")
        k = args.get("k", 5)
        clusters = args.get("clusters", 5)

        colour_clusters_result = ColourClustering.colour_cluster(clusters=clusters, image_url=image_url)

        if colour_clusters_result is None:
            raise InvalidUsage('Error while trying to obtain clusters from image, check url', status_code=400)
            return

        result = {
            "status": "ok",
            "source": {
                "image_url": image_url,
                "colour_clusters": colour_clusters_result["colour_clusters"]
            },
            "similar_images": self.get_similar_images(
                colour_clusters=colour_clusters_result["colour_clusters"],
                k=k
            )
        }

        return jsonify(result)

    def get_similar_images(self, colour_clusters, k=5):
        similar_images = []

        src_colours = map(lambda a: a["colour"], colour_clusters)

        images_distance = []

        images = self.get_data_manager().get_colour_details_for_all_posts()
        for i in range(len(images)):
            image = images[i]
            image_colours = map(lambda a: a["colour"], image["rgb_clusters"])
            total_distance = 0
            for src_colour in src_colours:
                dis = self.get_closest_distance(src_colour, image_colours)
                total_distance += dis

            images_distance.append((i, total_distance))

        images_distance.sort(key=lambda tup: tup[1])

        image_indcies = [item[0] for item in images_distance]

        if len(image_indcies) > k:
            image_indcies = image_indcies[:k]

        for idx in image_indcies:
            similar_images.append(images[idx])

        return similar_images

    def get_closest_distance(self, c, colours):
        distances = [self.calc_distance(c, colour) for colour in colours]
        distances.sort()
        return distances[0]

    def calc_distance(self, c1, c2):
        tmp = map(lambda a, b: a - b, c1, c2)
        tmp = map(lambda a: a * a, tmp)
        tmp = math.sqrt(reduce(lambda x, y: x + y, tmp))
        return tmp


""" DominateColoursHandler """


class DominateColoursHandler(BaseHandler):

    request_parser = reqparse.RequestParser()
    request_parser.add_argument('clusters', type=int, default=-1)

    def get(self):
        args = self.request_parser.parse_args()

        clusters = args.get("clusters", -1)

        posts = self.get_data_manager().get_colour_details_for_all_posts()

        img = ColourClustering.create_colour_swatch_from_posts(posts=posts)

        result = ColourClustering.colour_cluster_from_image(
            clusters=clusters,
            img=img,
            colour_space='lab'
        )

        result = {
            "status": "ok",
            "colour_clusters": result['colour_clusters'],
            "colour_clusters_count": result['clusters']
        }

        return jsonify(result)


""" PaletteGridHandler """


class PaletteGridHandler(BaseHandler):

    request_parser = reqparse.RequestParser()

    def get(self):
        args = self.request_parser.parse_args()

        posts = self.get_data_manager().get_all_posts()

        img = ColourClustering.create_colour_swatch_from_posts(posts=posts)

        encode_param = [int(cv2.IMWRITE_JPEG_QUALITY), 90]
        result, encimg = cv2.imencode('.jpg', img, encode_param)

        return send_file(io.BytesIO(encimg))
