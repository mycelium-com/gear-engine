class BlockchainNetwork < EnumerateIt::Base
  include EnumerateSymbols

  associate_symbols %i[
    BTC
    BTC_TEST
    BCH
    BCH_TEST
  ]
end
