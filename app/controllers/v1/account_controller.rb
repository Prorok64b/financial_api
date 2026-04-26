# frozen_string_literal: true

module V1
  class AccountController < ApplicationController
    before_action :authenticate_user!

    def balance
      @balance = current_user.balance
    end

    def deposit
      result = Account::DepositService.call(user: current_user, amount: params[:amount])

      if result.success?
        @balance = result.data[:balance]
      else
        @error = result.error
        render :error, status: :unprocessable_entity
      end
    end

    def withdraw
      result = Account::WithdrawService.call(user: current_user, amount: params[:amount])

      if result.success?
        @balance = result.data[:balance]
      else
        @error = result.error
        render :error, status: :unprocessable_entity
      end
    end

    def transfer
      result = Account::TransferService.call(
        sender: current_user,
        recipient_email: params[:recipient_email],
        amount: params[:amount]
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
