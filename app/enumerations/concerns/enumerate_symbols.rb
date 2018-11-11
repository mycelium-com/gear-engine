module EnumerateSymbols
  extend ActiveSupport::Concern

  class_methods do

    def associate_symbols(list)
      associate_values Hash[list.zip(list)]
    end

    def [](key)
      raise NameError if key.blank?
      const_get(String(key).upcase)
    end
  end
end