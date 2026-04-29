# frozen_string_literal: true

class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  MAX_BALANCE = BigDecimal("999999.99")

  devise :database_authenticatable, :registerable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: self

  has_many :transactions, dependent: :destroy

  validates :balance, numericality: { greater_than_or_equal_to: 0 }
  validate :balance_max_two_decimal_places
  validate :balance_within_limit

  private

  def balance_max_two_decimal_places
    return if balance_before_type_cast.blank?

    balance_string = balance_before_type_cast.to_s
    return unless balance_string.include?(".")

    decimal_part = balance_string.split(".").last
    if decimal_part.length > 2
      errors.add(:balance, "must have at most 2 decimal places")
    end
  end

  def balance_within_limit
    return if balance.blank?
    return if balance <= MAX_BALANCE

    previous_balance = balance_was || BigDecimal("0")
    max_deposit = MAX_BALANCE - previous_balance

    errors.add(
      :balance,
      "limit exceeded. Current balance is #{previous_balance}, maximum deposit amount is #{max_deposit}"
    )
  end
end
