# frozen_string_literal: true

require "dry/validation"

module V1
  module Account
    class AccountContract < Dry::Validation::Contract
      params do
        required(:amount).filled(:decimal)
      end

      rule(:amount) do
        str = values[:amount].to_s
        decimal_part = str.split(".").second

        key.failure("must have at most 2 decimal places") if decimal_part && decimal_part.size > 2
      end
    end

    class DepositContract < AccountContract
      params {}
    end

    class WithdrawContract < AccountContract
      params {}
    end

    class TransferContract < AccountContract
      params do
        required(:recipient_email).filled(:string)
      end
    end
  end
end
