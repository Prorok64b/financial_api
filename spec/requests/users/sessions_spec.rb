# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Users::Sessions', type: :request do
  describe 'POST /users/sign_in' do
    subject(:request) { post '/users/sign_in', params: { user: user_params }, as: :json }

    let!(:user) { create(:user, email: 'test@example.com', password: 'password123') }

    context 'with valid credentials' do
      let(:user_params) { { email: 'test@example.com', password: 'password123' } }

      it 'returns ok status' do
        request

        expect(response).to have_http_status(:ok)
      end

      it 'returns success message' do
        request

        expect(json_response['message']).to eq('Logged in')
      end

      it 'returns user data' do
        request

        expect(json_response['user']['email']).to eq('test@example.com')
        expect(json_response['user']).to have_key('created_at')
        expect(json_response['user']).to have_key('updated_at')
      end

      it 'does not return sensitive fields' do
        request

        expect(json_response['user']).not_to have_key('jti')
        expect(json_response['user']).not_to have_key('encrypted_password')
      end

      it 'returns JWT token in authorization header' do
        request

        expect(response.headers['Authorization']).to be_present
        expect(response.headers['Authorization']).to start_with('Bearer ')
      end
    end

    context 'with invalid credentials' do
      context 'when password is wrong' do
        let(:user_params) { { email: 'test@example.com', password: 'wrongpassword' } }

        it 'returns unauthorized status' do
          request

          expect(response).to have_http_status(:unauthorized)
        end

        it 'returns error message' do
          request

          expect(json_response['error']).to eq('Invalid email or password.')
        end

        it 'does not return JWT token' do
          request

          expect(response.headers['Authorization']).to be_nil
        end
      end

      context 'when email does not exist' do
        let(:user_params) { { email: 'nonexistent@example.com', password: 'password123' } }

        it 'returns unauthorized status' do
          request

          expect(response).to have_http_status(:unauthorized)
        end

        it 'returns error message' do
          request

          expect(json_response['error']).to eq('Invalid email or password.')
        end
      end

      context 'when email is missing' do
        let(:user_params) { { password: 'password123' } }

        it 'returns unauthorized status' do
          request

          expect(response).to have_http_status(:unauthorized)
        end
      end

      context 'when password is missing' do
        let(:user_params) { { email: 'test@example.com' } }

        it 'returns unauthorized status' do
          request

          expect(response).to have_http_status(:unauthorized)
        end
      end
    end
  end

  describe 'DELETE /users/sign_out' do
    subject(:request) { delete '/users/sign_out', headers: headers, as: :json }

    context 'when authenticated' do
      let(:user) { create(:user) }
      let(:headers) { auth_headers(user) }

      it 'returns ok status' do
        request

        expect(response).to have_http_status(:ok)
      end

      it 'returns success message' do
        request

        expect(json_response['message']).to eq('Logged out')
      end

      it 'invalidates the JWT token' do
        request

        # Try to use the same token again
        get '/v1/account/balance', headers: headers, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when not authenticated' do
      let(:headers) { {} }

      it 'returns ok status' do
        request

        expect(response).to have_http_status(:ok)
      end
    end
  end
end
