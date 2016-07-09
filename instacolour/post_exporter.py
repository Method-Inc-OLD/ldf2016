

from data_manager import DataManager
import csv

if __name__ == '__main__':
    print __file__

    dm = DataManager()

    username = "l_d_f_official"
    #users_posts = dm.get_users_posts(username=username)
    users_posts = dm.get_all_posts()

    count = 0

    # https://docs.python.org/2/library/csv.html
    with open('export/posts_2.csv', 'wb') as csvfile:
        csv_writer = csv.writer(csvfile)

        # write header
        csv_writer.writerow([
            "id",
            "username",
            "text",
            "datetime",
            "img_src",
            "likes",
            "entities"
        ])

        for post in users_posts:

            if "likes" not in post:
                post["likes"] = 0
            else:
                if type(post["likes"]) is not int:
                    post["likes"] = int(post["likes"].replace(",", ""))

            post["likes"] = int(post["likes"])

            hashtags = []
            if "entities" in post:
                hashtags = [entity["name"].lower() for entity in post["entities"]]

            hastags_string = " ".join(hashtags)

            csv_writer.writerow([
                post['id'],
                post['username'],
                post['text'].replace(",", " ").encode('utf-8'),
                post['datetime'],
                post['img_src'],
                post['likes'],
                hastags_string.encode('utf-8')
            ])

            count += 1

    print "finished exporting {} posts to csv".format(count)
