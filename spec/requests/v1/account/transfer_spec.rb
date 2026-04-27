# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'V1::Account#transfer', type: :request do
  self.use_transactional_tests = false

  include_context 'authenticated user'

  subject(:request) do
    post '/v1/account/transfer',
         params: { amount: amount, recipient_email: recipient_email },
         headers: headers,
         as: :json
  end

  let(:recipient) { create(:user, balance: 50.00) }
  let(:recipient_email) { recipient.email }
  let(:amount) { 30.00 }

  context 'when authenticated' do
    context 'with valid transfer' do
      it 'returns success' do
        request

        expect(response).to have_http_status(:ok)
        expect(json_response['message']).to eq('Transfer successful')
        expect(json_response['amount']).to eq('30.0')
        expect(json_response['recipient']).to eq(recipient.email)
        expect(json_response['balance']).to eq('70.0')
      end

      it 'decreases sender balance and increases recipient balance' do
        expect { request }
          .to change { user.reload.balance }.from(100.00).to(70.00)
          .and change { recipient.reload.balance }.from(50.00).to(80.00)
      end

      it 'creates transaction records for both users' do
        expect { request }.to change { Transaction.count }.by(2)
      end
    end

    context 'with invalid recipient' do
      context 'when recipient does not exist' do
        let(:recipient_email) { 'nonexistent@example.com' }

        it 'returns not found' do
          request

          expect(response).to have_http_status(:not_found)
          expect(json_response['error']).to eq('Recipient not found')
        end
      end

      context 'when transferring to self' do
        let(:recipient_email) { user.email }

        it 'returns error' do
          request

          expect(response).to have_http_status(:unprocessable_entity)
          expect(json_response['error']).to eq('Cannot transfer to yourself')
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
    end

    context 'with invalid amount' do
      let(:amount) { 0 }

      it 'returns error for zero amount' do
        request

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['error']).to eq('Amount must be greater than 0')
      end
    end

    context 'when transfer would exceed recipient balance limit' do
      let(:user) { create(:user, balance: 10_000.00) }
      let(:recipient) { create(:user, balance: 999_000.00) }
      let(:amount) { 1_001.00 }

      it 'returns error' do
        request

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['error']).to include('Balance must be less than 1000000')
      end

      it 'does not change sender balance' do
        expect { request }.not_to change { user.reload.balance }
      end

      it 'does not change recipient balance' do
        expect { request }.not_to change { recipient.reload.balance }
      end
    end

    context 'when amount has more than 2 decimal places' do
      let(:amount) { 10.999 }

      it 'returns error' do
        request

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['error']).to include('must have at most 2 decimal places')
      end

      it 'does not change sender balance' do
        expect { request }.not_to change { user.reload.balance }
      end

      it 'does not change recipient balance' do
        expect { request }.not_to change { recipient.reload.balance }
      end
    end

    context 'when amount has exactly 2 decimal places' do
      let(:amount) { 10.99 }

      it 'succeeds' do
        request

        expect(response).to have_http_status(:ok)
        expect(user.reload.balance).to eq(89.01)
        expect(recipient.reload.balance).to eq(60.99)
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
