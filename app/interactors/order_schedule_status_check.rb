class OrderScheduleStatusCheck
  include Interactor
  include InteractorLogs

  def call
    OrderStatusCheckJob.new(order: context.order, final: false).enqueue
    context.schedule = []
    on_schedule do |time, final|
      context.schedule << time
      OrderStatusCheckJob.new(order: context.order, final: final).enqueue(wait_until: time)
    end
  end

  # We want to minimize number of checks _and_ transaction detection latency.
  # Let's assume broadcasted transaction was not detected via WebsocketInsightClient.
  # if BlockchainAdapter returns unconfirmed transactions
  #   and if Gateway requires zero confirmations
  #     then check BlockchainAdapter as often as feasible
  # TODO:
  # if BlockchainAdapter returns only confirmed transactions
  #   or if Gateway requires some confirmations
  #     then check BlockchainAdapter when new block has been (or expected to be) mined
  def on_schedule
    return to_enum(:on_schedule) unless block_given?
    start  = context.order.created_at
    finish = start + context.order.gateway.orders_expiration_period.seconds
    period = finish - start
    often  = {
        base_interval: ENVied.ORDER_CHECK_BASE_INTERVAL.seconds,
        max_interval:  ENVied.ORDER_CHECK_MAX_INTERVAL.seconds,
        rand_factor:   ENVied.ORDER_CHECK_RAND_FACTOR,
        multiplier:    ENVied.ORDER_CHECK_BACKOFF_MULT,
        max_period:    period,
    }
    now    = start
    with_intervals often do |interval|
      now += interval
      now = now.round(2)
      yield now, false
    end
    yield finish, true
  end

  def with_intervals(max_period:, base_interval:, max_interval:, rand_factor:, multiplier:)
    return to_enum(:with_intervals) unless block_given?
    total   = 0
    backoff = 1
    loop do
      interval = [base_interval * backoff, max_interval].min
      unless rand_factor.zero?
        delta    = 1.0 * interval * rand_factor
        min      = interval - delta
        max      = interval + delta
        interval = rand(min..max)
      end
      total += interval
      break if total >= max_period
      yield interval
      backoff *= multiplier
    end
  end
end
