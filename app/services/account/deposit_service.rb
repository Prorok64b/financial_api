# frozen_string_literal: true

module Account
  class DepositService < ApplicationService
    def initialize(user:, amount:)
      @user = user
      @amount = BigDecimal(amount.to_s)
    end

    def call
      return failure("Amount must be greater than 0") if @amount <= 0

      ActiveRecord::Base.transaction(isolation: :repeatable_read) do
        @user.lock!
        new_balance = @user.balance + @amount
        @user.update!(balance: new_balance)
        @user.transactions.create!(
          amount: @amount,
          transaction_type: "deposit",
          balance_after: new_balance
        )
      end

      success(balance: @user.balance)
    rescue ActiveRecord::RecordInvalid => e
      failure(e.message)
    rescue ActiveRecord::SerializationFailure
      retry
    end
  end
end
