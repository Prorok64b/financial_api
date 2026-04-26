# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Account::TransferService do
  self.use_transactional_tests = false

  describe '.call' do
    let(:sender) { create(:user, balance: 100.00) }
    let(:recipient) { create(:user, balance: 50.00) }

    context 'with valid transfer' do
      it 'returns success' do
        result = described_class.call(sender: sender, recipient_email: recipient.email, amount: 30.00)
        expect(result).to be_success
      end

      it 'decreases sender balance' do
        expect {
          described_class.call(sender: sender, recipient_email: recipient.email, amount: 30.00)
        }.to change { sender.reload.balance }.from(100.00).to(70.00)
      end

      it 'increases recipient balance' do
        expect {
          described_class.call(sender: sender, recipient_email: recipient.email, amount: 30.00)
        }.to change { recipient.reload.balance }.from(50.00).to(80.00)
      end

      it 'creates two transaction records' do
        expect {
          described_class.call(sender: sender, recipient_email: recipient.email, amount: 30.00)
        }.to change { Transaction.count }.by(2)
      end

      it 'creates transfer_out transaction for sender' do
        described_class.call(sender: sender, recipient_email: recipient.email, amount: 30.00)
        transaction = sender.transactions.last

        expect(transaction.amount).to eq(30.00)
        expect(transaction.transaction_type).to eq('transfer_out')
        expect(transaction.balance_after).to eq(70.00)
        expect(transaction.counterparty).to eq(recipient)
      end

      it 'creates transfer_in transaction for recipient' do
        described_class.call(sender: sender, recipient_email: recipient.email, amount: 30.00)
        transaction = recipient.transactions.last

        expect(transaction.amount).to eq(30.00)
        expect(transaction.transaction_type).to eq('transfer_in')
        expect(transaction.balance_after).to eq(80.00)
        expect(transaction.counterparty).to eq(sender)
      end

      it 'returns correct data in the result' do
        result = described_class.call(sender: sender, recipient_email: recipient.email, amount: 30.00)

        expect(result.data[:balance]).to eq(70.00)
        expect(result.data[:amount]).to eq(30.00)
        expect(result.data[:recipient_email]).to eq(recipient.email)
      end

      it 'allows transferring entire balance' do
        result = described_class.call(sender: sender, recipient_email: recipient.email, amount: 100.00)
        expect(result).to be_success
        expect(sender.reload.balance).to eq(0)
        expect(recipient.reload.balance).to eq(150.00)
      end

      it 'handles decimal amounts correctly' do
        described_class.call(sender: sender, recipient_email: recipient.email, amount: 33.33)
        expect(sender.reload.balance).to eq(66.67)
        expect(recipient.reload.balance).to eq(83.33)
      end

      it 'handles string amounts' do
        result = described_class.call(sender: sender, recipient_email: recipient.email, amount: '30.00')
        expect(result).to be_success
      end
    end

    context 'with invalid recipient' do
      it 'fails when recipient does not exist' do
        result = described_class.call(sender: sender, recipient_email: 'nonexistent@example.com', amount: 30.00)
        expect(result).to be_failure
        expect(result.error).to eq('Recipient not found')
        expect(result.data[:status]).to eq(:not_found)
      end

      it 'fails when transferring to self' do
        result = described_class.call(sender: sender, recipient_email: sender.email, amount: 30.00)
        expect(result).to be_failure
        expect(result.error).to eq('Cannot transfer to yourself')
      end

      it 'does not change balances when recipient not found' do
        expect {
          described_class.call(sender: sender, recipient_email: 'nonexistent@example.com', amount: 30.00)
        }.not_to change { sender.reload.balance }
      end
    end

    context 'with insufficient funds' do
      it 'fails when amount exceeds sender balance' do
        result = described_class.call(sender: sender, recipient_email: recipient.email, amount: 150.00)
        expect(result).to be_failure
        expect(result.error).to eq('Insufficient funds')
      end

      it 'does not change any balances on insufficient funds' do
        described_class.call(sender: sender, recipient_email: recipient.email, amount: 150.00)
        expect(sender.reload.balance).to eq(100.00)
        expect(recipient.reload.balance).to eq(50.00)
      end

      it 'does not create any transactions on insufficient funds' do
        expect {
          described_class.call(sender: sender, recipient_email: recipient.email, amount: 150.00)
        }.not_to change { Transaction.count }
      end
    end

    context 'with invalid amount' do
      it 'fails with zero amount' do
        result = described_class.call(sender: sender, recipient_email: recipient.email, amount: 0)
        expect(result).to be_failure
        expect(result.error).to eq('Amount must be greater than 0')
      end

      it 'fails with negative amount' do
        result = described_class.call(sender: sender, recipient_email: recipient.email, amount: -50)
        expect(result).to be_failure
        expect(result.error).to eq('Amount must be greater than 0')
      end
    end

    context 'atomicity' do
      it 'creates both transactions or neither' do
        initial_transaction_count = Transaction.count

        described_class.call(sender: sender, recipient_email: recipient.email, amount: 30.00)

        # Successful transfer creates exactly 2 transactions
        expect(Transaction.count).to eq(initial_transaction_count + 2)
      end

      it 'does not create partial transactions on insufficient funds' do
        initial_transaction_count = Transaction.count

        described_class.call(sender: sender, recipient_email: recipient.email, amount: 150.00)

        # Failed transfer creates no transactions
        expect(Transaction.count).to eq(initial_transaction_count)
      end
    end

    context 'with concurrent transfers' do
      it 'handles concurrent transfers correctly without deadlock' do
        user1 = create(:user, balance: 100.00)
        user2 = create(:user, balance: 100.00)
        threads = []

        # Concurrent transfers in both directions
        5.times do
          threads << Thread.new do
            described_class.call(sender: User.find(user1.id), recipient_email: user2.email, amount: 10.00)
          end
          threads << Thread.new do
            described_class.call(sender: User.find(user2.id), recipient_email: user1.email, amount: 10.00)
          end
        end

        threads.each(&:join)

        # Both should still have their original balance since transfers are symmetric
        expect(user1.reload.balance).to eq(100.00)
        expect(user2.reload.balance).to eq(100.00)
      end
    end
  end
end
