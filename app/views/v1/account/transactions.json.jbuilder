# frozen_string_literal: true

json.transactions @transactions do |transaction|
  json.id transaction.id
  json.amount transaction.amount
  json.type transaction.transaction_type
  json.balance_after transaction.balance_after
  json.counterparty_email transaction.counterparty&.email if transaction.counterparty
  json.created_at transaction.created_at
end
