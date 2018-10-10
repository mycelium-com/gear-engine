class ExchangeRateProvider < EnumerateIt::Base
  include EnumerateSymbols

  associate_symbols %i[
    bitpay
    bitstamp
    coinbase
    kraken
    okcoin
  ]
end
