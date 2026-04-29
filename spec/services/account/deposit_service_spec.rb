# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Account::DepositService do
  self.use_transactional_tests = false

  describe '.call' do
    let(:user) { create(:user, balance: 100.00) }

    context 'with valid amount' do
      it 'returns success' do
        result = described_class.call(user: user, amount: 50.00)

        expect(result).to be_success
        expect(result.data[:balance]).to eq(150.00)
      end

      it 'increases the user balance' do
        expect {
          described_class.call(user: user, amount: 50.00)
        }.to change { user.reload.balance }.from(100.00).to(150.00)
      end

      it 'creates a transaction record' do
        expect {
          described_class.call(user: user, amount: 50.00)
        }.to change { user.transactions.count }.by(1)
      end

      it 'creates a deposit transaction with correct attributes' do
        described_class.call(user: user, amount: 50.00)
        transaction = user.transactions.last

        expect(transaction.amount).to eq(50.00)
        expect(transaction.transaction_type).to eq('deposit')
        expect(transaction.balance_after).to eq(150.00)
      end

      it 'returns the new balance in the result' do
        result = described_class.call(user: user, amount: 50.00)
        expect(result.data[:balance]).to eq(150.00)
      end

      it 'handles decimal amounts correctly' do
        result = described_class.call(user: user, amount: 25.75)
        expect(user.reload.balance).to eq(125.75)
      end

      it 'handles string amounts' do
        result = described_class.call(user: user, amount: '50.00')
        expect(result).to be_success
        expect(user.reload.balance).to eq(150.00)
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

      it 'does not change the balance on failure' do
        expect {
          described_class.call(user: user, amount: -50)
        }.not_to change { user.reload.balance }
      end

      it 'does not create a transaction on failure' do
        expect {
          described_class.call(user: user, amount: -50)
        }.not_to change { user.transactions.count }
      end
    end

    context 'when deposit would exceed balance limit' do
      let(:user) { create(:user, balance: 999_000.00) }

      it 'fails with helpful error message' do
        result = described_class.call(user: user, amount: 1_001.00)
        expect(result).to be_failure
        expect(result.error).to include('Current balance is 999000.0')
        expect(result.error).to include('maximum deposit amount is 999.99')
      end

      it 'does not change the balance when limit exceeded' do
        expect {
          described_class.call(user: user, amount: 1_001.00)
        }.not_to change { user.reload.balance }
      end

      it 'does not create a transaction when limit exceeded' do
        expect {
          described_class.call(user: user, amount: 1_001.00)
        }.not_to change { user.transactions.count }
      end

      it 'succeeds when deposit stays within limit' do
        result = described_class.call(user: user, amount: 999.99)
        expect(result).to be_success
        expect(user.reload.balance).to eq(999_999.99)
      end
    end

    context 'with concurrent deposits' do
      it 'handles concurrent deposits correctly' do
        user = create(:user, balance: 0)
        threads = []

        5.times do
          threads << Thread.new do
            described_class.call(user: User.find(user.id), amount: 100.00)
          end
        end

        threads.each(&:join)
        expect(user.reload.balance).to eq(500.00)
        expect(user.transactions.count).to eq(5)
      end
    end
  end
end
