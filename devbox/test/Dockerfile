FROM --platform=linux/amd64 ruby:2.7.7-bullseye

RUN apt-get update \
  && apt-get install -y --fix-missing --no-install-recommends \
    firefox-esr

RUN gem install bundler:2.3.26
