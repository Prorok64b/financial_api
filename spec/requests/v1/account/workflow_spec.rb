# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'V1::Account Workflow', type: :request do
  self.use_transactional_tests = false

  describe 'full workflow' do
    it 'performs a complete deposit, transfer, and withdraw flow' do
      sender = create(:user, balance: 0)
      recipient = create(:user, balance: 0)
      sender_headers = auth_headers(sender)
      recipient_headers = auth_headers(recipient)

      # Deposit funds to sender
      post '/v1/account/deposit', params: { amount: 100.00 }, headers: sender_headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(sender.reload.balance).to eq(100.00)

      # Transfer to recipient
      post '/v1/account/transfer',
           params: { amount: 40.00, recipient_email: recipient.email },
           headers: sender_headers,
           as: :json
      expect(response).to have_http_status(:ok)
      expect(sender.reload.balance).to eq(60.00)
      expect(recipient.reload.balance).to eq(40.00)

      # Recipient withdraws
      post '/v1/account/withdraw', params: { amount: 20.00 }, headers: recipient_headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(recipient.reload.balance).to eq(20.00)

      # Check sender transaction history
      get '/v1/account/transactions', headers: sender_headers, as: :json
      expect(json_response['transactions'].length).to eq(2)
      expect(json_response['transactions'].map { |t| t['type'] }).to contain_exactly('deposit', 'transfer_out')

      # Check recipient transaction history
      get '/v1/account/transactions', headers: recipient_headers, as: :json
      expect(json_response['transactions'].length).to eq(2)
      expect(json_response['transactions'].map { |t| t['type'] }).to contain_exactly('transfer_in', 'withdrawal')
    end
  end
end
