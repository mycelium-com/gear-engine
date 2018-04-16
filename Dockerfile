FROM ruby:2.5.1-stretch AS build

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

RUN rm vendor/cache/*.gem
RUN rm $GEM_HOME/cache/*.gem


#############################

FROM ruby:2.5.1-stretch AS production

ENV RAILS_ENV production
ENV RAILS_LOG_TO_STDOUT yes
ENV RAILS_SERVE_STATIC_FILES yes
ENV GEAR_ENGINE_PATH /gear-engine
COPY --from=build $GEM_HOME $GEM_HOME
COPY --from=build $GEAR_ENGINE_PATH $GEAR_ENGINE_PATH

# https://github.com/oleganza/btcruby/issues/29
RUN ln -nfs /usr/lib/x86_64-linux-gnu/libssl.so.1.0.2 /usr/lib/x86_64-linux-gnu/libssl.so \
  && mkdir -p $GEAR_ENGINE_PATH/tmp \
  && chown -R nobody: $GEAR_ENGINE_PATH/tmp

WORKDIR $GEAR_ENGINE_PATH
USER nobody