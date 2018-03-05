#!/bin/bash

apt-get update -y
apt-get upgrade -y
apt-get install sudo -y
yes 1 | apt-get install postfix -y
apt-get install -y build-essential zlib1g-dev libyaml-dev libssl-dev libgdbm-dev libre2-dev
apt-get install -y libreadline-dev libncurses5-dev libffi-dev curl openssh-server checkinstall
apt-get install -y libxml2-dev libxslt-dev libcurl4-openssl-dev libicu-dev logrotate rsync python-docutils pkg-config cmake
apt-get install -y git-core
apt-get install -y libpcre3 libpcre3-dev
apt-get install ruby ruby-dev -y
apt-get install emacs-nox -y
gem install bundler --no-ri --no-rdoc
apt-get install golang -y
curl --location https://deb.nodesource.com/setup_7.x | sudo bash -
apt-get install -y nodejs
curl --silent --show-error https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
apt-get update
apt-get install yarn
adduser --disabled-login --gecos 'GitLab' git
apt-get install -y postgresql postgresql-client libpq-dev postgresql-contrib
/etc/init.d/postgresql restart

sudo -u postgres psql -d template1 -c "CREATE USER git CREATEDB PASSWORD 'iaintgettingpaidenoughforthisshit';"
sudo -u postgres psql -d template1 -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;"
sudo -u postgres psql -d template1 -c "CREATE DATABASE gitlabhq_production OWNER git;"
apt-get install -y redis-server
sudo usermod -aG redis git
cd /home/git
sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab-ce.git -b 10-5-stable gitlab
cd /home/git/gitlab
sudo -u git -H cp config/gitlab.yml.example config/gitlab.yml
sudo -u git -H cp config/secrets.yml.example config/secrets.yml
sudo -u git -H chmod 0600 config/secrets.yml
sudo chown -R git log/
sudo chown -R git tmp/
sudo chmod -R u+rwX,go-w log/
sudo chmod -R u+rwX tmp/
sudo chmod -R u+rwX tmp/pids/
sudo chmod -R u+rwX tmp/sockets/
sudo -u git -H mkdir public/uploads/
sudo chmod 0700 public/uploads
sudo chmod -R u+rwX builds/
sudo chmod -R u+rwX shared/artifacts/
sudo chmod -R ug+rwX shared/pages/
sudo -u git -H cp config/unicorn.rb.example config/unicorn.rb
nproc
sudo -u git -H cp config/initializers/rack_attack.rb.example config/initializers/rack_attack.rb
sudo -u git -H git config --global core.autocrlf input
sudo -u git -H git config --global gc.auto 0
sudo -u git -H git config --global repack.writeBitmaps true
sudo -u git -H git config --global receive.advertisePushOptions true
sudo -u git -H cp config/resque.yml.example config/resque.yml
sudo -u git cp config/database.yml.postgresql config/database.yml
sudo -u git -H sed -i.bak -e 's/"secure password"/''"iaintgettingpaidenoughforthisshit"''/g' config/database.yml
sudo -u git -H chmod o-rwx config/database.yml
sudo -u git -H bundle install -j3 --deployment --without development test mysql aws kerberos

sudo -u git -H bundle exec rake gitlab:shell:install REDIS_URL=unix:/var/run/redis/redis.sock RAILS_ENV=production SKIP_STORAGE_VALIDATION=true
#sudo -u git -H editor /home/git/gitlab-shell/config.yml
sudo -u git -H bundle exec rake "gitlab:workhorse:install[/home/git/gitlab-workhorse]" RAILS_ENV=production
#=-------------------------------------------
cp /etc/redis/redis.conf /etc/redis/redis.conf.orig
sed 's/^port .*/port 0/' /etc/redis/redis.conf.orig | sudo tee /etc/redis/redis.conf
echo 'unixsocket /var/run/redis/redis.sock' | sudo tee -a /etc/redis/redis.conf
echo 'unixsocketperm 770' | sudo tee -a /etc/redis/redis.conf
mkdir /var/run/redis
chown redis:redis /var/run/redis
chmod 755 /var/run/redis
if [ -d /etc/tmpfiles.d ]; then
  echo 'd  /var/run/redis  0755  redis  redis  10d  -' | sudo tee -a /etc/tmpfiles.d/redis.conf
fi
sudo service redis-server restart
#=-------------------------------------------
yes yes | sudo -u git -H bundle exec rake gitlab:setup RAILS_ENV=production
sudo cp lib/support/init.d/gitlab /etc/init.d/gitlab
sudo update-rc.d gitlab defaults 21
sudo -u git -H bundle exec rake "gitlab:gitaly:install[/home/git/gitaly]" RAILS_ENV=production
sudo chmod 0700 /home/git/gitlab/tmp/sockets/private
sudo chown git /home/git/gitlab/tmp/sockets/private
sudo cp lib/support/logrotate/gitlab /etc/logrotate.d/gitlab
sudo -u git -H bundle exec rake gitlab:env:info RAILS_ENV=production
sudo -u git -H bundle exec rake gettext:compile RAILS_ENV=production
sudo -u git -H yarn install --production --pure-lockfile
sudo -u git -H bundle exec rake gitlab:assets:compile RAILS_ENV=production NODE_ENV=production
sudo apt-get install -y nginx
echo '## GitLab
##
## Lines starting with two hashes (##) are comments with information.
## Lines starting with one hash (#) are configuration parameters that can be uncommented.
##
##################################
##        CONTRIBUTING          ##
##################################
##
## If you change this file in a Merge Request, please also create
## a Merge Request on https://gitlab.com/gitlab-org/omnibus-gitlab/merge_requests
##
###################################
##         configuration         ##
###################################
##
## See installation.md#using-https for additional HTTPS configuration details.

