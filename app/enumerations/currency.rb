module Currency

  def self.[](key)
    raise NameError if key.blank?
    case key
    when Array
      key.map(&method(:[]))
    when Symbol
      key.upcase
    else
      String(key).upcase.to_sym
    end
  end

  def self.precision(currency)
    code = Currency[currency]
    if BLOCKCHAIN.include?(code)
      8
    elsif FIAT.include?(code)
      2
    end
  end

  BLOCKCHAIN = Currency[%i[
    BTC BCH
  ]].to_set.freeze

  FIAT = Currency[%i[
    USD EUR AUD BGN BRL CAD CHF CNY CZK DKK GBP HKD HRK HUF IDR ILS INR
    JPY KRW MXN MYR NOK NZD PHP PLN RON RUB UAH SEK SGD THB TRY ZAR
  ]].to_set.freeze
end