# frozen_string_literal: true

class Transaction < ApplicationRecord
  TYPES = %w[deposit withdrawal transfer_in transfer_out].freeze

  belongs_to :user
  belongs_to :counterparty, class_name: 'User', optional: true

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :transaction_type, presence: true, inclusion: { in: TYPES }
  validates :balance_after, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :recent_first, -> { order(created_at: :desc) }
end
