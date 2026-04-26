# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'V1::Account#withdraw', type: :request do
  include_context 'authenticated user'

  subject(:request) { post '/v1/account/withdraw', params: { amount: amount }, headers: headers, as: :json }

  let(:amount) { 50.00 }

  context 'when authenticated' do
    context 'with valid amount and sufficient funds' do
      it 'returns success' do
        request

        expect(response).to have_http_status(:ok)
        expect(json_response['message']).to eq('Withdrawal successful')
        expect(json_response['balance']).to eq('50.0')
      end

      it 'decreases the user balance' do
        expect { request }.to change { user.reload.balance }.from(100.00).to(50.00)
      end

      context 'when withdrawing entire balance' do
        let(:amount) { 100.00 }

        it 'allows withdrawing entire balance' do
          request

          expect(response).to have_http_status(:ok)
          expect(user.reload.balance).to eq(0)
        end
      end
    end

    context 'with insufficient funds' do
      let(:amount) { 150.00 }

      it 'returns error' do
        request

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['error']).to eq('Insufficient funds')
      end

      it 'does not change balance' do
        expect { request }.not_to change { user.reload.balance }
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
