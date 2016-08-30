
import requests
import json
import constants
import utils
import ConfigParser
import httplib2
import urllib
from data_manager import DataManager
import urllib2
from BeautifulSoup import BeautifulSoup, Comment
import re
import json
import platform
from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.common.by import By
import time


class InstagramWrapperAPI(object):
    """
    Usernames:
    method_inc

    Tags:
    #method_inc
    #uncertainty
    #beauty
    #vr
    """

    def __init__(self, username=None):
        config_parser = ConfigParser.RawConfigParser()
        config_parser.read(utils.get_full_file_path(constants.config_file))

        self.data_manager = DataManager()

        self.client_id = config_parser.get(constants.config_section, "instagram_client_id")
        self.client_secret = config_parser.get(constants.config_section, "instagram_client_secret")

        self.authenticated_account = None

        # self.set_access_token(username=username)

    def set_access_token(self, username):
        authenticated_accounts = self.data_manager.get_authenticated_accounts(service="instagram")
        if authenticated_accounts is None or len(authenticated_accounts) == 0:
            raise Exception("No authenticated accounts registered")

        if username is None:
            self.authenticated_account = authenticated_accounts[0]
        else:
            for authenticated_account in authenticated_accounts:
                if "user" in authenticated_account:
                    if authenticated_account["user"]["username"] == username:
                        self.authenticated_account = authenticated_account
                        break

        if self.authenticated_account is None:
            raise Exception("No matching authenticated accounts found")

    def get_recent_for_user(self, user_id):
        uri = "https://api.instagram.com/v1/users/{}/media/recent/?access_token={}".format(
            user_id,
            self.authenticated_account["access_token"]
        )

        h = httplib2.Http()

        headers = {'Content-type': 'application/x-www-form-urlencoded'}

        utils.Logger.info("requesting {}".format(uri))

        resp, content = h.request(uri=uri,
                                  method="GET",
                                  headers=headers)

        return json.loads(content)

    def parse_page(self, tag=None, username=None, max_id=None):

        if username is not None:
            uri = "https://www.instagram.com/{}".format(
                username
            )
        else:
            uri = "https://www.instagram.com/explore/tags/{}".format(
                tag
            )

        if max_id is not None:
            uri = "{}/?max_id={}".format(
                uri,
                max_id
            )

        utils.Logger.info("instagram_api.parse_page.polling {}".format(uri))
        utils.Logger.info("loading PhantomJS from {}".format(self._get_phantomjs_bin()))

        items = []

        driver = webdriver.PhantomJS(self._get_phantomjs_bin())
        driver.get(uri)

        if driver is None:
            raise Exception("Webdriver is null")

        driver.implicitly_wait(10)
        #assert "@l_d_f_official" in driver.title
        html = driver.page_source

        if html is None:
            raise Exception("html is null")

        utils.Logger.info("loaded html {}".format(html[:20]))

        soup = BeautifulSoup(html)

        rows = soup.findAll("div", {"class": "_myci9"})
        for row in rows:
            cells = row.findAll("a")
            for cell in cells:
                try:
                    href = cell["href"]
                    img_src = None
                    img_alt = None
                    img_elem = cell.find("img")
                    if img_elem is not None:
                        img_src = img_elem["src"]

                        try:
                            img_alt = img_elem["alt"]
                        except KeyError as e:
                            utils.Logger.error("Error parsing alt from item, {}".format(e))

                    item = {"id": href[3:-1], "href": href, "img_src": img_src, "img_alt": img_alt}

                    item["search_term"] = "username:{}".format(username) if username is not None else "tag:{}".format(tag)

                    items.append(item)
                except Exception as e:
                    utils.Logger.error("Error parsing item, {}".format(e))

        for item in items:
            try:
                if "href" in item and len(item["href"]) > 0:
                    self.parse_details_page(driver=driver, item=item)
            except Exception as e:
                utils.Logger.error("Failed to parse details pahe {} ERROR {}".format(item["href"], e))

        driver.close()

        try:
            driver.quit()
        except:
            pass

        anchors = soup.findAll("a")

        more_elem = None

        for anchor in anchors:
            if anchor.getText() == "Load more":
                more_elem = anchor
                break

        if more_elem is not None:
            prev_next_id = None
            href = more_elem["href"]

            if href is not None:
                p = re.compile("max_id=\w*")
                res = p.search(href)
                if res is not None:
                    group = res.group()
                    prev_next_id = group[7:]

            return items, prev_next_id
        else:
            return items, None

    def parse_details_page(self, driver, item):
        uri = "https://www.instagram.com{}".format(item["href"])

        utils.Logger.info("parse_details_page {}".format(uri))

        driver.get(uri)
        driver.implicitly_wait(10)
        time.sleep(10)
        html = driver.page_source
        soup = BeautifulSoup(html)

        time_elem = soup.find("time")
        if time_elem is not None:
            item["datetime"] = time_elem["datetime"]

        likes_span_elem = soup.find("span", {"class": "_tf9x3"})
        if likes_span_elem is not None:
            likes_span_elem_elem = likes_span_elem.find("span")
            if likes_span_elem_elem is not None:
                item["likes"] = likes_span_elem_elem.text

        # using XPath in Chrome
        # http://stackoverflow.com/questions/22571267/how-to-verify-an-xpath-expression-in-chrome-developers-tool-or-firefoxs-firebug
        # run $x('<XPath Expression>') in the console
        try:
            view_all_button = driver.find_elements(By.XPATH, '//*[@id="react-root"]/section/main/div/div/article/div[2]/ul/li[2]/button')
            if view_all_button is not None:
                view_all_button.click()
        except:
            pass

        ul_elem = soup.find("ul")
        if ul_elem is not None:
            list_items = ul_elem.findAll("li")
            for i in range(len(list_items)):
                is_comment = i > 0
                li = list_items[i]

                for element in li(text=lambda text: isinstance(text, Comment)):
                    element.extract()

                username_a = li.find("a")
                if username_a is None:
                    continue

                username = username_a.extract().getText()
                text_elem = li.find("span")
                text = text_elem.extract().getText()
                entity_elems = text_elem.findAll('a')

                entities = []

                for entity_elem in entity_elems:
                    entity_href = entity_elem["href"]
                    entity_text = entity_elem.extract().getText()

                    entities.append({
                        "href": entity_href,
                        "name": entity_text
                    })

                if is_comment:
                    if "comments" not in item:
                        item["comments"] = []

                    comment = {
                        "username": username,
                        "text": text
                    }

                    if len(entities) > 0:
                        comment["entities"] = entities

                    item["comments"].append(comment)
                else:
                    item["username"] = username
                    item["text"] = text

                    if len(entities) > 0:
                        item["entities"] = entities
                    else:
                        item["entities"] = []

        driver.back()
        time.sleep(5)

        return item

    def _get_phantomjs_bin(self):
        if platform.system() == "Darwin":
            return utils.get_full_file_path("dev_bin/phantomjs")
        else:
            return utils.get_full_file_path("bin/phantomjs")


if __name__ == '__main__':
    print "instagram_api.py"

    dm = DataManager()

    all_post_ids = dm.get_all_post_ids()

    api = InstagramWrapperAPI()

    # username = "l_d_f_official"
    # max_id = None
    # is_crawling = True
    # while is_crawling:
    #     items, prev_max_id = api.parse_page(username=username, max_id=max_id)
    #     insert_count = 0
    #     for item in items:
    #         if item["id"] not in all_post_ids:
    #             dm.put_post(item)
    #             insert_count += 1
    #
    #     if prev_max_id is None:
    #         is_crawling = False
    #     else:
    #         max_id = prev_max_id
    #
    #     print "inserted {} items".format(insert_count)

    tag = "ldf16"
    max_id = None
    is_crawling = True
    while is_crawling:
        items, prev_max_id = api.parse_page(tag=tag, max_id=max_id)
        insert_count = 0
        for item in items:
            if item["id"] not in all_post_ids:
                dm.put_post(item)
                insert_count += 1

        if prev_max_id is None:
            is_crawling = False
        else:
            max_id = prev_max_id

        print "inserted {} items".format(insert_count)



