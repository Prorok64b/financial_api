# frozen_string_literal: true

module Account
  class WithdrawService < ApplicationService
    LIMIT = 1_000_000
    TRANSACTION = "withdrawal"

    def initialize(user:, amount:)
      @user = user
      @amount = BigDecimal(amount.to_s)
    end

    def call
      # we need this quick check, to avoid placing transaction and aquiring a lock,
      # in case we already know that amount is not valid
      return failure("Amount must be greater than 0") if @amount <= 0
      return failure("Maximum withdrawal amount is #{LIMIT}") if @amount > LIMIT
      return failure("Insufficient funds") if @user.balance < @amount

      ActiveRecord::Base.transaction(isolation: :repeatable_read) do
        @user.lock!

        new_balance = @user.balance - @amount
        @user.update!(balance: new_balance)
        @user.transactions.create!(
          amount: @amount,
          transaction_type: TRANSACTION,
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
