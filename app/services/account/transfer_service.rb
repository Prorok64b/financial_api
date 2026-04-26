# frozen_string_literal: true

module Account
  class TransferService < ApplicationService
    def initialize(sender:, recipient_email:, amount:)
      @sender = sender
      @recipient_email = recipient_email
      @amount = BigDecimal(amount.to_s)
    end

    def call
      return failure('Amount must be greater than 0') if @amount <= 0

      recipient = User.find_by(email: @recipient_email)
      return failure('Recipient not found', :not_found) unless recipient
      return failure('Cannot transfer to yourself') if recipient.id == @sender.id

      ActiveRecord::Base.transaction(isolation: :repeatable_read) do
        users = lock_parties(@sender, recipient)
        sender = users.find { |u| u.id == @sender.id }
        recipient = users.find { |u| u.id != @sender.id }

        return failure('Insufficient funds') if sender.balance < @amount

        transfer_funds(sender, recipient)
      end

      success(
        balance: @sender.reload.balance,
        amount: @amount,
        recipient_email: @recipient_email
      )
    rescue ActiveRecord::RecordInvalid => e
      failure(e.message)
    rescue ActiveRecord::SerializationFailure
      retry
    end

    private

    def failure(error, status = nil)
      Result.new(success?: false, error: error, data: { status: status })
    end

    def lock_parties(sender, recipient)
      User.where(id: [sender.id, recipient.id]).lock.to_a
    end

    def transfer_funds(sender, recipient)
      sender_new_balance = sender.balance - @amount
      recipient_new_balance = recipient.balance + @amount

      sender.update!(balance: sender_new_balance)
      sender.transactions.create!(
        amount: @amount,
        transaction_type: 'transfer_out',
        balance_after: sender_new_balance,
        counterparty: recipient
      )

      recipient.update!(balance: recipient_new_balance)
      recipient.transactions.create!(
        amount: @amount,
        transaction_type: 'transfer_in',
        balance_after: recipient_new_balance,
        counterparty: sender
      )
    end
  end
end
