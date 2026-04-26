# frozen_string_literal: true

FactoryBot.define do
  factory :transaction do
    user
    amount { 50.00 }
    transaction_type { 'deposit' }
    balance_after { 50.00 }

    trait :deposit do
      transaction_type { 'deposit' }
    end

    trait :withdrawal do
      transaction_type { 'withdrawal' }
    end

    trait :transfer_in do
      transaction_type { 'transfer_in' }
      counterparty { association :user }
    end

    trait :transfer_out do
      transaction_type { 'transfer_out' }
      counterparty { association :user }
    end
  end
end
