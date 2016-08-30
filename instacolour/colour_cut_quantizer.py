from collections import namedtuple
import math
import random
import base64
import datetime
import os

import cv2
from sklearn.cluster import KMeans
import urllib
import numpy as np
import utils
import StringIO

from colour_utils import ColourUtils
from colour_utils import Swatch
from colour_histogram import ColourHistogram
from image_utils import ImageUtils


class ColourCutQuantizer(object):

    COMPONENT_RED = -3
    COMPONENT_GREEN = -2
    COMPONENT_BLUE = -1

    @staticmethod
    def from_image(image, max_colours=16):
        (h, w) = image.shape[:2]

        image = image.reshape((image.shape[0] * image.shape[1], 3))

        pixels = ColourUtils.pack_pixels(image, w, h)

        colour_hist = ColourHistogram(pixels)

        return ColourCutQuantizer(colour_histogram=colour_hist, max_colours=max_colours)

    def __init__(self, colour_histogram, max_colours):
        self.colours = []
        self.colour_populations = {}
        self.quantized_colours = []

        raw_colour_count = colour_histogram.number_of_colours
        raw_colours = colour_histogram.colours
        raw_colour_counts = colour_histogram.colour_counts

        # First, lets pack the populations into a SparseIntArray so that they can be easily
        # retrieved without knowing a color's index
        for i in range(len(raw_colours)):
            self.colour_populations[raw_colours[i]] = raw_colour_counts[i]

        # Now go through all of the colors and keep those which we do not want to ignore
        self.colours = []
        valid_colour_count = 0
        for i in range(len(raw_colours)):
            colour = raw_colours[i]
            rgb = np.array([ColourUtils.red(colour), ColourUtils.green(colour), ColourUtils.blue(colour)])
            if not ColourUtils.should_ignore(ColourUtils.rbg_to_hsl(rgb)):
                valid_colour_count += 1
                self.colours.append(colour)

        if valid_colour_count <= max_colours:
            self.quantized_colours = []
            for i in range(len(self.colours)):
                colour = self.colours[i]
                self.quantized_colours.append(Swatch(ColourUtils.unpack_pixel(colour), self.colour_populations[colour]))
        else:
            self.quantized_colours = self.quantize_pixels(valid_colour_count-1, max_colours)

    def quantize_pixels(self, max_colour_index, max_colours):
        """
        Create the priority queue which is sorted by volume descending. This means we always
        split the largest box in the queue
        """
        def compare(lhs, rhs):
            return lhs.volume - rhs.volume

        pq = PriorityQueue(queue_size=max_colours, compare_func=compare)

        # To start, offer a box which contains all of the colors
        pq.enqueue(Vbox(0, max_colour_index, self.colours, self.colour_populations))

        # Now go through the boxes, splitting them until we have reached maxColors or there are no
        # more boxes to split
        self.split_boxes(pq, max_colours)

        # Finally, return the average colors of the color boxes
        return self.generate_average_colours(pq)

    def generate_average_colours(self, vboxes):
        colours = []
        for vbox in vboxes.queue:
            colour = vbox.get_average_colour()
            if not ColourUtils.should_ignore(colour.hsl):
                colours.append(colour)

        return colours

    def split_boxes(self, pq, max_size):
        """
        Iterate through the {@link java.util.Queue}, popping objects from the queue
        and splitting them. Once split, the new box and the remaining box are offered back to the
        queue.
        :param pr:
        :param max_colours:
        :return:
        """
        while pq.size < max_size:
            vbox = pq.dequeue()

            if vbox is not None and vbox.can_split:
                # First split the box, and offer the result
                pq.enqueue(vbox.split_box())
                # Then offer the box back
                pq.enqueue(vbox)
            else:
                return


