# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'V1::Account#transactions', type: :request do
  self.use_transactional_tests = false

	include_context 'authenticated user'

  subject(:request) { get '/v1/account/transactions', headers: headers, as: :json }

  context 'when authenticated' do
    before do
      create(:transaction, user: user, amount: 100.00, transaction_type: 'deposit', balance_after: 100.00, created_at: 2.days.ago)
      create(:transaction, user: user, amount: 50.00, transaction_type: 'withdrawal', balance_after: 50.00, created_at: 1.day.ago)
    end

    it 'returns the transaction history' do
      request

      expect(response).to have_http_status(:ok)
      expect(json_response['transactions'].length).to eq(2)
    end

    it 'returns transactions in reverse chronological order' do
      request

      transactions = json_response['transactions']
      expect(transactions[0]['type']).to eq('withdrawal')
      expect(transactions[1]['type']).to eq('deposit')
    end

    it 'includes all required fields' do
      request

      transaction = json_response['transactions'].first
      expect(transaction).to include('id', 'amount', 'type', 'balance_after', 'created_at')
    end

    context 'with transfer transactions' do
      let(:other_user) { create(:user) }

      before do
        create(:transaction, :transfer_out, user: user, counterparty: other_user, balance_after: 30.00)
      end

      it 'includes counterparty email' do
        request

        transfer = json_response['transactions'].find { |t| t['type'] == 'transfer_out' }
        expect(transfer['counterparty_email']).to eq(other_user.email)
      end
    end

    context 'when no transactions exist' do
      before { user.transactions.destroy_all }

      it 'returns empty array' do
        request

        expect(json_response['transactions']).to eq([])
      end
    end
  end

  context 'when not authenticated' do
    include_context 'unauthenticated request'

    it 'returns unauthorized' do
      request

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
