# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Account::WithdrawService do
  self.use_transactional_tests = false

  describe '.call' do
    let(:user) { create(:user, balance: 100.00) }

    context 'with valid amount and sufficient funds' do
      it 'returns success' do
        result = described_class.call(user: user, amount: 50.00)
        expect(result).to be_success
      end

      it 'decreases the user balance' do
        expect {
          described_class.call(user: user, amount: 50.00)
        }.to change { user.reload.balance }.from(100.00).to(50.00)
      end

      it 'creates a transaction record' do
        expect {
          described_class.call(user: user, amount: 50.00)
        }.to change { user.transactions.count }.by(1)
      end

      it 'creates a withdrawal transaction with correct attributes' do
        described_class.call(user: user, amount: 50.00)
        transaction = user.transactions.last

        expect(transaction.amount).to eq(50.00)
        expect(transaction.transaction_type).to eq('withdrawal')
        expect(transaction.balance_after).to eq(50.00)
      end

      it 'returns the new balance in the result' do
        result = described_class.call(user: user, amount: 50.00)
        expect(result.data[:balance]).to eq(50.00)
      end

      it 'allows withdrawing entire balance' do
        result = described_class.call(user: user, amount: 100.00)
        expect(result).to be_success
        expect(user.reload.balance).to eq(0)
      end

      it 'handles decimal amounts correctly' do
        result = described_class.call(user: user, amount: 25.75)
        expect(user.reload.balance).to eq(74.25)
      end

      it 'handles string amounts' do
        result = described_class.call(user: user, amount: '50.00')
        expect(result).to be_success
        expect(user.reload.balance).to eq(50.00)
      end
    end

    context 'with insufficient funds' do
      it 'fails when amount exceeds balance' do
        result = described_class.call(user: user, amount: 150.00)
        expect(result).to be_failure
        expect(result.error).to eq('Insufficient funds')
      end

      it 'does not change the balance on insufficient funds' do
        expect {
          described_class.call(user: user, amount: 150.00)
        }.not_to change { user.reload.balance }
      end

      it 'does not create a transaction on insufficient funds' do
        expect {
          described_class.call(user: user, amount: 150.00)
        }.not_to change { user.transactions.count }
      end

      it 'fails when user has zero balance' do
        user.update!(balance: 0)
        result = described_class.call(user: user, amount: 1.00)
        expect(result).to be_failure
        expect(result.error).to eq('Insufficient funds')
      end
    end

    context 'with invalid amount' do
      it 'fails with zero amount' do
        result = described_class.call(user: user, amount: 0)
        expect(result).to be_failure
        expect(result.error).to eq('Amount must be greater than 0')
      end

      it 'fails with negative amount' do
        result = described_class.call(user: user, amount: -50)
        expect(result).to be_failure
        expect(result.error).to eq('Amount must be greater than 0')
      end
    end

    context 'when amount exceeds maximum withdrawal limit' do
      let(:user) { create(:user, balance: 2_000_000.00) }

      it 'fails with error message' do
        result = described_class.call(user: user, amount: 1_000_001.00)
        expect(result).to be_failure
        expect(result.error).to eq('Maximum withdrawal amount is 1000000')
      end

      it 'does not change balance' do
        expect {
          described_class.call(user: user, amount: 1_000_001.00)
        }.not_to change { user.reload.balance }
      end

      it 'succeeds at maximum allowed amount' do
        result = described_class.call(user: user, amount: 1_000_000)
        expect(result).to be_success
        expect(user.reload.balance).to eq(1_000_000)
      end
    end

    context 'with concurrent withdrawals' do
      it 'prevents overdraft with concurrent withdrawals' do
        user = create(:user, balance: 100.00)
        results = []
        threads = []

        3.times do
          threads << Thread.new do
            results << described_class.call(user: User.find(user.id), amount: 50.00)
          end
        end

        threads.each(&:join)

        successful = results.count(&:success?)
        expect(successful).to eq(2)
        expect(user.reload.balance).to eq(0)
      end
    end
  end
end
