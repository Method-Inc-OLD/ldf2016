"""
Port from:
https://android.googlesource.com/platform/frameworks/support/+/b14fc7c/v7/palette/src/android/support/v7/graphics/Palette.java
https://android.googlesource.com/platform/frameworks/support/+/b14fc7c/v7/palette/src/android/support/v7/graphics/ColorUtils.java
"""

import cv2
import numpy as np
from colour_utils import ColourUtils, Swatch
from colour_quantization import ColourQuantization
#from mmcq import mmcq
from ict.MMCQ import MMCQ


class CPalette(object):

    DEFAULT_IMAGE_DOWN_SCALING = 200.  # < 0 == disabled
    DEFAULT_CALCULATE_NUMBER_COLORS = 16

    TARGET_DARK_LUMA = 0.26
    MAX_DARK_LUMA = 0.45

    MIN_LIGHT_LUMA = 0.55
    TARGET_LIGHT_LUMA = 0.74

    MIN_NORMAL_LUMA = 0.3
    TARGET_NORMAL_LUMA = 0.5
    MAX_NORMAL_LUMA = 0.7

    TARGET_MUTED_SATURATION = 0.3
    MAX_MUTED_SATURATION = 0.4

    TARGET_VIBRANT_SATURATION = 1.
    MIN_VIBRANT_SATURATION = 0.35

    WEIGHT_SATURATION = 3.
    WEIGHT_LUMA = 6.
    WEIGHT_POPULATION = 1.

    def __init__(self, swatches):
        self.swatches = swatches
        self.highest_population = 0
        self.vibrant_swatch = None
        self.muted_swatch = None
        self.dark_vibrant_swatch = None
        self.dark_muted_swatch = None
        self.light_vibrant_swatch = None
        self.light_muted_color = None

        self.highest_population = self.find_max_population()

        self.vibrant_swatch = self.findColor(CPalette.TARGET_NORMAL_LUMA, CPalette.MIN_NORMAL_LUMA,
                                             CPalette.MAX_NORMAL_LUMA, CPalette.TARGET_VIBRANT_SATURATION,
                                             CPalette.MIN_VIBRANT_SATURATION, 1.)

        self.light_vibrant_swatch = self.findColor(CPalette.TARGET_LIGHT_LUMA, CPalette.MIN_LIGHT_LUMA, 1.,
                                                   CPalette.TARGET_VIBRANT_SATURATION, CPalette.MIN_VIBRANT_SATURATION, 1.)

        self.dark_vibrant_swatch = self.findColor(CPalette.TARGET_DARK_LUMA, 0., CPalette.MAX_DARK_LUMA,
                                                  CPalette.TARGET_VIBRANT_SATURATION, CPalette.MIN_VIBRANT_SATURATION, 1.)

        self.muted_swatch = self.findColor(CPalette.TARGET_NORMAL_LUMA, CPalette.MIN_NORMAL_LUMA, CPalette.MAX_NORMAL_LUMA,
                                           CPalette.TARGET_MUTED_SATURATION, 0., CPalette.MAX_MUTED_SATURATION)

        self.light_muted_color = self.findColor(CPalette.TARGET_LIGHT_LUMA, CPalette.MIN_LIGHT_LUMA, 1.,
                                                CPalette.TARGET_MUTED_SATURATION, 0., CPalette.MAX_MUTED_SATURATION)

        self.dark_muted_swatch = self.findColor(CPalette.TARGET_DARK_LUMA, 0., CPalette.MAX_DARK_LUMA,
                                                CPalette.TARGET_MUTED_SATURATION, 0., CPalette.MAX_MUTED_SATURATION)

        self.generate_empty_swatches()

    def find_max_population(self):
        population = 0

        for i in range(len(self.swatches)):
            population = max(population, self.swatches[i].population)

        return population

    def is_already_selected(self, swatch):
        return swatch == self.vibrant_swatch or swatch == self.dark_vibrant_swatch \
               or swatch == self.light_vibrant_swatch or swatch == self.muted_swatch \
               or swatch == self.dark_muted_swatch or swatch == self.light_muted_color

    def findColor(self, targetLuma, minLuma, maxLuma, targetSaturation, minSaturation, maxSaturation):
        max_swatch = None
        max_value = 0

        for i in range(len(self.swatches)):
            swatch = self.swatches[i]

            sat = swatch.hsl[1]
            luma = swatch.hsl[2]

            if sat >= minSaturation and sat <= maxSaturation and luma >= minLuma and luma <= maxLuma \
                    and not self.is_already_selected(swatch):

                this_value = self.create_comparison_value(
                    sat, targetSaturation, luma, targetLuma,
                    swatch.population, self.highest_population
                )

                if max_swatch is None or this_value > max_value:
                    max_swatch = swatch
                    max_value = this_value

        return max_swatch

    def create_comparison_value(self, saturation, targetSaturation, luma, targetLuma, population, highestPopulation):
        return CPalette.weighted_mean([
            CPalette.invert_diff(saturation, targetSaturation), CPalette.WEIGHT_SATURATION,
            CPalette.invert_diff(luma, targetLuma), CPalette.WEIGHT_LUMA,
            float(population) / float(highestPopulation), CPalette.WEIGHT_POPULATION
        ])

    def generate_empty_swatches(self):

        if self.vibrant_swatch is None:
            if self.dark_vibrant_swatch is not None:
                new_hsl = self.copy_hsl_values(self.dark_vibrant_swatch)
                new_hsl[2] = CPalette.TARGET_NORMAL_LUMA
                self.vibrant_swatch = Swatch(ColourUtils.hsl_to_rgb(new_hsl), 0)

        if self.dark_vibrant_swatch is None:
            if self.vibrant_swatch is not None:
                new_hsl = self.copy_hsl_values(self.vibrant_swatch)
                new_hsl[2] = CPalette.TARGET_DARK_LUMA
                self.dark_vibrant_swatch = Swatch(ColourUtils.hsl_to_rgb(new_hsl), 0)

    def get_swatches(self):
        swatches = []

        for swatch in self.swatches:
            swatches.append({
                "rgb": swatch.rgb.astype("uint8").tolist(),
                "population": swatch.population
            })

        # sort by population
        swatches.sort(key=lambda swatch: swatch['population'], reverse=True)

        return swatches

    def to_dict(self):
        result = {}

        result["swatches"] = self.get_swatches()
        result["highest_population"] = self.highest_population
        if self.vibrant_swatch is not None:
            result["vibrant_swatch"] = self.vibrant_swatch.rgb.tolist()

        if self.muted_swatch is not None:
            result["muted_swatch"] = self.muted_swatch.rgb.tolist()

        if self.dark_vibrant_swatch is not None:
            result["dark_vibrant_swatch"] = self.dark_vibrant_swatch.rgb.tolist()

        if self.dark_muted_swatch is not None:
            result["dark_muted_swatch"] = self.dark_muted_swatch.rgb.tolist()

        if self.light_vibrant_swatch is not None:
            result["light_vibrant_swatch"] = self.light_vibrant_swatch.rgb.tolist()

        if self.light_muted_color is not None:
            result["light_muted_color"] = self.light_muted_color.rgb.tolist()

        return result

    @staticmethod
    def invert_diff(value, targetValue):
        return 1. - abs(value - targetValue)

    @staticmethod
    def weighted_mean(values):
        sum_val = 0.
        sum_weight = 0.

        for i in range(0, len(values), 2):
            val = values[i]
            val_weight = values[i+1]

            sum_val += (val * val_weight)
            sum_weight += val_weight

        return sum_val / sum_weight

    @staticmethod
    def copy_hsl_values(swatch):
        return swatch.hsl.copy()

    @staticmethod
    def generate(img, num_colours=DEFAULT_CALCULATE_NUMBER_COLORS, size=100., convert_to_rgb=True):
        CPalette.check_img_param(img)
        CPalette.check_number_colours_param(num_colours)

        # First we'll scale down the bitmap so it's shortest dimension is 100px
        scaled_img = CPalette.down_sample_img(img, size=size)

        if convert_to_rgb:
            scaled_img = cv2.cvtColor(scaled_img, cv2.COLOR_BGR2RGB)

        # generate a quantizer from the Bitmap
        return CPalette(ColourQuantization.get_colours(scaled_img, num_colours))

    @staticmethod
    def generate_with_android_colour_cut_quantizer(img,
                                                   num_colours=DEFAULT_CALCULATE_NUMBER_COLORS,
                                                   size=DEFAULT_IMAGE_DOWN_SCALING):

        from colour_cut_quantizer import ColourCutQuantizer
        img = CPalette.down_sample_img(img, size=size)

        colour_cq = ColourCutQuantizer.from_image(img, max_colours=num_colours)

        return CPalette(colour_cq.quantized_colours)

    @staticmethod
    def generate_with_mmcq(
            img,
            num_colours=DEFAULT_CALCULATE_NUMBER_COLORS,
            size=DEFAULT_IMAGE_DOWN_SCALING,
            convert_to_rgb=True):

        CPalette.check_img_param(img)
        CPalette.check_number_colours_param(num_colours)

        # First we'll scale down the bitmap so it's shortest dimension is 100px
        if size > 0:
            img = CPalette.down_sample_img(img, size=size)

        if convert_to_rgb:
            img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

        # swatches = []
        #
        # image_colours = CPalette._get_raw_colours(img, pixel_stride=quality)
        #
        # c_map = mmcq(image_colours, num_colours)
        # palette_and_population = c_map.palette_and_population
        # for item in palette_and_population:
        #     colour = item['colour']
        #     population = item['population']
        #     rgb = np.array([colour[0], colour[1], colour[2]])
        #     swatches.append(Swatch(rgb=rgb, population=population))

        mmcq = MMCQ(img, num_colours)

        if mmcq is None:
            return {}

        theme = mmcq.quantize()

        swatches = []
        for i in range(len(theme)):
            rgb = theme[i][0]
            population = theme[i][1]

            swatches.append(Swatch(rgb=np.array(rgb), population=population))

        return CPalette(swatches)

    @staticmethod
    def _get_raw_colours(img, pixel_stride=1):
        raw_colors = []
        img = img.reshape((img.shape[0] * img.shape[1], 3))

        num_pixels = len(img)
        i = 0

        while i < num_pixels:
            r = img[i][0]
            g = img[i][1]
            b = img[i][2]

            if r < 250 and g < 250 and b < 250:
                raw_colors.append((r, g, b))

            i += pixel_stride

        return raw_colors

    @staticmethod
    def check_img_param(img):
        pass

    @staticmethod
    def check_number_colours_param(img):
        pass

    @staticmethod
    def down_sample_img(img, size=100.):
        scaled_img = img

        # resize image
        if scaled_img.shape[1] > scaled_img.shape[0]:
            if scaled_img.shape[1] > size:
                ratio = float(size) / float(img.shape[1])
                scaled_img = cv2.resize(img,
                                        (int(ratio * scaled_img.shape[1]), int(ratio * scaled_img.shape[0])),
                                        interpolation=cv2.INTER_CUBIC)

        if scaled_img.shape[0] > size:
            ratio = float(size) / float(scaled_img.shape[0])
            scaled_img = cv2.resize(scaled_img,
                                    (int(ratio * scaled_img.shape[1]), int(ratio * scaled_img.shape[0])),
                                    interpolation=cv2.INTER_CUBIC)

        return scaled_img


if __name__ == '__main__':
    print __file__

    from cpalette import CPalette
    from image_utils import ImageUtils

    test_image = "/Users/josh/Desktop/ldf_test.jpg"
    #test_image = "/Users/josh/Desktop/palette16.png"

    img = ImageUtils.load_image(test_image)

    cv2.imshow("", img)
    cv2.waitKey(0)

    #palette = CPalette.generate(img)
    palette = CPalette.generate_with_mmcq(img)

    palette_result = palette.to_dict()

    print palette_result

    #
    # populations = map(lambda a: a["population"], palette_result["swatches"])
    # total_population = float(reduce(lambda a, b: a + b, populations))
    # print total_population