FROM ruby:latest

RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install nodejs -y
RUN apt-get install sqlite3 -y
RUN gem update --system
RUN gem install rails
RUN gem install rake
RUN gem install bundler
ONBUILD COPY . /opt/app
ONBUILD WORKDIR /opt/app
ONBUILD RUN bundle install
ONBUILD RUN rake
ONBUILD RUN rake db:migrate
ONBUILD RUN rake db:seed