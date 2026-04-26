# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:transactions).dependent(:destroy) }
  end

  describe 'validations' do
    it { is_expected.to validate_numericality_of(:balance).is_greater_than_or_equal_to(0) }

    it 'is valid with a zero balance' do
      user = build(:user, balance: 0)
      expect(user).to be_valid
    end

    it 'is valid with a positive balance' do
      user = build(:user, balance: 100.50)
      expect(user).to be_valid
    end

    it 'is invalid with a negative balance' do
      user = build(:user, balance: -1)
      expect(user).not_to be_valid
      expect(user.errors[:balance]).to include('must be greater than or equal to 0')
    end
  end

  describe 'balance precision' do
    it 'stores balance with 2 decimal places' do
      user = create(:user, balance: 100.999)
      user.reload
      expect(user.balance).to eq(101.00)
    end
  end
end
