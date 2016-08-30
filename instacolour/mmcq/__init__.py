#! -*- coding: utf-8 -*-
from contextlib import contextmanager

from .constant import SIGBITS
from .quantize import mmcq
import cv2
import numpy as np


__version__ = (0, 0, 1)
version = '{}.{}.{}'.format(*__version__)


#@contextmanager
def get_palette(image, color_count=16, quality=10, convert_to_rgb=True):
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

    c_map = mmcq(colors, color_count)
    return c_map.palette


def get_dominant_color(color_count=5, quality=10, **kwards):
    with get_palette(color_count, quality, **kwards) as palette:
        return palette[0]
