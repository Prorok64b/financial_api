# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'V1::Account#deposit', type: :request do
  self.use_transactional_tests = false

  include_context 'authenticated user'

  subject(:request) { post '/v1/account/deposit', params: params, headers: headers, as: :json }

  let(:params) { { amount: amount } }
  let(:amount) { 50.00 }

  context 'when authenticated' do
    context 'with empty params' do
      let(:params) { {} }

      it 'returns error' do
        request

        expect(response).to have_http_status(:bad_request)
      end
    end

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

      context 'with 1 decimal place amount' do
        let(:amount) { 25.5 }

        it 'succeeds' do
          request

          expect(response).to have_http_status(:ok)
          expect(user.reload.balance).to eq(125.5)
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

      context 'when deposit amount exceeds maximum limit' do
        let(:amount) { 1_000_001.00 }

        it 'returns error with message' do
          request

          expect(response).to have_http_status(:unprocessable_entity)
          expect(json_response['error']).to eq('Maximum deposit amount is 1000000')
        end

        it 'does not change balance' do
          expect { request }.not_to change { user.reload.balance }
        end
      end

      context 'when deposit is at maximum allowed amount' do
        let(:amount) { 1_000_000.00 }

        it 'succeeds' do
          request

          expect(response).to have_http_status(:ok)
          expect(user.reload.balance).to eq(1_000_100.00)
        end
      end

      context 'when deposit would push balance over 1 million' do
        let(:user) { create(:user, balance: 900_000.00) }
        let(:amount) { 500_000.00 }

        it 'succeeds because only deposit amount is limited' do
          request

          expect(response).to have_http_status(:ok)
          expect(user.reload.balance).to eq(1_400_000.00)
        end
      end

      context 'when amount has more than 2 decimal places' do
        let(:amount) { 50.999 }

        it 'returns error' do
          request

          expect(response).to have_http_status(:bad_request)
          expect(json_response['error']['amount']).to include('must have at most 2 decimal places')
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
