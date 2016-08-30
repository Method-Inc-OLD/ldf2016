
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

from colour_utils import ColourUtils
from colour_utils import Swatch
from colour_histogram import ColourHistogram
from image_utils import ImageUtils
import colour_cut_quantizer
from cpalette import CPalette

import cv2


class Colouriser(object):

    STANDARD_DEVIATIONS = 2.5

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
    def colourise_image(image_url, num_colours=7, requested_swatch_index=0):
        img = Colouriser.fetch_image(image_url=image_url)
        img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

        return Colouriser.colourise_image_with_image(img, num_colours, requested_swatch_index)

    @staticmethod
    def colourise_image_with_image(img, num_colours=7, requested_swatch_index=0):
        cpalette = CPalette.generate_with_android_colour_cut_quantizer(img, num_colours=num_colours)

        img = CPalette.down_sample_img(img, 400)

        cpalette_dict = cpalette.to_dict()

        swatches = cpalette_dict["swatches"]
        #print swatches
        swatches = np.array([np.array(swatch["rgb"]) for swatch in swatches])

        def rbg_to_lab(rgb):
            lab = ColourUtils.rgb2lab(rgb)
            return np.array(lab)

        swatches_lab = np.apply_along_axis(rbg_to_lab, 1, swatches)

        def rbg_to_lab_find_closest_swatch(rgb):
            lab = ColourUtils.rgb2lab(rgb)

            min_dis = 999.
            min_dis_idx = -1

            for i in range(swatches_lab.shape[0]):
                dis = ColourUtils.euclidean_distance(lab, swatches_lab[i])

                if min_dis_idx == -1 or dis < min_dis:
                    min_dis = dis
                    min_dis_idx = i

            return np.array([rgb[0], rgb[1], rgb[2], min_dis_idx, min_dis])

        img_swatch_idx = np.apply_along_axis(rbg_to_lab_find_closest_swatch, 2, img)

        swatch_dis = np.zeros((7, 2))

        for i in range(swatches_lab.shape[0]):
            subset = img_swatch_idx[np.where(img_swatch_idx[:, :, 3] == i)]
            swatch_dis[i, 0] = subset[:, 4].mean()
            swatch_dis[i, 1] = subset[:, 4].std()

        def filter_img_swatch_idx_to_greya(data):
            intensity = int(0.2989*float(data[0]) + 0.5870*float(data[1]) + 0.1140*float(data[2]))
            idx = int(data[3])
            dis = data[4]

            swatch_mean_std = swatch_dis[int(idx)]

            if dis < (swatch_mean_std[0] - Colouriser.STANDARD_DEVIATIONS * swatch_mean_std[1]) or dis > (swatch_mean_std[0] + Colouriser.STANDARD_DEVIATIONS * swatch_mean_std[1]):
                idx = -1

            if idx == -1:
                return np.array([intensity, intensity, intensity, 0], np.uint8)

            if requested_swatch_index == idx:
                return np.array([int(data[2]), int(data[1]), int(data[0]), 255-idx], np.uint8)
            else:
                return np.array([intensity, intensity, intensity, 255-idx], np.uint8)

        final = np.apply_along_axis(filter_img_swatch_idx_to_greya, 2, img_swatch_idx)

        return final


"""
ran out of names; this class is a facade for extracting the palette from a image and encoding the index of these colours
in the alpha channel of the (and returning it)
"""


def validate_image(image_url, num_colours=6):
    img = Colouriser.fetch_image(image_url=image_url)
    img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

    cpalette = CPalette.generate_with_android_colour_cut_quantizer(img, num_colours=num_colours)

    image = cpalette.to_dict()

    rgb_clusters = image["swatches"]

    if len(rgb_clusters) < 6:
        return False

    # make sure there is enough distance between each image
    rgb_colours = [item["rgb"] for item in rgb_clusters]

    # convert rgb to lab
    # dis = ColourUtils.euclidean_distance(lab, swatches_lab[i])
    lab_colours = [rbg_to_lab(item) for item in rgb_colours]

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
    print min_distances.std()


def rbg_to_lab(rgb):
    lab = ColourUtils.rgb2lab(rgb)
    return np.array(lab)


# if __name__ == '__main__':
#     print __file__
#
#     # image_url_1 = "http://www.designboom.com/wp-content/uploads/2016/08/yinka-ilori-a-swimming-pool-of-dreams-clerkenwell-london-design-festival-designboom-600.jpg"
#     #image_url_1 = "https://fa707ec5abab9620c91c-e087a9513984a31bae18dd7ef8b1f502.ssl.cf1.rackcdn.com/11308925_ldf-london-design-festival-2016-raw-color_td64876bc.jpg"
#     image_url_1 = "http://www.hglivingbeautifully.com/wp-content/uploads/2015/09/London-Design-Festival-Homes-Gardens-3.jpg"
#     #image_url_1 = "http://files.idnworld.com/events/files/2016/LondonDesignFestival-2016.jpg"
#     #image_url_1 = "http://www.elledecor.it/var/elleit/storage/images/london-design-festival/interview-max-fraser-london-design-festival/interview-max-fraser-london-design-festival/15797278-1-ita-IT/interview-max-fraser-london-design-festival_box4cposter.jpg"
#     #image_url_1 = "http://www.tutorialspoint.com/java_dip/images/grayscale.jpg"
#
#     # img = Colouriser.colourise_image(image_url=image_url_1, num_colours=6, requested_swatch_index=4)
#     #cv2.imshow("grey", cv2.cvtColor(img, cv2.COLOR_RGBA2BGRA))
#     # cv2.imshow("grey", img)
#     # cv2.waitKey(0)
#
#     validate_image(image_url_1)




