
import ConfigParser
import os
from apscheduler.schedulers.blocking import BlockingScheduler
import requests
import json
import utils
import constants
import datetime
from instagram_api import InstagramWrapperAPI
from data_manager import DataManager
from colour_clustering import ColourClustering
from cpalette import CPalette
import cv2

basedir = os.path.abspath(os.path.dirname(__file__))

sched = BlockingScheduler()


# @sched.scheduled_job('cron', day_of_week='mon-sun', minute=180)
@sched.scheduled_job('cron', day_of_week='mon-sun', minute=10)
def timed_job():

    start_time = datetime.datetime.now()
    utils.Logger.info('Running timed_job - starting {}'.format(start_time))

    crawl_instagram()
    extract_dominate_colours()

    end_time = datetime.datetime.now()
    et = end_time - start_time
    utils.Logger.info('Finished timed_job, job took {} seconds'.format(et.seconds))


def crawl_instagram():
    utils.Logger.info("starting crawl_instagram")

    search_terms = get_search_terms()

    # get data manager
    dm = DataManager()

    all_post_ids = dm.get_all_post_ids()
    api = InstagramWrapperAPI()

    for search_term in search_terms:
        utils.Logger.info(
            'Querying instagram with search term {} for {}'.format(search_term["term"], search_term["type"]))

        max_id = None
        is_crawling = True
        while is_crawling:
            tag = None
            username = None

            if search_term["type"] == "username":
                username = search_term["term"]
            else:
                tag = search_term["term"]

            items, prev_max_id = api.parse_page(username=username, tag=tag, max_id=max_id)
            insert_count = 0
            for item in items:
                if item["id"] not in all_post_ids:
                    dm.put_post(item)
                    insert_count += 1
                else:
                    utils.Logger.info('Existing Crawler - found item already parsed')
                    is_crawling = False

            if prev_max_id is None:
                is_crawling = False
            else:
                max_id = prev_max_id

            utils.Logger.info("inserted {} items".format(insert_count))

    utils.Logger.info("finished crawl_instagram")


def extract_dominate_colours():
    utils.Logger.info("Starting extract_dominate_colours")
    dm = DataManager()

    posts = dm.get_posts_with_no_cluster_analysis()

    for post in posts:
        if "img_src" not in post:
            continue

        img_src = post["img_src"]

        if img_src is None or len(img_src) == 0:
            continue

        img = ColourClustering.fetch_image(img_src)

        if img is None or len(img.shape) == 0 or img.shape[0] == 0:
            print("image {} is null".format(img_src))
            continue

        img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

        cpalette = CPalette.generate_with_android_colour_cut_quantizer(img, num_colours=6)

        if cpalette is None:
            continue

        cpalette_dict = cpalette.to_dict()

        if "swatches" in cpalette_dict:
            post['rgb_clusters'] = cpalette_dict['swatches']

        post["palette"] = {}
        for key in cpalette_dict.keys():
            if key == "swatches" or key == "highest_population":
                continue

            post["palette"][key] = cpalette_dict[key]

        try:
            dm.update_post(post)
        except Exception as e:
            print("{}".format(e))

    utils.Logger.info("Finished extract_dominate_colours")


def get_search_terms():
    config_parser = ConfigParser.RawConfigParser()
    config_parser.read(utils.get_full_file_path(constants.config_file))

    usernames = config_parser.get(constants.config_section, "instafram_usernames").split(",")
    tags = config_parser.get(constants.config_section, "instafram_tags").split(",")

    search_terms = []

    for username in usernames:
        search_terms.append({
            "type": "username",
            "term": username
        })

    for tag in tags:
        search_terms.append({
            "type": "tag",
            "term": tag
        })

    return search_terms


sched.start()

#extract_dominate_colours()
# crawl_instagram()
