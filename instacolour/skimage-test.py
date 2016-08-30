"""
http://scikit-image.org/docs/dev/auto_examples/segmentation/plot_ncut.html#sphx-glr-auto-examples-segmentation-plot-ncut-py
http://scikit-image.org/docs/dev/auto_examples/segmentation/plot_rag_mean_color.html#sphx-glr-auto-examples-segmentation-plot-rag-mean-color-py
http://scikit-image.org/docs/dev/auto_examples/segmentation/plot_rag_merge.html#sphx-glr-auto-examples-segmentation-plot-rag-merge-py
"""

from skimage import data, io, segmentation, color
from skimage.future import graph
from matplotlib import pyplot as plt
from skimage.transform import resize

test_image = "/Users/josh/Desktop/ldf_test.jpg"

#img = data.coffee()
img = io.imread(test_image)
img = resize(img, (img.shape[0] * 0.5, img.shape[1] * 0.5))

labels1 = segmentation.slic(img, n_segments=6, compactness=100000.0, convert2lab=True, enforce_connectivity=True)
out1 = color.label2rgb(labels1, img, kind='avg')

# g = graph.rag_mean_color(img, labels1, mode='similarity')
# labels2 = graph.cut_normalized(labels1, g)
# out2 = color.label2rgb(labels2, img, kind='avg')

# plt.figure()
# io.imshow(img)

plt.figure()
io.imshow(out1)

# plt.figure()
# io.imshow(out2)

io.show()