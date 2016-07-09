
### Depedencies 
https://github.com/facebookarchive/python-instagram


### Virtual Environment 
source ~/.virtualenvs/instacolour/bin/activate

### References 
https://www.instagram.com/developer/
http://downloadsfolder.jamiemclellan.com/

### Instagram Auth callback 
instacolour.herokuapp.com/instagramauth

#### Instafram Libraries
https://github.com/facebookarchive/python-instagram
https://github.com/rarcega/instagram-scraper
http://nbyim.com/monitor-instagram-accounts-without-using-api/
https://github.com/helloitsim/InstAnalytics

### Scheduling 
https://apscheduler.readthedocs.io/en/latest/userguide.html

## Heroku
pip freeze > requirements.txt
(on other environment: pip install -r requirements.txt)
 
### Buildpacks 
https://github.com/thenovices/heroku-buildpack-scipy
https://blog.dbrgn.ch/2013/6/18/heroku-buildpack-numpy-scipy-scikit-learn/

https://github.com/kennethreitz/conda-buildpack

https://github.com/hdachev/heroku-buildpack-opencv

### Init 
https://dashboard.heroku.com/apps/octothorpesrv/deploy/heroku-git

Install the Heroku Toolbelt

Download and install the Heroku Toolbelt or learn more about the Heroku Command Line Interface.

If you haven't already, log in to your Heroku account and follow the prompts to create a new SSH public key.

$ heroku login
Create a new Git repository

Initialize a git repository in a new or existing directory

$ cd my-project/
$ git init
$ heroku git:remote -a instacolour
Deploy your application

Commit your code to the repository and deploy it to Heroku using Git.

$ git add .
$ git commit -am "make it better"
$ git push heroku master

set git remote heroku to https://git.heroku.com/instacolour.git

## Instafram 
https://www.instagram.com/developer/endpoints/tags/#get_tags

## Colour Processing 
Medium Cut Algorithm  
https://github.com/admire93/mmcq.py
https://github.com/mvanveen/mcut
https://github.com/sergeyk/rayleigh/blob/master/rayleigh/palette.py


## Examples 
http://lokeshdhakar.com/projects/color-thief/
https://color.adobe.com/create/image/
http://colorify.rocks/

## LDW Feeds
https://uk.pinterest.com/dezeen/london-design-festival-2015/
https://www.instagram.com/l_d_f_official/
https://twitter.com/l_d_f?lang=en-gb

## Misc 
http://www.pyimagesearch.com/2014/12/08/adding-web-interface-image-search-engine-flask/

Instagram user_id lookup 
http://jelled.com/instagram/lookup-user-id#

## phantomjs 
https://github.com/stomita/heroku-buildpack-phantomjs
http://phantomjs.org/download.html