upstream gitlab-workhorse {
  # Gitlab socket file,
  # for Omnibus this would be: unix:/var/opt/gitlab/gitlab-workhorse/socket
  server unix:/home/git/gitlab/tmp/sockets/gitlab-workhorse.socket fail_timeout=0;
}

map $http_upgrade $connection_upgrade_gitlab {
    default upgrade;
    '\'\''      close;
}

#### NGINX 'combined' log format with filtered query strings
##log_format gitlab_access $remote_addr - $remote_user [$time_local] "$request_method $gitlab_filtered_request_uri $server_protocol" $status $body_bytes_sent "$gitlab_filtered_http_referer" "$http_user_agent";
##
#### Remove private_token from the request URI
### In:  /foo?private_token=unfiltered&authenticity_token=unfiltered&rss_token=unfiltered&...
### Out: /foo?private_token=[FILTERED]&authenticity_token=unfiltered&rss_token=unfiltered&...
##map $request_uri $gitlab_temp_request_uri_1 {
##  default $request_uri;
##  ~(?i)^(?<start>.*)(?<temp>[\?&]private[\-_]token)=[^&]*(?<rest>.*)$ "$start$temp=[FILTERED]$rest";
##}
##
#### Remove authenticity_token from the request URI
### In:  /foo?private_token=[FILTERED]&authenticity_token=unfiltered&rss_token=unfiltered&...
### Out: /foo?private_token=[FILTERED]&authenticity_token=[FILTERED]&rss_token=unfiltered&...
##map $gitlab_temp_request_uri_1 $gitlab_temp_request_uri_2 {
##  default $gitlab_temp_request_uri_1;
##  ~(?i)^(?<start>.*)(?<temp>[\?&]authenticity[\-_]token)=[^&]*(?<rest>.*)$ "$start$temp=[FILTERED]$rest";
##}
##
#### Remove rss_token from the request URI
### In:  /foo?private_token=[FILTERED]&authenticity_token=[FILTERED]&rss_token=unfiltered&...
### Out: /foo?private_token=[FILTERED]&authenticity_token=[FILTERED]&rss_token=[FILTERED]&...
##map $gitlab_temp_request_uri_2 $gitlab_filtered_request_uri {
##  default $gitlab_temp_request_uri_2;
##  ~(?i)^(?<start>.*)(?<temp>[\?&]rss[\-_]token)=[^&]*(?<rest>.*)$ "$start$temp=[FILTERED]$rest";
##}
##
#### A version of the referer without the query string
##map $http_referer $gitlab_filtered_http_referer {
##  default $http_referer;
##  ~^(?<temp>.*)\? $temp;
##}

## Normal HTTP host
server {
  ## Either remove ''default_server'' from the listen line below,
  ## or delete the /etc/nginx/sites-enabled/default file. This will cause gitlab
  ## to be served if you visit any address that your server responds to, eg.
  ## the ip address of the server (http://x.x.x.x/)n 0.0.0.0:80 default_server;
  listen 0.0.0.0:80 default_server;
  listen [::]:80 default_server;
  server_name YOUR_SERVER_FQDN; ## Replace this with something like gitlab.example.com
  server_tokens off; ## Don''t show the nginx version number, a security best practice

  ## See app/controllers/application_controller.rb for headers set

  ## Real IP Module Config
  ## http://nginx.org/en/docs/http/ngx_http_realip_module.html
  real_ip_header X-Real-IP; ## X-Real-IP or X-Forwarded-For or proxy_protocol
  real_ip_recursive off;    ## If you enable 'on'
  ## If you have a trusted IP address, uncomment it and set it
  # set_real_ip_from YOUR_TRUSTED_ADDRESS; ## Replace this with something like 192.168.1.0/24

  ## Individual nginx logs for this GitLab vhost
  access_log  /var/log/nginx/gitlab_access.log;
  error_log   /var/log/nginx/gitlab_error.log;

  location / {
    client_max_body_size 0;
    gzip off;
 ## https://github.com/gitlabhq/gitlabhq/issues/694
    ## Some requests take more than 30 seconds.
    proxy_read_timeout      300;
    proxy_connect_timeout   300;
    proxy_redirect          off;

    proxy_http_version 1.1;

    proxy_set_header    Host                $http_host;
    proxy_set_header    X-Real-IP           $remote_addr;
    proxy_set_header    X-Forwarded-For     $proxy_add_x_forwarded_for;
    proxy_set_header    X-Forwarded-Proto   $scheme;
    proxy_set_header    Upgrade             $http_upgrade;
    proxy_set_header    Connection          $connection_upgrade_gitlab;

    proxy_pass http://gitlab-workhorse;
  }
 error_page 404 /404.html;
  error_page 422 /422.html;
  error_page 500 /500.html;
  error_page 502 /502.html;
  error_page 503 /503.html;
  location ~ ^/(404|422|500|502|503)\.html$ {
    # Location to the Gitlab''s public directory,
    # for Omnibus this would be: /opt/gitlab/embedded/service/gitlab-rails/public.
    root /home/git/gitlab/public;
    internal;
  }
}
' > /etc/nginx/sites-available/gitlab
sudo ln -s /etc/nginx/sites-available/gitlab /etc/nginx/sites-enabled/gitlab
mv /etc/nginx/sites-available/default /etc/nginx/default.bak
nginx -t
