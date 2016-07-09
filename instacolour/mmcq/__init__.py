#! -*- coding: utf-8 -*-
from contextlib import contextmanager

from .constant import SIGBITS
from .quantize import mmcq


__version__ = (0, 0, 1)
version = '{}.{}.{}'.format(*__version__)


@contextmanager
def get_palette(color_count=10, quality=10, **kwards):
    from wand.image import Image, Color
    if not any(['filename' in kwards, 'blob' in kwards, 'file' in kwards]):
        raise Exception('One of `filename`, `blob`, `file` MUST required.')

    with Image(**kwards) as image:
        colors = []
        image.resize(200, 200)
        for x in range(0, image.height):
            for y in range(0, image.width, quality):
                color = image[x][y]
                r = color.red_int8
                g = color.green_int8
                b = color.blue_int8
                a = color.alpha_int8
                if r < 250 and g < 250 and b < 250:
                    colors.append((r, g, b))

        c_map = mmcq(colors, color_count)
        yield c_map.palette

#@contextmanager
def get_palette_from_numpy_array(color_count=10, rgb_data=None):
    colors = []
    for x in range(0, rgb_data.shape[1]):
        for y in range(0, rgb_data.shape[0]):
            rgb = rgb_data[y,x]
            r = rgb[0]
            g = rgb[1]
            b = rgb[2]
            if r < 250 and g < 250 and b < 250:
                colors.append((r, g, b))

    c_map = mmcq(colors, color_count)
    return c_map.palette


def get_dominant_color(color_count=5, quality=10, **kwards):
    with get_palette(color_count, quality, **kwards) as palette:
        return palette[0]
