from mmcq import mmcq
from colour_utils import ColourUtils
from colour_utils import Swatch
from colour_histogram import ColourHistogram
from image_utils import ImageUtils
import cv2
import numpy as np
from ict.MMCQ import MMCQ
import skimage
from skimage import io


def prepare_image(image):
    image = cpalette.CPalette.down_sample_img(image)
    return image


def get_colours_from_image(image, convert_to_rgb=True):
    (h, w) = image.shape[:2]

    colors = []

    if convert_to_rgb:
        image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

    image = image.reshape((image.shape[0] * image.shape[1], 3))

    for i in range(0, len(image)):
        r = image[i][0]
        g = image[i][1]
        b = image[i][2]

        if r < 250 and g < 250 and b < 250:
            colors.append((r, g, b))

    return colors


def get_swatches_from_image_colours(image_colours):
    swatches = []

    c_map = mmcq(image_colours, 16)
    palette = c_map.palette_and_population
    for item in palette:
        colour = item['colour']
        population = item['population']
        rgb = np.array([colour[0], colour[1], colour[2]])
        swatches.append(Swatch(rgb=rgb, population=population))

    return swatches

if __name__ == '__main__':
    print __file__

    import cpalette
    from colour_utils import ColourUtils

    #test_image = "/Users/josh/Desktop/palette16.png"
    test_image = "/Users/josh/Desktop/ldf_test.jpg"

    #image = prepare_image(ImageUtils.load_image(test_image))
    #image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

    image = io.imread(test_image)

    mmcq = MMCQ(image, 6)
    theme = mmcq.quantize()
    print theme

    swatches = []
    for i in range(len(theme)):
        rgb = theme[i][0]
        population = theme[i][1]
        swatches.append(Swatch(rgb=np.array(rgb), population=population))

    p = cpalette.CPalette(swatches=swatches)
    print p.to_dict()

    """
    image_colours = get_colours_from_image(image)
    swatches = get_swatches_from_image_colours(image_colours)

    print len(swatches)
    print swatches

    #print reduce(lambda a, b: a + b, map(lambda a: a.population, swatches))

    palette = cpalette.CPalette(swatches=swatches)
    print palette.to_dict()
    """

