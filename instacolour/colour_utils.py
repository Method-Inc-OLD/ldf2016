
import numpy as np
import cv2
import math


class ColourUtils(object):

    BLACK_MAX_LIGHTNESS = 0.1
    WHITE_MIN_LIGHTNESS = 0.95

    @staticmethod
    def should_ignore(hsl):
        return ColourUtils.is_black(hsl) or ColourUtils.is_white(hsl) or ColourUtils.is_near_red_i_line(hsl)

    @staticmethod
    def is_black(hsl):
        return hsl[2] <= ColourUtils.BLACK_MAX_LIGHTNESS

    @staticmethod
    def is_white(hsl):
        return hsl[2] >= ColourUtils.WHITE_MIN_LIGHTNESS

    @staticmethod
    def is_near_red_i_line(hsl):
        return hsl[0] >= 10. and hsl[0] <= 37. and hsl[1] <= 0.82

    @staticmethod
    def calculateXyzLuma(rgb):
        return ((0.2126 * float(rgb[0])) + (0.7152 * float(rgb[1])) + (0.0722 * float(rgb[2]))/255.)

    @staticmethod
    def rgb2lab(rgb):
        """ http://www.easyrgb.com/index.php?X=MATH&H=07#text7 """
        return ColourUtils.xyz2lab(ColourUtils.rgb2xyz(rgb))

    @staticmethod
    def rgb2xyz(rgb):
        R = float(rgb[0])
        G = float(rgb[1])
        B = float(rgb[2])

        var_R = (R / 255.)
        var_G = (G / 255.)
        var_B = (B / 255.)

        if var_R > 0.04045:
            var_R = math.pow(( ( var_R + 0.055 ) / 1.055 ), 2.4)
        else:
            var_R = var_R / 12.92

        if var_G > 0.04045:
            var_G = math.pow(( ( var_G + 0.055 ) / 1.055 ), 2.4)
        else:
            var_G = var_G / 12.92

        if var_B > 0.04045:
            var_B = math.pow(( ( var_B + 0.055 ) / 1.055 ), 2.4)
        else:
            var_B = var_B / 12.92

        var_R = var_R * 100
        var_G = var_G * 100
        var_B = var_B * 100

        X = var_R * 0.4124 + var_G * 0.3576 + var_B * 0.1805
        Y = var_R * 0.2126 + var_G * 0.7152 + var_B * 0.0722
        Z = var_R * 0.0193 + var_G * 0.1192 + var_B * 0.9505

        return [X,Y,Z]

    @staticmethod
    def xyz2lab(xyz):
        ref_X = 95.047
        ref_Y = 100.000
        ref_Z = 108.883

        X = xyz[0]
        Y = xyz[1]
        Z = xyz[2]

        var_X = X / ref_X
        var_Y = Y / ref_Y
        var_Z = Z / ref_Z

        if var_X > 0.008856:
            var_X = math.pow(var_X, ( 1. / 3. ))
        else:
            var_X = (7.787 * var_X) + (16. / 116.)

        if var_Y > 0.008856:
            var_Y = math.pow(var_Y, ( 1. / 3. ))
        else:
            var_Y = (7.787 * var_Y) + (16. / 116.)

        if var_Z > 0.008856:
            var_Z = math.pow(var_Z, ( 1. / 3. ))
        else:
            var_Z = (7.787 * var_Z) + (16. / 116.)

        CIE_L = (116. * var_Y) - 16.
        CIE_a = 500. * (var_X - var_Y)
        CIE_b = 200. * (var_Y - var_Z)

        return [CIE_L, CIE_a, CIE_b]

    @staticmethod
    def euclidean_distance(dis1, dis2):
        dx = dis1[0] - dis2[0]
        dy = dis1[1] - dis2[1]
        dz = dis1[2] - dis2[2]

        return math.sqrt(dx*dx + dy*dy + dz*dz)

    @staticmethod
    def calc_rgb_distance(rgb1, rgb2):
        """
        http://stackoverflow.com/questions/8863810/python-find-similar-colors-best-way
        https://github.com/gtaylor/python-colormath
        """
        rmean = (rgb1[0] + rgb2[0])/2
        r = rgb1[0] - rgb2[0]
        g = rgb1[1] - rgb2[1]
        b = rgb1[2] - rgb2[2]
        return math.sqrt((((512+rmean)*r*r)>>8) + 4*g*g + (((767-rmean)*b*b)>>8))

    @staticmethod
    def calculateContrast(rgb1, rgb2):
        return abs(ColourUtils.calculateXyzLuma(rgb1) - ColourUtils.calculateXyzLuma(rgb2))

    @staticmethod
    def rbg_to_hsl(rgb):
        """
        http://serennu.com/colour/hsltorgb.php
        """
        hsl = [0., 0., 0.]

        rf = float(rgb[0]) / 255.
        gf = float(rgb[1]) / 255.
        bf = float(rgb[2]) / 255.

        max_v = max(rf, max(gf, bf))
        min_v = min(rf, min(gf, bf))
        deltaMaxMin = max_v - min_v

        h = 0.
        s = 0.

        l = (max_v + min_v) / 2.
        if max_v == min_v:
            h = s = 0.
        else:
            if max_v == rf:
                h = ((gf - bf) / deltaMaxMin) % 6
            elif max_v == gf:
                h = ((bf - rf) / deltaMaxMin) + 2
            else:
                h = ((rf - gf) / deltaMaxMin) + 4

            s = deltaMaxMin / (1 - abs(2 * l - 1))

        hsl[0] = (h * 60) % 360
        hsl[1] = s
        hsl[2] = l

        return np.array(hsl)

    @staticmethod
    def pack_pixel(pixel):
        r = pixel[0]
        g = pixel[1]
        b = pixel[2]

        packed_pixel = r
        packed_pixel = (packed_pixel << 8) + g
        packed_pixel = (packed_pixel << 8) + b

        return packed_pixel

    @staticmethod
    def unpack_pixel(packed_rgb):
        r = (packed_rgb >> 16) & 0xFF
        g = (packed_rgb >> 8) & 0xFF
        b = packed_rgb & 0xFF

        return np.array([r, g, b])

    @staticmethod
    def pack_pixels(flatterned_array, w, h):
        """
        expecting flatterned RGB array (flatterned_array)
        :param flatterned_array:
        :param w:
        :param h:
        :return:
        """
        packed_array = np.zeros(w * h, np.uint32)

        for i in range(0, len(flatterned_array)):
            r = flatterned_array[i][0]
            g = flatterned_array[i][1]
            b = flatterned_array[i][2]

            packed_pixel = r
            packed_pixel = (packed_pixel << 8) + g
            packed_pixel = (packed_pixel << 8) + b
            packed_array[i] = packed_pixel

        return packed_array

    @staticmethod
    def unpack_pixels(packed_array, w, h):
        """
        expecting flatterned RGB array (flatterned_array)
        :param packed_array:
        :param w:
        :param h:
        :return:
        """
        unpacked_array = np.zeros(w * h * 3, np.uint32)
        for i in range(0, len(packed_array)):
            rgb = packed_array[i]
            r = (rgb >> 16) & 0xFF
            g = (rgb >> 8) & 0xFF
            b = rgb & 0xFF

            unpacked_array[i] = r
            unpacked_array[i + 1] = g
            unpacked_array[i + 2] = b

        return unpacked_array

    @staticmethod
    def red(packed_rgb):
        return (packed_rgb >> 16) & 0xFF

    @staticmethod
    def green(packed_rgb):
        return (packed_rgb >> 8) & 0xFF

    @staticmethod
    def blue(packed_rgb):
        return packed_rgb & 0xFF

    @staticmethod
    def hsl_to_rgb(hsl):
        h = hsl[0]
        s = hsl[1]
        l = hsl[2]

        c = (1 - abs(2. * l - 1.)) * s
        m = l - 0.5 * c
        x = c * (1. - abs((h / 60 % 2.) - 1.))

        hueSegment = int(h / 60.)

        if hueSegment == 0:
            r = round(255 * (c + m))
            g = round(255 * (x + m))
            b = round(255 * m)
        elif hueSegment == 1:
            r = round(255 * (x + m))
            g = round(255 * (c + m))
            b = round(255 * m)
        elif hueSegment == 2:
            r = round(255 * m)
            g = round(255 * (c + m))
            b = round(255 * (x + m))
        elif hueSegment == 3:
            r = round(255 * m)
            g = round(255 * (x + m))
            b = round(255 * (c + m))
        elif hueSegment == 4:
            r = round(255 * (x + m))
            g = round(255 * m)
            b = round(255 * (c + m))
        else:
            r = round(255 * (c + m))
            g = round(255 * m)
            b = round(255 * (x + m))

        r = max(0, min(255, r))
        g = max(0, min(255, g))
        b = max(0, min(255, b))

        return np.array([r, g, b])


class Swatch(object):

    def __init__(self, rgb, population=0):
        self.rgb = rgb
        self.population = population
        self.hsl = ColourUtils.rbg_to_hsl(rgb)

    def __eq__(self, other):
        if other is None or other.rgb is None:
            return False

        return self.rgb[0] == other.rgb[0] and self.rgb[1] == other.rgb[1] and self.rgb[2] == other.rgb[2]

    def __str__(self):
        return "Swatch(rgb({},{},{}) x {})".format(
            self.rgb[0],
            self.rgb[1],
            self.rgb[2],
            self.population
        )

    def __repr__(self):
        return self.__str__()

