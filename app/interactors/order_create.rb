class OrderCreate
  include Interactor::Organizer

  organize OrderPersist, OrderScheduleStatusCheck, OrderSubscribeToStatusChange
end
