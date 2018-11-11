module ORM
  extend ActiveSupport::Concern

  class_methods do

    def orm
      StraightServer.const_get(name)
    end

    def db
      orm.db
    end

    def with_pk!(pk)
      new(orm.with_pk!(pk))
    end

    def find_by(hash)
      data = orm.where(hash).order(:id).last
      data && new(data)
    end

    def find_by_id(id)
      find_by(id: id)
    end

    def wrap_each(dataset)
      return enum_for(:wrap_each, dataset) unless block_given?
      dataset.paged_each do |order|
        yield new(order)
      end
    end
  end

  def initialize(obj = nil)
    obj ||= self.class.orm.new
    raise ArgumentError unless obj.is_a?(self.class.orm)
    super
  end

  # Sequel updates all fields by default, results in noisy logs
  def save_changed
    save changed: true
  end


  def eql?(other)
    other.is_a?(self.class) && __getobj__.eql?(other.__getobj__)
  end

  def ==(other)
    other.is_a?(self.class) && (__getobj__ == other.__getobj__)
  end

  def ===(other)
    other.is_a?(self.class) && (__getobj__ === other.__getobj__)
  end

  def inspect
    "#<#{self.class.name}#{values.inspect}>"
  end

  def to_s
    "[#{self.class.name}#{id}]"
  end
end