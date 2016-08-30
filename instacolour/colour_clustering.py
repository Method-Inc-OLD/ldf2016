
"""
http://charlesleifer.com/blog/using-python-and-k-means-to-find-the-dominant-colors-in-images/
"""

from collections import namedtuple
import math
import random
import base64
import datetime
import os

import cv2
from sklearn.cluster import KMeans
import urllib
import urllib2
import numpy as np
import utils
import StringIO

Point = namedtuple('Point', ('coords', 'n', 'ct'))
Cluster = namedtuple('Cluster', ('points', 'center', 'n'))


class ColourClustering(object):

    @staticmethod
    def create_colour_swatch_from_posts(posts, width=1000, height=1000):
        if width != height:
            raise Exception('Illegal params, width and height must be equal')

        posts = filter(lambda post: ('rgb_clusters' in post and len(post['rgb_clusters']) > 0), posts)

        cx = 0.
        cy = 0.

        #swatch_dim = math.sqrt(float(width * height)/float(len(posts)))
        swatch_dim = int(math.floor(float(width)/math.sqrt(float(len(posts)))))

        width = swatch_dim**2
        height = width

        blank_image = np.zeros((height, width, 3), np.uint8)

        cv2.rectangle(
            blank_image,
            (0, 0), (width, height),
            (255, 255, 255),
            thickness=cv2.cv.CV_FILLED
        )

        print "post count {}, swatch_dim {} width {}".format(len(posts), swatch_dim, width)

        for i in range(len(posts)):
            post = posts[i]
            # break palette up based on cluster size
            rgb_clusters = post['rgb_clusters']
            num_clusters = len(rgb_clusters)
            rect_width = swatch_dim/float(num_clusters)
            rect_height = swatch_dim

            for j in range(num_clusters):
                x = int(cx + j * rect_width)
                y = int(cy)
                x2 = int(x + rect_width)
                y2 = int(y + rect_height)

                # http://docs.opencv.org/3.0-beta/modules/imgproc/doc/drawing_functions.html
                rgb = rgb_clusters[j]['colour']
                cv2.rectangle(
                    blank_image,
                    (x, y), (x2, y2),
                    (rgb[2], rgb[1], rgb[0]),
                    thickness=cv2.cv.CV_FILLED
                )

            cx += swatch_dim

            if cx >= width:
                cx = 0
                cy += swatch_dim

        return blank_image


    @staticmethod
    def fetch_image(image_url):
        user_agent = 'Mozilla/5.0 (Windows NT 6.1; Win64; x64)'
        headers = {'User-Agent': user_agent}
        req = urllib2.Request(image_url, headers=headers)
        res = urllib2.urlopen(req)
        arr = np.asarray(bytearray(res.read()), dtype=np.uint8)
        img = cv2.imdecode(arr, -1)
        return img

    @staticmethod
    def colour_cluster_on_all_images(clusters=5, all_colours=None):
        all_colours_array = np.array(all_colours)

        clt = KMeans(n_clusters=clusters)
        clt.fit(all_colours_array)

        hist = ColourClustering.centroid_histogram_from_cluster(clt)

        colour_clusters = []

        for (percent, colour) in zip(hist, clt.cluster_centers_):
            colour_clusters.append({
                "percentage": round(float(percent) * 100., 2),
                "colour": colour.astype("uint8").tolist()
            })

        result = {
            "clusters": clusters,
            "colour_clusters": colour_clusters
        }

        utils.Logger.info("returning {}".format(result))

        return result

    @staticmethod
    def colour_cluster(clusters=5, image_url=None, colour_space='rgb', min_thresh=35, max_thresh=100):

        if "data:image" in image_url:
            utils.Logger.info("detected image data, writing to buffer before loading into memory")

            output = StringIO.StringIO()
            output.write(base64.b64decode(image_url.split(",")[1]))
            output.seek(0)
            img_array = np.asarray(bytearray(output.read()), dtype=np.uint8)
            img = cv2.imdecode(img_array, cv2.CV_LOAD_IMAGE_COLOR)
            output.close()

        else:
            utils.Logger.info("fetching image from {}".format(image_url))
            img = ColourClustering.fetch_image(image_url=image_url)

        if img is None:
            return None

        return ColourClustering.colour_cluster_from_image(
            clusters=clusters,
            img=img,
            colour_space=colour_space,
            min_thresh=min_thresh,
            max_thresh=max_thresh
        )

    @staticmethod
    def colour_cluster_from_image(clusters=5, img=None, colour_space='rgb', min_thresh=30, max_thresh=100):

        if img is None:
            return None

        MAX_IMAGE_SIZE = 200.

        # resize image
        if img.shape[1] > img.shape[0]:
            if img.shape[1] > MAX_IMAGE_SIZE:
                ratio = MAX_IMAGE_SIZE / img.shape[1]
                img = cv2.resize(img, (int(ratio * img.shape[0]), int(ratio * img.shape[1])),
                                 interpolation=cv2.INTER_CUBIC)
        elif img.shape[0] > MAX_IMAGE_SIZE:
            ratio = MAX_IMAGE_SIZE / img.shape[0]
            img = cv2.resize(img, (int(ratio * img.shape[0]), int(ratio * img.shape[1])), interpolation=cv2.INTER_CUBIC)

        # convert image from BGR to RGB
        if colour_space == 'rgb':
            img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        elif colour_space == 'hsv':
            img = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
        elif colour_space == 'lab':
            img = cv2.cvtColor(img, cv2.COLOR_BGR2LAB)
        elif colour_space == 'hls':
            img = cv2.cvtColor(img, cv2.COLOR_BGR2HLS)

        if clusters > 0:
            return ColourClustering._colour_cluster_from_image(
                clusters=clusters,
                img=img,
                colour_space=colour_space
            )

        return ColourClustering.search_for_optimum_clusters(
            img=img,
            colour_space=colour_space,
            min_thresh=min_thresh,
            max_thresh=max_thresh
        )

    @staticmethod
    def search_for_optimum_clusters(img=None, colour_space='rgb', min_thresh=50, max_thresh=150):
        current_clusters = 12
        threshold_meet = False
        counter = 0

        reshaped_img = img.reshape((img.shape[0] * img.shape[1], 3))

        while not threshold_meet and current_clusters > 1 and current_clusters < 15 and counter < 10:

            clt = KMeans(n_clusters=current_clusters)
            clt.fit(reshaped_img)

            cluster_centers_ = clt.cluster_centers_

            min_dis, max_dis = ColourClustering._find_min_max_distances(cluster_centers_)

            counter += 1

            if min_dis < min_thresh:
                current_clusters -= 1
            elif min_dis > max_thresh:
                current_clusters += 1
            else:
                threshold_meet = True

            print min_dis
            print max_dis

        return ColourClustering._colour_cluster_from_image(
            clusters=current_clusters,
            img=img,
            colour_space=colour_space
        )

    @staticmethod
    def _find_min_max_distances(cluster_centers):
        min_dis = 99999999
        max_dis = 0

        count = cluster_centers.shape[0]

        for i in range(count-1):
            col1 = cluster_centers[i]
            for j in range(i+1, count):
                col2 = cluster_centers[j]

                print col1
                print col2

                col_diff = map(lambda a, b: (a - b) ** 2, col1, col2)
                col_sum = reduce(lambda a, b: a + b, col_diff)
                e_distance = math.sqrt(col_sum)

                min_dis = min(e_distance, min_dis)
                max_dis = max(e_distance, max_dis)

        return min_dis, max_dis

    @staticmethod
    def _colour_cluster_from_image(clusters=5, img=None, colour_space='rgb'):
        # reshape the image to be a list of pixels
        img = img.reshape((img.shape[0] * img.shape[1], 3))

        clt = KMeans(n_clusters=clusters)
        clt.fit(img)

        hist = ColourClustering.centroid_histogram_from_cluster(clt)

        colour_clusters = []

        cluster_centers_ = clt.cluster_centers_

        for (percent, colour) in zip(hist, cluster_centers_):
            if colour_space == "lab":
                colour = cv2.cvtColor(
                    colour.astype('uint8').reshape((1, 1, 3)),
                    cv2.COLOR_LAB2RGB
                )[0,0,:]

            colour_clusters.append({
                "percentage": round(float(percent) * 100., 2),
                "colour": colour.astype('uint8').tolist()
            })

        colour_clusters.sort(key=lambda item: item["percentage"], reverse=True)

        result = {
            "colour_space": colour_space,
            "clusters": clusters,
            "colour_clusters": colour_clusters
        }

        utils.Logger.info("returning {}".format(result))

        return result

    @staticmethod
    def centroid_histogram_from_cluster(clt):
        """
        Grab the number of different clusters and create a histogram
        based on the number of pixels assigned to each cluster
        """
        numLabels = np.arange(0, len(np.unique(clt.labels_)) + 1)
        (hist, _) = np.histogram(clt.labels_, bins=numLabels)

        # normalize the histogram, such that it sums to one
        hist = hist.astype("float")
        hist /= hist.sum()

        return hist


if __name__ == '__main__':
    print __file__

    image_1_url = "https://scontent.cdninstagram.com/t51.2885-15/s640x640/sh0.08/e35/13534120_149595438794557_1250197596_n.jpg?ig_cache_key=MTI4NDcyNTE1MzgzMDA1MjIwOQ%3D%3D.2"
    image_2_url = "https://scontent.cdninstagram.com/t51.2885-15/s640x640/sh0.08/e35/13561902_1138566509519678_1935865874_n.jpg?ig_cache_key=MTI4NzYyNjM0NzUzOTg3MzQ4Ng%3D%3D.2"

    # req = urllib.urlopen(image_1_url)
    # arr = np.asarray(bytearray(req.read()), dtype=np.uint8)
    # img = cv2.imdecode(arr, -1)  # 'load it as it is'
    #
    # cv2.imshow('lalala', img)
    # cv2.waitKey(0)

    print ColourClustering.colour_cluster(image_url=image_1_url)