# frozen_string_literal: true

# Clear existing data
puts 'Cleaning database...'
Transaction.destroy_all
User.destroy_all

puts 'Creating users...'

# Main test user
alice = User.create!(
  email: 'alice@example.com',
  password: 'password123',
  balance: 0
)

bob = User.create!(
  email: 'bob@example.com',
  password: 'password123',
  balance: 0
)

charlie = User.create!(
  email: 'charlie@example.com',
  password: 'password123',
  balance: 0
)

demo = User.create!(
  email: 'demo@example.com',
  password: 'demo1234',
  balance: 0
)

puts "Created #{User.count} users"

# Helper to create transactions and update balance
def deposit(user, amount, created_at: Time.current)
  new_balance = user.balance + amount
  user.update!(balance: new_balance)
  user.transactions.create!(
    amount: amount,
    transaction_type: 'deposit',
    balance_after: new_balance,
    created_at: created_at
  )
end

def withdraw(user, amount, created_at: Time.current)
  new_balance = user.balance - amount
  user.update!(balance: new_balance)
  user.transactions.create!(
    amount: amount,
    transaction_type: 'withdrawal',
    balance_after: new_balance,
    created_at: created_at
  )
end

def transfer(sender, recipient, amount, created_at: Time.current)
  sender_new_balance = sender.balance - amount
  recipient_new_balance = recipient.balance + amount

  sender.update!(balance: sender_new_balance)
  recipient.update!(balance: recipient_new_balance)

  sender.transactions.create!(
    amount: amount,
    transaction_type: 'transfer_out',
    balance_after: sender_new_balance,
    counterparty: recipient,
    created_at: created_at
  )

  recipient.transactions.create!(
    amount: amount,
    transaction_type: 'transfer_in',
    balance_after: recipient_new_balance,
    counterparty: sender,
    created_at: created_at
  )
end

puts 'Creating transactions for Alice...'

# Alice's transaction history (past 30 days)
deposit(alice, 1000.00, created_at: 30.days.ago)
deposit(alice, 500.00, created_at: 25.days.ago)
withdraw(alice, 150.00, created_at: 20.days.ago)
deposit(alice, 250.00, created_at: 15.days.ago)
withdraw(alice, 75.50, created_at: 10.days.ago)
withdraw(alice, 200.00, created_at: 5.days.ago)
deposit(alice, 100.00, created_at: 2.days.ago)

puts "Alice's balance: $#{alice.balance}"

puts 'Creating transactions for Bob...'

# Bob's transaction history
deposit(bob, 2000.00, created_at: 28.days.ago)
withdraw(bob, 500.00, created_at: 21.days.ago)
deposit(bob, 300.00, created_at: 14.days.ago)
withdraw(bob, 150.00, created_at: 7.days.ago)

puts "Bob's balance: $#{bob.balance}"

puts 'Creating transactions for Charlie...'

# Charlie's transaction history
deposit(charlie, 500.00, created_at: 20.days.ago)
deposit(charlie, 500.00, created_at: 10.days.ago)

puts "Charlie's balance: $#{charlie.balance}"

puts 'Creating transfers between users...'

# Transfers between users
transfer(alice, bob, 100.00, created_at: 8.days.ago)
transfer(bob, charlie, 250.00, created_at: 6.days.ago)
transfer(charlie, alice, 75.00, created_at: 3.days.ago)
transfer(alice, charlie, 50.00, created_at: 1.day.ago)

puts 'Creating transactions for Demo user...'

# Demo user with simple history
deposit(demo, 500.00, created_at: 7.days.ago)
withdraw(demo, 50.00, created_at: 5.days.ago)
deposit(demo, 100.00, created_at: 3.days.ago)
transfer(demo, alice, 25.00, created_at: 1.day.ago)

puts ''
puts '=' * 50
puts 'Seeding complete!'
puts '=' * 50
puts ''
puts 'Test Users:'
puts '-' * 50
puts "| #{'Email'.ljust(25)} | #{'Password'.ljust(12)} | #{'Balance'.rjust(10)} |"
puts '-' * 50

User.order(:email).each do |user|
  puts "| #{user.email.ljust(25)} | #{'password123'.ljust(12)} | #{format('$%.2f', user.balance).rjust(10)} |"
end

puts '-' * 50
puts ''
puts "Total transactions: #{Transaction.count}"
puts ''
puts 'Demo user credentials:'
puts '  Email: demo@example.com'
puts '  Password: demo1234'
