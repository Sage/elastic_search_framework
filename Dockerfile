FROM ruby:3.2-alpine

RUN apk add --no-cache --update bash

COPY Gemfile elastic_search_framework.gemspec .
COPY lib/elastic_search_framework/version.rb ./lib/elastic_search_framework/

RUN apk add --no-cache --update --virtual .gem-builddeps make gcc libc-dev ruby-json \
    && bundle \
    && apk del .gem-builddeps

# Create application directory and set it as the WORKDIR.
ENV APP_HOME /elastic_search_framework
RUN mkdir -p $APP_HOME
WORKDIR $APP_HOME

COPY . $APP_HOME

RUN bundle install --system --binstubs
