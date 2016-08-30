
from image_utils import ImageUtils
from colour_utils import ColourUtils, Swatch
import numpy as np
import cv2
#from sklearn.cluster import MiniBatchKMeans
from sklearn.cluster import KMeans


class ColourHistogram(object):

    def __init__(self, pixels_array):
        self.colours = []
        self.colour_counts = []
        self.number_of_colours = 0

        self.pixels = pixels_array

        # Sort the pixels to enable counting below
        #self.pixels[::-1].sort()
        self.pixels.sort()

        """ // Count number of distinct colors
        mNumberColors = countDistinctColors(pixels);"""
        # Count number of distinct colors
        self.number_of_colours = self.count_distinct_colours(self.pixels)

        # create arrays ???

        # count frequencies for each colour
        self.count_frequencies(self.pixels)

    def count_distinct_colours(self, pixels):
        if pixels.size < 2:
            return pixels.size

        colour_count = 1
        current_colour = pixels[0]

        for i in range(1, pixels.size):
            if pixels[i] != current_colour:
                current_colour = pixels[i]
                colour_count += 1

        return colour_count

    def count_frequencies(self, pixels):
        if pixels.size == 0:
            return

        current_colour_index = 0
        current_colour = pixels[0]

        self.colours.append(current_colour)
        self.colour_counts.append(1)

        if pixels.size == 1:
            return

        for i in range(1, pixels.size):
            if pixels[i] == current_colour:
                self.colour_counts[current_colour_index] += 1
            else:
                current_colour = pixels[i]

                current_colour_index += 1
                self.colours.append(current_colour)
                self.colour_counts.append(1)
