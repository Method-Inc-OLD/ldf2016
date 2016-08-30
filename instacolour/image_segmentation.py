"""
references:
http://opencv-python-tutroals.readthedocs.io/en/latest/py_tutorials/py_imgproc/py_watershed/py_watershed.html#watershed
http://www.pyimagesearch.com/2015/11/02/watershed-opencv/

"""

from image_utils import ImageUtils
from skimage.feature import peak_local_max
from skimage.morphology import watershed
from scipy import ndimage
import numpy as np
import matplotlib.pyplot as plt
import cv2

if __name__ == '__main__':
    print __file__

    # filepath = "/Users/josh/Desktop/p10077400_b_v8_ab.jpg"
    # filepath = "/Users/josh/Desktop/13392819_879208228890924_1029159944_n.jpg"
    filepath = "/Users/josh/Desktop/test_2.jpg"

    img = cv2.imread(filepath)
    # img = cv2.resize(img, (int(0.3 * img.shape[1]), int(0.3 * img.shape[0])), interpolation=cv2.INTER_CUBIC)

    # gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    # ret, thresh = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)

    shifted = cv2.pyrMeanShiftFiltering(img, 21, 51)
    # cv2.imshow("Input", shifted)
    # cv2.waitKey()
    gray = cv2.cvtColor(shifted, cv2.COLOR_BGR2GRAY)
    ret, thresh = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY | cv2.THRESH_OTSU)

    D = ndimage.distance_transform_edt(thresh)
    localMax = peak_local_max(D, indices=False, min_distance=20, labels=thresh)

    markers = ndimage.label(localMax, structure=np.ones((3, 3)))[0]
    labels = watershed(-D, markers, mask=thresh)
    print("[INFO] {} unique segments found".format(len(np.unique(labels)) - 1))

    for label in np.unique(labels):
        # if the label is zero, we are examining the 'background'
        # so simply ignore it
        if label == 0:
            continue

        # otherwise, allocate memory for the label region and draw
        # it on the mask
        mask = np.zeros(gray.shape, dtype="uint8")
        mask[labels == label] = 255

        # detect contours in the mask and grab the largest one
        cnts = cv2.findContours(mask.copy(), cv2.RETR_EXTERNAL,
                                cv2.CHAIN_APPROX_SIMPLE)[-2]
        c = max(cnts, key=cv2.contourArea)

        # draw a circle enclosing the object
        ((x, y), r) = cv2.minEnclosingCircle(c)
        # cv2.circle(img, (int(x), int(y)), int(r), (0, 255, 0), 2)
        cv2.drawContours(img, cnts, -1, (0, 255, 0), 3)
        cv2.putText(img, "#{}".format(label), (int(x) - 10, int(y)),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 0, 255), 2)

    cv2.imshow('Dense feature detector', img)
    cv2.waitKey()
    #ImageUtils.show_image(img)

