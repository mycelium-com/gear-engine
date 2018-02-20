FROM ruby:2.5.0

ENV GEAR_ENGINE_PATH /gear-engine
RUN mkdir -p $GEAR_ENGINE_PATH
WORKDIR $GEAR_ENGINE_PATH

ENV BUILD_PACKAGES "build-essential libpq-dev"
RUN apt-get update \
  && apt-get install -y --fix-missing --no-install-recommends \
    $BUILD_PACKAGES

COPY Gemfile* ./
COPY vendor ./vendor
RUN bundle install --without development test

COPY . ./

# https://github.com/oleganza/btcruby/issues/29
RUN ln -nfs /usr/lib/x86_64-linux-gnu/libssl.so.1.0.2 /usr/lib/x86_64-linux-gnu/libssl.so

ENV RAILS_ENV production

#RUN rm vendor/cache/*.gem \
#  && rm /usr/local/bundle/cache/*.gem \
#  && apt-get remove -y --purge $BUILD_PACKAGES \
#  && apt-get autoremove -y \
#  && rm -rf /var/lib/apt/lists/*