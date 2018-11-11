module Straight
  Transaction = Struct.new(:tid, :amount, :confirmations, :block_height) do

    def self.from_hash(hash)
      result = {
          tid:           hash[:tid],
          confirmations: hash[:confirmations].to_i,
          block_height:  hash[:block_height].to_i,
          amount:        (hash.key?(:total_amount) ? hash[:total_amount] : hash[:amount])
      }
      new(*result.values_at(*members))
    end

    def self.from_hashes(array)
      array.map { |item| from_hash(item) }
    end
  end
end
