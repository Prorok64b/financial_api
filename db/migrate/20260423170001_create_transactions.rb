# frozen_string_literal: true

class CreateTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :transactions do |t|
      t.references :user, null: false, foreign_key: true
      t.decimal :amount, precision: 15, scale: 2, null: false
      t.string :transaction_type, null: false
      t.decimal :balance_after, precision: 15, scale: 2, null: false
      t.references :counterparty, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :transactions, [:user_id, :created_at]
  end
end
