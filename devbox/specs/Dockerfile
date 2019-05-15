FROM ruby:2.6.3-stretch

RUN apt-get update \
  && apt-get install -y --fix-missing --no-install-recommends \
    firefox-esr

# https://github.com/oleganza/btcruby/issues/29
RUN ln -nfs /usr/lib/x86_64-linux-gnu/libssl.so.1.0.2 /usr/lib/x86_64-linux-gnu/libssl.so