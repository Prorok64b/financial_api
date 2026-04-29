# frozen_string_literal: true

module V1
  class AccountController < ApplicationController
    before_action :authenticate_user!

    def balance
      @balance = current_user.balance
    end

    def deposit
      amount = params.require(:amount)

      result = Account::DepositService.call(user: current_user, amount: amount)

      if result.success?
        @balance = result.data[:balance]
      else
        @error = result.error
        render :error, status: :unprocessable_entity
      end
    end

    def withdraw
      amount = params.require(:amount)

      result = Account::WithdrawService.call(user: current_user, amount: amount)

      if result.success?
        @balance = result.data[:balance]
      else
        @error = result.error
        render :error, status: :unprocessable_entity
      end
    end

    def transfer
      amount = params.require(:amount)
      recipient_email = params.require(:recipient_email)

      result = Account::TransferService.call(
        sender: current_user,
        recipient_email: recipient_email,
        amount: amount
      )

      if result.success?
        @amount = result.data[:amount]
        @recipient_email = result.data[:recipient_email]
        @balance = result.data[:balance]
      else
        @error = result.error
        status = result.data&.dig(:status) == :not_found ? :not_found : :unprocessable_entity
        render :error, status: status
      end
    end

    def transactions
      @transactions = current_user.transactions.recent_first
    end
  end
end
