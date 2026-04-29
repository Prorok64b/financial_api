# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'V1::Account#deposit', type: :request do
  self.use_transactional_tests = false

  include_context 'authenticated user'

  subject(:request) { post '/v1/account/deposit', params: { amount: amount }, headers: headers, as: :json }

  let(:amount) { 50.00 }

  context 'when authenticated' do
    context 'with valid amount' do
      it 'returns success' do
        request

        expect(response).to have_http_status(:ok)
        expect(json_response['message']).to eq('Deposit successful')
        expect(json_response['balance']).to eq('150.0')
      end

      it 'increases the user balance' do
        expect { request }.to change { user.reload.balance }.from(100.00).to(150.00)
      end

      it 'creates a transaction record' do
        expect { request }.to change { user.transactions.count }.by(1)
      end

      context 'with decimal amount' do
        let(:amount) { 25.75 }

        it 'handles decimal amounts' do
          request

          expect(response).to have_http_status(:ok)
          expect(user.reload.balance).to eq(125.75)
        end
      end
    end

    context 'with invalid amount' do
      context 'when amount is zero' do
        let(:amount) { 0 }

        it 'returns error' do
          request

          expect(response).to have_http_status(:unprocessable_entity)
          expect(json_response['error']).to eq('Amount must be greater than 0')
        end
      end

      context 'when amount is negative' do
        let(:amount) { -50 }

        it 'returns error' do
          request

          expect(response).to have_http_status(:unprocessable_entity)
          expect(json_response['error']).to eq('Amount must be greater than 0')
        end

        it 'does not change balance' do
          expect { request }.not_to change { user.reload.balance }
        end
      end

      context 'when deposit would exceed balance limit' do
        let(:user) { create(:user, balance: 999_000.00) }
        let(:amount) { 1_001.00 }

        it 'returns error with helpful message' do
          request

          expect(response).to have_http_status(:unprocessable_entity)
          expect(json_response['error']).to include('Current balance is 999000.0')
          expect(json_response['error']).to include('maximum deposit amount is 999.99')
        end

        it 'does not change balance' do
          expect { request }.not_to change { user.reload.balance }
        end
      end

      context 'when deposit would exactly reach the limit' do
        let(:user) { create(:user, balance: 999_000.00) }
        let(:amount) { 999.99 }

        it 'succeeds' do
          request

          expect(response).to have_http_status(:ok)
          expect(user.reload.balance).to eq(999_999.99)
        end
      end

      context 'when amount has more than 2 decimal places' do
        let(:amount) { 50.999 }

        it 'returns error' do
          request

          expect(response).to have_http_status(:unprocessable_entity)
          expect(json_response['error']).to include('must have at most 2 decimal places')
        end

        it 'does not change balance' do
          expect { request }.not_to change { user.reload.balance }
        end
      end

      context 'when amount has exactly 2 decimal places' do
        let(:amount) { 50.99 }

        it 'succeeds' do
          request

          expect(response).to have_http_status(:ok)
          expect(user.reload.balance).to eq(150.99)
        end
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
