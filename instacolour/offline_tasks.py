
from data_manager import DataManager
from colour_clustering import ColourClustering
import time
from cpalette import CPalette


def rebuild_colour_clusters_for_all_images():
    print("starting rebuild_colour_clusters_for_all_images")

    dm = DataManager()

    update_count = 0
    skipped_count = 0

    posts = dm.get_all_posts()

    for post in posts:
        # has image url?
        if 'img_src' not in post:
            skipped_count += 1
            continue

        # remove 'rgb_clusters'
        if 'rgb_clusters' in post:
            del post['rgb_clusters']

        img_src = post['img_src']

        try:
            # result = ColourClustering.colour_cluster(
            #     clusters=-1,
            #     image_url=img_src,
            #     colour_space='lab',
            #     min_thresh=35,
            #     max_thresh=100
            # )
            img = ColourClustering.fetch_image(img_src)

            if img is None or len(img.shape) == 0 or img.shape[0] == 0:
                print("image {} is null".format(img_src))
                continue

            cpalette = CPalette.generate_with_android_colour_cut_quantizer(img, num_colours=6)

            if cpalette is None:
                skipped_count += 1
                continue

            cpalette_dict = cpalette.to_dict()

        except Exception as e:
            print("{}".format(e))
            result = None

        # if result is None or 'colour_clusters' not in result:
        #     skipped_count += 1
        # else:
        #     colour_clusters = result['colour_clusters']
        #     post['rgb_clusters'] = colour_clusters
        #     update_count += 1

        if "swatches" in cpalette_dict:
            post['rgb_clusters'] = cpalette_dict['swatches']
            update_count += 1

        post["palette"] = {}
        for key in cpalette_dict.keys():
            if key == "swatches" or key == "highest_population":
                continue

            post["palette"][key] = cpalette_dict[key]

        try:
            dm.update_post(post)
        except Exception as e:
            print("{}".format(e))

        print "finished updating image {}".format(img_src)
        time.sleep(1)

    print("finished rebuild_colour_clusters_for_all_images, updated {}, skipped {}".format(
        update_count,
        skipped_count
    ))


if __name__ == '__main__':
    print __file__

    rebuild_colour_clusters_for_all_images()

