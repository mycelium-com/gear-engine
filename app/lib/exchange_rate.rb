# frozen_string_literal: true

module ExchangeRate

  KEY_PREFIX = 'ExchangeRatePair_'

  class Pair < Dry::Struct

    attributes(
      src:  Dry::Types['strict.string'],
      pair: Dry::Types['strict.array'].of(Dry::Types['strict.symbol']),
      rate: Dry::Types['strict.decimal'],
      time: Dry::Types['strict.time']
    )

    def *(other)
      raise ArgumentError, "cannot multiply #{self} and #{other}" unless other.is_a?(self.class) && to == other.from
      self.class.new(
        src:  "#{pair_str}(#{src}) * #{other.pair_str}(#{other.src})",
        pair: [from, other.to],
        rate: rate * other.rate,
        time: [time, other.time].min
      )
    end

    def from
      pair[0]
    end

    def to
      pair[1]
    end

    def pair_str
      pair.join('_')
    end

    def reverse
      self.class.new(
        src:  "1 / (#{src})",
        pair: pair.reverse,
        rate: 1 / rate,
        time: time
      )
    end

    def to_s
      "#<ExchangeRate#{pair.inspect}=#{rate} at #{time} via #{src}>"
    end
  end

  def self.update_cache(providers = ExchangeRateProvider.keys)
    providers.each do |provider|
      begin
        pairs = public_send(:"fetch_#{provider}")
        pairs.each(&method(:write_cache))
      rescue => ex
        Sentry.capture_exception ex
        Rails.logger.error "[ExchangeRate] update_cache(#{provider.inspect}) failed: #{ex.inspect}"
        next
      end
    end
  end

  def self.write_cache(pair)
    if pair.is_a?(Pair) && pair.rate > 0
      Rails.cache.write("#{KEY_PREFIX}#{pair.pair_str}_#{pair.src}", pair)
    end
  rescue => ex
    Sentry.capture_exception ex
    Rails.logger.error "[ExchangeRate] write_cache(#{pair.inspect}) failed: #{ex.inspect}"
  end

  def self.[](from: :*, to: :*, provider: :*)
    from      = Currency[from] unless from == :*
    to        = Currency[to] unless to == :*
    provider  = ExchangeRateProvider[provider] unless provider == :*
    available = Redis.current.keys("#{KEY_PREFIX}#{from}_#{to}_#{provider}")
    Rails.cache.read_multi(*available).values
  end

  def self.convert(from:, to:, provider: :*, via: Currency[:USD])
    args = { from: Currency[from], to: Currency[to], provider: provider }
    if args.fetch(:from) == args.fetch(:to)
      return # failed cross rate
    end
    results = direct_rates(**args)
    results = reversed_rates(**args) if results.empty?
    results = cross_rates(via: via, **args) if results.empty? && via.present?
    select_median(results)
  end

  def self.direct_rates(**args)
    send(:[], **args)
  end

  def self.reversed_rates(**args)
    args[:from], args[:to] = args[:to], args[:from]
    send(:[], **args).map(&:reverse)
  end

  def self.cross_rates(from:, to:, via:, provider: :*)
    result = []
    args   = [
      { from: from, to: via, provider: provider, via: false },
      { from: via, to: to, provider: provider, via: false }
    ]
    pairs  = args.map(&method(:convert))
    unless pairs.any?(&:nil?)
      result << pairs.reduce(:*)
    end
    result
  end

  def self.select_median(pairs)
    median = (pairs.size - 1) / 2
    pairs.sort_by(&:rate)[median]
  end

  # Assuming that receiver of payment is interested in converting it to fiat
  # it seems the most appropriate rate to use is the bid price

  def self.fetch_bitpay
    data   = URI.open('https://bitpay.com/api/rates').read
    time   = Time.now.utc
    parsed = JSON(data)
    first  = parsed.shift
    unless first['code'] == 'BTC' && first['rate'] == 1
      raise "unexpected response"
    end
    parsed.map do |item|
      pair = Currency[[:BTC, item['code']]]
      Pair.new(
        src:  'bitpay',
        pair: pair,
        rate: item['rate'].to_d,
        time: time
      )
    end
  end

  def self.fetch_bitstamp
    data   = URI.open('https://www.bitstamp.net/api/ticker/').read
    parsed = JSON(data)
    time   = Time.at(parsed['timestamp'].to_i).utc
    pair   = Currency[%i[BTC USD]]
    [
      Pair.new(
        src:  'bitstamp',
        pair: pair,
        rate: parsed['bid'].to_d,
        time: time
      ),
      Pair.new(
        src:  'bitstamp',
        pair: pair.reverse,
        rate: 1 / parsed['ask'].to_d,
        time: time
      )
    ]
  end

  def self.fetch_coinbase(currency: nil)
    if currency.nil?
      return %i[BTC BCH USD].map { |e| fetch_coinbase(currency: e) }.reduce(:concat)
    end

    data   = URI.open("https://api.coinbase.com/v2/exchange-rates?currency=#{currency}").read
    time   = Time.now.utc
    parsed = JSON(data)
    from   = parsed['data']['currency']
    parsed['data']['rates'].map do |key, value|
      pair = Currency[[from, key]]
      Pair.new(
        src:  'coinbase',
        pair: pair,
        rate: value.to_d,
        time: time
      )
    end
  end

  def self.fetch_kraken
    data   = URI.open('https://api.kraken.com/0/public/Ticker?pair=BCHEUR,BCHUSD,BCHXBT,XBTCAD,XBTEUR,XBTGBP,XBTJPY,XBTUSD').read
    time   = Time.now.utc
    parsed = JSON(data)['result']
    parsed.flat_map do |key, value|
      norm = key.gsub(/^XXBT|XBT$/, 'BTC').gsub(/Z(.{3})$/, '\1')
      pair = Currency[norm.partition(/.{3}/).tap(&:shift)]
      [
        Pair.new(
          src:  'kraken',
          pair: pair,
          rate: value['b'][0].to_d,
          time: time
        ),
        Pair.new(
          src:  'kraken',
          pair: pair.reverse,
          rate: 1 / value['a'][0].to_d,
          time: time
        )
      ]
    end
  end

  def self.fetch_okcoin
    pairs = {
      Currency[%i[BTC USD]] => URI.open('https://www.okcoin.com/api/market/v3/oracle').read
    }
    pairs.flat_map do |pair, data|
      parsed = JSON(data)
      time   = Time.at(parsed['timestamp'].to_i).utc
      [
        Pair.new(
          src:  'okcoin',
          pair: pair,
          rate: parsed['prices']['BTC'].to_d,
          time: time
        )
      ]
    end
  end

  def self.fetch_fixer
    # TODO: sign up on https://fixer.io/product or find some other cross-rates provider
  end
end