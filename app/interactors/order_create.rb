class OrderCreate
  include Interactor::Organizer

  organize OrderPersist, OrderScheduleStatusCheck
end
