"""
http://www.pyimagesearch.com/2014/07/07/color-quantization-opencv-using-k-means-clustering/
http://glowingpython.blogspot.co.uk/2012/07/color-quantization.html
http://opencvpython.blogspot.co.uk/2013/01/k-means-clustering-3-working-with-opencv.html

"""

from image_utils import ImageUtils
from colour_utils import ColourUtils, Swatch
import numpy as np
import cv2
#from sklearn.cluster import MiniBatchKMeans
from sklearn.cluster import KMeans


class ColourQuantization(object):

    @staticmethod
    def get_colours(image, clusters=12):
        (h, w) = image.shape[:2]
            
        image = image.reshape((image.shape[0] * image.shape[1], 3))
        mask = np.apply_along_axis(ColourQuantization.should_ignore_colour, 1, image)
        image = image[mask]

        for i in range(len(image)):
            image[i] = cv2.cvtColor(image[i].astype('uint8').reshape((1, 1, 3)), cv2.COLOR_RGB2LAB)

        #clt = MiniBatchKMeans(n_clusters=clusters)
        clt = KMeans(n_clusters=clusters, n_init=1)
        clt.fit(image)
        labels = clt.fit_predict(image)
        #quant = clt.cluster_centers_.astype("uint8")[labels]
        quantized_colours = clt.cluster_centers_

        colour_count = np.zeros(len(quantized_colours))
        for label in labels:
            colour_count[label] += 1

        # convert to rgb
        for i in range(len(quantized_colours)):
            quantized_colours[i] = cv2.cvtColor(quantized_colours[i].astype("uint8").reshape((1, 1, 3)), cv2.COLOR_LAB2RGB)

        mask = np.apply_along_axis(ColourQuantization.should_ignore_colour, 1, quantized_colours)
        quantized_colours = quantized_colours[mask]

        swatches = []

        for i in range(len(quantized_colours)):
            swatches.append(Swatch(rgb=quantized_colours[i], population=colour_count[i]))

        return swatches


    @staticmethod
    def should_ignore_colour(rgb):
        return ColourUtils.should_ignore(ColourUtils.rbg_to_hsl(rgb))


if __name__ == '__main__':
    print __file__

    import cpalette

    #test_image = "/Users/josh/Desktop/paul-smith-visionary-crazy-golf-trafalgar-square-london-design-festival-dezeen-1568-01.jpg"
    test_image = "/Users/josh/Desktop/palette16.png"

    #img = ImageUtils.load_image(test_image)

    image = cpalette.CPalette.down_sample_img(ImageUtils.load_image(test_image), size=100)

    ColourQuantization.get_colours(image)

    # img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    # img = img.reshape((img.shape[0] * img.shape[1], 3))
    # mask = np.apply_along_axis(shouldIgnoreColor, 1, img)
    #
    # filtered_image = img[mask]
    #
    # print img.shape
    # print mask.shape
    # print filtered_image.shape

    # mask = filter(img[:,:]) # (1120, 1568)
    # print img.shape




    #print np.apply_along_axis(filter, 2, img).shape

    # quant, image = color_quantization(img)
    #
    # ImageUtils.show_image(np.hstack([quant, image]))


