# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'V1::Account#balance', type: :request do
  include_context 'authenticated user'

  subject(:request) { get '/v1/account/balance', headers: headers, as: :json }

  context 'when authenticated' do
    it 'returns the current balance' do
      request

      expect(response).to have_http_status(:ok)
      expect(json_response['balance']).to eq('100.0')
    end

    it 'returns zero balance for new user' do
      user.update!(balance: 0)
      request

      expect(json_response['balance']).to eq('0.0')
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
