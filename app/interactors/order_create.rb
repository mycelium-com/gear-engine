class OrderCreate
  include Interactor::Organizer

  organize OrderParamsValidate, OrderPersist, OrderScheduleStatusCheck, OrderSubscribeToStatusChange
end
