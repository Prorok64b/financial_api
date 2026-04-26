# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Transaction, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:counterparty).class_name('User').optional }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:amount) }
    it { is_expected.to validate_numericality_of(:amount).is_greater_than(0) }
    it { is_expected.to validate_presence_of(:transaction_type) }
    it { is_expected.to validate_inclusion_of(:transaction_type).in_array(Transaction::TYPES) }
    it { is_expected.to validate_presence_of(:balance_after) }
    it { is_expected.to validate_numericality_of(:balance_after).is_greater_than_or_equal_to(0) }

    it 'is valid with valid attributes' do
      transaction = build(:transaction)
      expect(transaction).to be_valid
    end

    it 'is invalid with zero amount' do
      transaction = build(:transaction, amount: 0)
      expect(transaction).not_to be_valid
    end

    it 'is invalid with negative amount' do
      transaction = build(:transaction, amount: -10)
      expect(transaction).not_to be_valid
    end

    it 'is invalid with unknown transaction type' do
      transaction = build(:transaction, transaction_type: 'unknown')
      expect(transaction).not_to be_valid
    end
  end

  describe 'scopes' do
    describe '.recent_first' do
      it 'orders transactions by created_at descending' do
        user = create(:user, balance: 100)
        old_transaction = create(:transaction, user: user, created_at: 2.days.ago)
        new_transaction = create(:transaction, user: user, created_at: 1.day.ago)

        expect(Transaction.recent_first).to eq([new_transaction, old_transaction])
      end
    end
  end

  describe 'transaction types' do
    it 'allows deposit type' do
      transaction = build(:transaction, :deposit)
      expect(transaction).to be_valid
    end

    it 'allows withdrawal type' do
      transaction = build(:transaction, :withdrawal)
      expect(transaction).to be_valid
    end

    it 'allows transfer_in type' do
      transaction = build(:transaction, :transfer_in)
      expect(transaction).to be_valid
    end

    it 'allows transfer_out type' do
      transaction = build(:transaction, :transfer_out)
      expect(transaction).to be_valid
    end
  end
end
