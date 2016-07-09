
from PIL import Image
import numpy as np
import scipy
import scipy.cluster

from skimage import data, io, segmentation, color
from skimage.future import graph
from collections import namedtuple

import mmcq

Point = namedtuple('Point', ('coords', 'n', 'ct'))
Cluster = namedtuple('Cluster', ('points', 'center', 'n'))

class ImageUtils(object):
    """
    references:
    http://scikit-image.org/docs/dev/auto_examples/segmentation/plot_rag_merge.html#sphx-glr-auto-examples-segmentation-plot-rag-merge-py
    http://scikit-image.org/docs/dev/auto_examples/segmentation/plot_rag_mean_color.html#sphx-glr-auto-examples-segmentation-plot-rag-mean-color-py

    """

    @staticmethod
    def PIL2array(img):
        return np.array(img.getdata(), np.uint8).reshape(img.size[1], img.size[0], 3)

    @staticmethod
    def array2PIL(arr, size):
        mode = 'RGBA'
        arr = arr.reshape(arr.shape[0]*arr.shape[1], arr.shape[2])
        if len(arr[0]) == 3:
            arr = np.c_[arr, 255*np.ones((len(arr),1), np.uint8)]
        return Image.frombuffer(mode, size, arr.tostring(), 'raw', mode, 0, 1)

    @staticmethod
    def show_image(img_data):
        img = ImageUtils.array2PIL(img_data, (img_data.shape[1], img_data.shape[0]))
        img.show()

    @staticmethod
    def save_image(file_path, img_data):
        io.imsave(file_path, img_data)

    @staticmethod
    def load_image(filepath):
        return scipy.ndimage.imread(filepath)

    @staticmethod
    def segment_image(img, compactness=30, n_segments=400, kind='avg'):
        labels1 = segmentation.slic(img, compactness=compactness, n_segments=n_segments)
        processed_img = color.label2rgb(labels1, img, kind=kind)
        return processed_img

    @staticmethod
    def palette(img):
        """
        Return palette in descending order of frequency
        """
        arr = np.asarray(img)
        palette, index = np.unique(ImageUtils.asvoid(arr).ravel(), return_inverse=True)
        palette = palette.view(arr.dtype).reshape(-1, arr.shape[-1])
        count = np.bincount(index)
        order = np.argsort(count)
        return palette[order[::-1]]

    @staticmethod
    def asvoid(arr):
        """View the array as dtype np.void (bytes)
        This collapses ND-arrays to 1D-arrays, so you can perform 1D operations on them.
        http://stackoverflow.com/a/16216866/190597 (Jaime)
        http://stackoverflow.com/a/16840350/190597 (Jaime)
        Warning:
        >>> asvoid([-0.]) == asvoid([0.])
        array([False], dtype=bool)
        """
        arr = np.ascontiguousarray(arr)
        return arr.view(np.dtype((np.void, arr.dtype.itemsize * arr.shape[-1])))

    @staticmethod
    def get_points(img):
        points = []
        w, h = img.shape[1], img.shape[0]
        #palette, index = np.unique(ImageUtils.asvoid(img).ravel(), return_inverse=True)
        palette, index = np.unique(img, return_inverse=True)
        count = np.bincount(index)

        for count, color in img.getcolors(w * h):
            points.append(Point(color, 3, count))

        return points

    @staticmethod
    def get_dominate_colours(img, clusters=5):
        shape = img.shape

        # Reshape array of values to merge color bands.
        if len(shape) > 2:
            ar = img.reshape(scipy.product(shape[:2]), shape[2])

        # Get NUM_CLUSTERS worth of centroids.
        codes, _ = scipy.cluster.vq.kmeans(ar, clusters)

        original_codes = codes
        for low, hi in [(60, 200), (35, 230), (10, 250)]:
            codes = scipy.array([code for code in codes
                                 if not ((code[0] < low and code[1] < low and code[2] < low) or
                                         (code[0] > hi and code[1] > hi and code[2] > hi))])
            if not len(codes):
                codes = original_codes
            else:
                break

        # Assign codes (vector quantization). Each vector is compared to the centroids
        # and assigned the nearest one.
        vecs, _ = scipy.cluster.vq.vq(ar, codes)

        # Count occurences of each clustered vector.
        counts, bins = scipy.histogram(vecs, len(codes))

        # Show colors for each code in its hex value.
        colors = [''.join(chr(c) for c in code).encode('hex') for code in codes]
        total = scipy.sum(counts)
        color_dist = dict(zip(colors, [count / float(total) for count in counts]))
        print(color_dist)

        # Find the most frequent color, based on the counts.
        index_max = scipy.argmax(counts)
        peak = codes[index_max]
        color = ''.join(chr(c) for c in peak).encode('hex')



# ImageUtils.show_image(ImageUtils.load_image("data/test_3.jpg"))
# ImageUtils.show_image(ImageUtils.segment_image(ImageUtils.load_image("data/test_3.jpg"), compactness=20, n_segments=400))
#
# ImageUtils.show_image(ImageUtils.segment_image(ImageUtils.load_image("data/test_3.jpg"), compactness=200, n_segments=100))
#
# data = ImageUtils.palette(ImageUtils.load_image("data/test_3.jpg"))
# print data
#
# hist, bin_edges = np.histogram(ImageUtils.load_image("data/test_3.jpg"))
# print hist
# print "========"
# print bin_edges

save_file_path = "/Users/josh/Desktop/images/save_{}.jpg"

frames = 10.0

s_segments = 10000.
e_segments = 2.
segment_steps = (e_segments - s_segments) / frames

s_compactness = 400.
e_compactness = 2.
compactness_steps = (e_compactness - s_compactness) / frames

img = scipy.misc.imresize(ImageUtils.load_image("data/test_3.jpg"), (400,400))
ImageUtils.save_image(save_file_path.format(0), img)

for frame in range(int(frames)):
    segments = s_segments + segment_steps * frame
    compactness = s_compactness + compactness_steps * frame

    img = ImageUtils.segment_image(scipy.misc.imresize(ImageUtils.load_image("data/test_3.jpg"), (400,400)),
                                   compactness=int(compactness), n_segments=int(segments))
    ImageUtils.save_image(save_file_path.format(frame + 1), img)
    #ImageUtils.show_image(ImageUtils.segment_image(scipy.misc.imresize(ImageUtils.load_image("data/test_3.jpg"), (200,200)), compactness=200, n_segments=10000))

#print mmcq.get_palette_from_numpy_array(rgb_data=scipy.misc.imresize(ImageUtils.load_image("data/test_4.jpg"), (200, 200)))

#ImageUtils.get_points(img=scipy.misc.imresize(ImageUtils.load_image("data/test_3.jpg"), (200, 200)))

# http://charlesleifer.com/blog/using-python-and-k-means-to-find-the-dominant-colors-in-images/
# img = Image.open("data/test_3.jpg")
# w, h = img.size
# color = img.getcolors(w * h)
# print color