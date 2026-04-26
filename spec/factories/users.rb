# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    password { 'password123' }
    balance { 0 }

    trait :with_balance do
      transient do
        initial_balance { 100.00 }
      end

      balance { initial_balance }
    end
  end
end
