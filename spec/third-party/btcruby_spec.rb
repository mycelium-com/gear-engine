require 'rails_helper'

RSpec.describe 'btcruby' do

  xit "parses BTC_TEST transaction 9f44d8931cd8e29888d6b89001867f906ca1dc427e5f98c2359e9eb22c5bab6a" do
    expect {
      BTC::Transaction.new(hex: '02000000000101556264afa5e0d3a2545db5d1279d43569dea3aec40f073467d60d3d334bb9a7c00000000171600142595f9f3d599c0b9cac2e51e218d0da8c81ef9a2fdffffff0210270000000000001976a91413f8e9ae69afdfca0de130f798022d2c795af4f988ac0ebaef010000000017a914f0ccca2d7b7ed870be0aa47755bdcc7867ce6a69870247304402201dfaf80f10ce4cafdb3470eee82ee4b366748179ccbc0ecc9ca7971516f7e70e022003f6eef0936eabdf86debabd031c9b2914d838389c624657e4540043165f510d0121024d56f3c5691b6207dc33651a76808ad97d2e5870ecac675b04aa1a579504a652e4a41300')
    }.not_to raise_error
  end
end