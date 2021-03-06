FROM ruby:2.6.3-stretch

ENV GEAR_ENGINE_PATH /gear-engine
RUN mkdir -p $GEAR_ENGINE_PATH
WORKDIR $GEAR_ENGINE_PATH

ENV BUILD_PACKAGES "build-essential libpq-dev"
RUN apt-get update \
  && apt-get install -y --fix-missing --no-install-recommends $BUILD_PACKAGES; \
  rm -rf /var/lib/apt/lists/*

COPY Gemfile* ./
RUN bundle install --without development test

COPY . ./

RUN rm vendor/cache/*.gem; \
    rm $GEM_HOME/cache/*.gem


ENV RAILS_ENV production
ENV RAILS_LOG_TO_STDOUT yes
ENV RAILS_SERVE_STATIC_FILES yes

# https://github.com/oleganza/btcruby/issues/29
RUN ln -nfs /usr/lib/x86_64-linux-gnu/libssl.so.1.0.2 /usr/lib/x86_64-linux-gnu/libssl.so; \
  mkdir -p $GEAR_ENGINE_PATH/tmp; \
  chown -R nobody: $GEAR_ENGINE_PATH/tmp

USER nobody

LABEL org.opencontainers.image.source=https://github.com/mycelium-com/gear-engine