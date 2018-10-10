# inspired by:
# https://stackoverflow.com/a/23711606
# https://github.com/havenwood/symbol_call

module SymbolCall
  refine Symbol do
    def call(*args, &block)
      ->(obj, *rest) { obj.public_send(self, *rest, *args, &block) }
    end
  end
end