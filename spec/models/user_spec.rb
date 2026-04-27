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

    it 'is invalid with a balance exceeding the limit' do
      user = build(:user, balance: 1_000_000)
      expect(user).not_to be_valid
      expect(user.errors[:balance]).to include('must be less than 1000000')
    end

    it 'is valid with balance having 2 decimal places' do
      user = build(:user, balance: BigDecimal('100.99'))
      expect(user).to be_valid
    end

    it 'is valid with balance having 1 decimal place' do
      user = build(:user, balance: BigDecimal('100.5'))
      expect(user).to be_valid
    end

    it 'is valid with balance having no decimal places' do
      user = build(:user, balance: BigDecimal('100'))
      expect(user).to be_valid
    end

    it 'is invalid with balance having more than 2 decimal places' do
      user = build(:user, balance: BigDecimal('100.999'))
      expect(user).not_to be_valid
      expect(user.errors[:balance]).to include('must have at most 2 decimal places')
    end

    it 'is invalid with balance having 3 decimal places' do
      user = build(:user, balance: BigDecimal('50.123'))
      expect(user).not_to be_valid
      expect(user.errors[:balance]).to include('must have at most 2 decimal places')
    end
  end

  describe 'balance precision' do
    it 'stores balance with exact 2 decimal places' do
      user = create(:user, balance: BigDecimal('100.55'))
      user.reload
      expect(user.balance).to eq(BigDecimal('100.55'))
    end
  end
end
