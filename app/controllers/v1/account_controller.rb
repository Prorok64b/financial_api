# frozen_string_literal: true

module V1
  class AccountController < ApplicationController
    before_action :authenticate_user!

    def balance
      @balance = current_user.balance
    end

    def deposit
      permitted = params.permit(:amount).to_h
      errors = contract_errors(V1::Account::DepositContract, permitted)
      return render_errors(errors) if errors.any?

      result = ::Account::DepositService.call(user: current_user, amount: permitted[:amount])

      if result.success?
        @balance = result.data[:balance]
      else
        @error = result.error
        render :error, status: :unprocessable_entity
      end
    end

    def withdraw
      permitted = params.permit(:amount).to_h
      errors = contract_errors(V1::Account::WithdrawContract, permitted)
      return render_errors(errors) if errors.any?

      result = ::Account::WithdrawService.call(user: current_user, amount: permitted[:amount])

      if result.success?
        @balance = result.data[:balance]
      else
        @error = result.error
        render :error, status: :unprocessable_entity
      end
    end

    def transfer
      permitted = params.permit(:amount, :recipient_email).to_h
      errors = contract_errors(V1::Account::TransferContract, permitted)
      return render_errors(errors) if errors.any?

      result = ::Account::TransferService.call(
        sender: current_user,
        recipient_email: permitted[:recipient_email],
        amount: permitted[:amount]
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

    private

    def contract_errors(contract_class, permitted_params)
      contract_class.new.call(permitted_params).errors.to_h
    end

    def render_errors(errors)
      @error = errors
      render :error, status: :bad_request
    end
  end
end
