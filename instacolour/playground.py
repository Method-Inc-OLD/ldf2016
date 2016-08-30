
from image_utils import ImageUtils
from colour_clustering import ColourClustering
import numpy as np
import cv2
from data_manager import DataManager

# def download_image(url):

def e_distance(col1, col2):
    import math
    col_diff = map(lambda a, b: (a-b)**2, col1, col2)
    print col_diff
    col_sum = reduce(lambda a, b: a + b, col_diff)
    print col_sum
    return math.sqrt(col_sum)


# http://stackoverflow.com/questions/596216/formula-to-determine-brightness-of-rgb-color
def luminance(a):
    return 0.2126*float(a[0]) + 0.7152*float(a[1]) + 0.0722*float(a[2])


def luminance2(a):
    return 0.299*float(a[0]) + 0.587*float(a[1]) + 0.114*float(a[2])


def luminance3(a):
    import math
    return math.sqrt((0.299*float(a[0]))**2 + (0.587*float(a[1]))**2 + (0.114*float(a[2]))**2)


def test_colour_swatch():
    dm = DataManager()
    posts = dm.posts = dm.get_all_posts()

    img = ColourClustering.create_colour_swatch_from_posts(posts=posts)
    ImageUtils.show_image(img)

    print ColourClustering.colour_cluster_from_image(
        clusters=-1,
        img=img,
        colour_space='lab'
    )

    #encode_param = [int(cv2.IMWRITE_JPEG_QUALITY), 90]
    #result, encimg = cv2.imencode('.jpg', img, encode_param)


def test_hist():
    test_image = "/Users/josh/Desktop/paul-smith-visionary-crazy-golf-trafalgar-square-london-design-festival-dezeen-1568-01.jpg"

    hist = cv2.calcHist([ImageUtils.load_image(test_image)], [2], None, [256], [0, 256])

    print hist.shape
    print hist[0]



if __name__ == '__main__':
    print __file__

    test_hist()

    #test_colour_swatch()

    #test_image = "/Users/josh/Desktop/London-Design-Festival-Homes-Gardens-21.jpg"
    #test_image = "/Users/josh/Desktop/images.jpg"
    #test_image = "/Users/josh/Desktop/hlounge_190914_01-630x420.jpg"
    #test_image = "/Users/josh/Desktop/paul-smith-visionary-crazy-golf-trafalgar-square-london-design-festival-dezeen-1568-01.jpg"
    #test_image = "/Users/josh/Desktop/red.jpg"

    #ImageUtils.show_image(ImageUtils.load_image(test_image))
    #ImageUtils.show_image(ImageUtils.segment_image(ImageUtils.load_image(test_image), compactness=20, n_segments=300))

    #ImageUtils.show_image(ImageUtils.segment_image(ImageUtils.load_image(test_image), compactness=20, n_segments=200))

    #ImageUtils.show_image(ImageUtils.segment_image(ImageUtils.load_image(test_image), compactness=200, n_segments=100))

    # for i in range(1000, 10, -50):
    #     print i
    #     ImageUtils.show_image(ImageUtils.segment_image(ImageUtils.load_image(test_image), compactness=20, n_segments=i))

    #img = cv2.imread(test_image, cv2.IMREAD_COLOR)

    # ColourClustering.colour_cluster(
    #     clusters=-1,
    #     image_url="http://retaildesignblog.net/wp-content/uploads/2014/09/Heineken-Pop-Up-City-Lounge-at-London-Design-Festival-London-UK-04.jpg",
    #     colour_space='lab'
    # )

    # print ColourClustering.colour_cluster(
    #     clusters=-1,
    #     image_url="http://littlebigbell.com/wp-content/uploads/2015/10/Camille-Walala-at-Aria-London-Design-Festival-2015-photo-by-Little-Big-Bell1.jpg",
    #     colour_space='lab'
    # )

    # print ColourClustering.colour_cluster(
    #     clusters=-1,
    #     image_url="https://static.dezeen.com/uploads/2016/06/paul-smith-visionary-crazy-golf-trafalgar-square-london-design-festival-dezeen-1568-01.jpg",
    #     colour_space='lab'
    # )

    # print img[0,0,:]

    # img_l = np.apply_along_axis(luminance3, 2, img[:,:,])
    #print type(img_l)
    #img_l *= 255
    #print img_l
    # ImageUtils.show_image(img)
    #ImageUtils.show_image(img_l)

    # img_lab = cv2.cvtColor(img, cv2.COLOR_BGR2LAB)
    # ImageUtils.show_image(img_lab)

    # img_lab = cv2.cvtColor(img, cv2.COLOR_RGB2LAB)
    # ImageUtils.show_image(img_lab)

    # img_hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
    # ImageUtils.show_image(img_hsv)
    #
    # img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    # ImageUtils.show_image(img_rgb)

    # print ColourClustering.colour_cluster_from_image(
    #     img=img,
    #     clusters=9,
    #     colour_space='lab'
    # )

    #print img[:,:,]
    #img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    # np.apply_along_axis(luminance, 1, img)
    # ImageUtils.show_image(img)


    # print "==="
    # print ColourClustering.colour_cluster_from_image(img=ImageUtils.segment_image(ImageUtils.load_image(test_image), compactness=20, n_segments=300))
    # print "==="
    #print ColourClustering.colour_cluster_from_image(img=ImageUtils.load_image(test_image), clusters=-1)


    # data = ImageUtils.palette(ImageUtils.load_image(test_image))
    # # print data
    #
    # hist, bin_edges = np.histogram(ImageUtils.segment_image(ImageUtils.load_image(test_image), compactness=20, n_segments=400), bins='auto')
    # print hist.shape
    # print hist
    # print "========"
    # print bin_edges

    # print e_distance([78,135,89], [48,110,74])