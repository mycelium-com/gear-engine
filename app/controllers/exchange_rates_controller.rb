class ExchangeRatesController < ApiController

  def index
    result =
      if params.values_at(:from, :to).all?(&:present?)
        [convert]
      else
        ExchangeRate[]
      end
    render json: result
  end

  private def convert
    ExchangeRate.convert(
      from: Currency[params[:from]],
      to:   Currency[params[:to]],
      via:  Currency[params[:via].presence || :USD]
    )
  end
end