class PriorityQueue(object):

    def __init__(self, queue_size=10, compare_func=None):
        self.queue_size = queue_size
        self.compare_func = compare_func
        self.queue = []

    @property
    def size(self):
        return len(self.queue)

    def dequeue(self):
        if self.size == 0:
            return None

        item = self.queue[len(self.queue)-1]
        del self.queue[len(self.queue)-1]
        return item

    def enqueue(self, item):
        self.queue.insert(0, item)

        self.queue.sort(cmp=self.compare_func)

        if len(self.queue) > self.queue_size:
            self.queue = self.queue[:self.queue_size]


class Vbox(object):

    def __init__(self, lower_index, upper_index, colours, colour_populations):
        self.lower_index = lower_index
        self.upper_index = upper_index
        self.colours = colours
        self.colour_populations = colour_populations

        self.min_red = 0
        self.max_red = 0
        self.min_green = 0
        self.max_green = 0
        self.min_blue = 0
        self.max_blue = 0

        self.fit_box()

    def fit_box(self):
        """
        Recomputes the boundaries of this box to tightly fit the colors within the box.
        """

        # Reset the min and max to opposite values
        self.min_red = self.min_green = self.min_blue = 255
        self.max_red = self.max_green = self.max_blue = 0

        for i in range(self.lower_index, self.upper_index+1):
            colour = self.colours[i]
            r = ColourUtils.red(colour)
            g = ColourUtils.green(colour)
            b = ColourUtils.blue(colour)

            self.max_red = max(self.max_red, r)
            self.min_red = min(self.min_red, r)

            self.max_green = max(self.max_green, g)
            self.min_green = min(self.min_green, g)

            self.max_blue = max(self.max_blue, b)
            self.min_blue = min(self.min_blue, b)

    def split_box(self):
        """
        Split this color box at the mid-point along it's longest dimension
        """
        if not self.can_split:
            raise Exception("Can not split a box with only 1 color")

        # find median along the longest dimension
        split_point = self.find_split_point()

        new_box = Vbox(split_point + 1, self.upper_index, self.colours, self.colour_populations)

        # Now change this box's upperIndex and recompute the color boundaries
        self.upper_index = split_point

        self.fit_box()

        return new_box

    def find_split_point(self):
        """
        Finds the point within this box's lowerIndex and upperIndex index of where to split.

        This is calculated by finding the longest color dimension, and then sorting the
        sub-array based on that dimension value in each color. The colors are then iterated over
        until a color is found with at least the midpoint of the whole box's dimension midpoint.

        :return: the index of the colors array to split from
        """

        longest_dimension = self.get_longest_colour_dimension()

        """
        We need to sort the colors in this box based on the longest color dimension.
        As we can't use a Comparator to define the sort logic, we modify each color so that
        it's most significant is the desired dimension
        """
        self.modify_significant_octet(longest_dimension, self.lower_index, self.upper_index)

        # Now sort...
        # self.colours[self.lower_index:self.upper_index+1] = self.colours[self.lower_index:self.upper_index+1].sort()
        subset_colours = self.colours[self.lower_index:self.upper_index+1]
        subset_colours.sort()
        for i in range(0, len(subset_colours)):
            self.colours[(i + self.lower_index)] = subset_colours[i]

        # Now revert all of the colors so that they are packed as RGB again
        self.modify_significant_octet(longest_dimension, self.lower_index, self.upper_index)

        dimension_mid_point = self.mid_point(longest_dimension)

        for i in range(self.lower_index, self.upper_index):
            colour = self.colours[i]

            if longest_dimension == ColourCutQuantizer.COMPONENT_RED:
                if ColourUtils.red(colour) >= dimension_mid_point:
                    return i
            elif longest_dimension == ColourCutQuantizer.COMPONENT_GREEN:
                if ColourUtils.green(colour) >= dimension_mid_point:
                    return i
            elif longest_dimension == ColourCutQuantizer.COMPONENT_BLUE:
                if ColourUtils.blue(colour) > dimension_mid_point:
                    return i

        return self.lower_index

    def get_longest_colour_dimension(self):
        """
        :return: the dimension which this box is largest in
        """

        r_length = self.max_red - self.min_red
        g_length = self.max_green - self.min_green
        b_length = self.max_blue - self.min_blue

        if r_length >= g_length and r_length >= b_length:
            return ColourCutQuantizer.COMPONENT_RED
        elif g_length >= r_length and g_length >= b_length:
            return ColourCutQuantizer.COMPONENT_GREEN
        else:
            return ColourCutQuantizer.COMPONENT_BLUE

    def modify_significant_octet(self, dimension, lower_index, high_index):
        """
        Modify the significant octet in a packed color int. Allows sorting based on the value of a
        single color component.
        :param dimension:
        :param lower_index:
        :param high_index:
        :return:
        """

        if dimension == ColourCutQuantizer.COMPONENT_RED:
            # Already in RGB, no need to do anything
            pass
        elif dimension == ColourCutQuantizer.COMPONENT_GREEN:
            # We need to do a RGB to GRB swap, or vice-versa
            for i in range(lower_index, high_index+1):
                colour = self.colours[i]
                unpacked_pixel = ColourUtils.unpack_pixel(colour)
                self.colours[i] = ColourUtils.pack_pixel([unpacked_pixel[1], unpacked_pixel[0], unpacked_pixel[2]])
        elif dimension == ColourCutQuantizer.COMPONENT_BLUE:
            # We need to do a RGB to BGR swap, or vice-versa
            for i in range(lower_index, high_index+1):
                colour = self.colours[i]
                unpacked_pixel = ColourUtils.unpack_pixel(colour)
                self.colours[i] = ColourUtils.pack_pixel([unpacked_pixel[2], unpacked_pixel[1], unpacked_pixel[0]])

    def mid_point(self, dimension):
        if dimension == ColourCutQuantizer.COMPONENT_RED:
            return (self.min_red + self.max_red) / 2
        elif dimension == ColourCutQuantizer.COMPONENT_GREEN:
            return (self.min_green + self.max_green) / 2
        elif dimension == ColourCutQuantizer.COMPONENT_BLUE:
            return (self.min_blue + self.max_blue) / 2

        return (self.min_red + self.max_red) / 2

    def get_average_colour(self):
        """
        :return: the average color of this box.
        """
        red_sum = 0
        green_sum = 0
        blue_sum = 0
        total_population = 0

        for i in range(self.lower_index, self.upper_index+1):
            colour = self.colours[i]
            colour_population = self.colour_populations[colour]

            total_population += colour_population

            red_sum += colour_population * ColourUtils.red(colour)
            green_sum += colour_population * ColourUtils.green(colour)
            blue_sum += colour_population * ColourUtils.blue(colour)

        red_avg = int(float(red_sum) / float(total_population))
        green_avg = int(float(green_sum) / float(total_population))
        blue_avg = int(float(blue_sum) / float(total_population))

        return Swatch(np.array([red_avg, green_avg, blue_avg]), total_population)

    @property
    def volume(self):
        return (self.max_red - self.min_red + 1) * (self.max_green - self.min_green + 1) + (self.max_blue - self.min_blue + 1)

    @property
    def can_split(self):
        return self.colour_count > 1

    @property
    def colour_count(self):
        return self.upper_index - self.lower_index


if __name__ == '__main__':
    print __file__

    import cpalette

    #test_image = "/Users/josh/Desktop/ldf_test.jpg"
    test_image = "/Users/josh/Desktop/test2.jpg"
    #test_image = "/Users/josh/Desktop/palette16.png"
    #test_image = "/Users/josh/Desktop/paletteblue.png"
    image = cpalette.CPalette.down_sample_img(ImageUtils.load_image(test_image))

    colour_cq = ColourCutQuantizer.from_image(image)
    for swatch in colour_cq.quantized_colours:
        print swatch

    p = cpalette.CPalette(colour_cq.quantized_colours)
    print p.to_dict()