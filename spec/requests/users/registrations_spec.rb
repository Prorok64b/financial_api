# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Users::Registrations', type: :request do
  describe 'POST /users' do
    subject(:request) { post '/users', params: { user: user_params }, as: :json }

    context 'with valid parameters' do
      let(:user_params) { { email: 'newuser@example.com', password: 'password123' } }

      it 'returns created status' do
        request

        expect(response).to have_http_status(:created)
      end

      it 'returns success message' do
        request

        expect(json_response['message']).to eq('Signed up')
      end

      it 'returns user data' do
        request

        expect(json_response['user']['email']).to eq('newuser@example.com')
        expect(json_response['user']).to have_key('created_at')
        expect(json_response['user']).to have_key('updated_at')
      end

      it 'does not return sensitive fields' do
        request

        expect(json_response['user']).not_to have_key('jti')
        expect(json_response['user']).not_to have_key('encrypted_password')
      end

      it 'creates a new user' do
        expect { request }.to change { User.count }.by(1)
      end

      it 'returns JWT token in authorization header' do
        request

        expect(response.headers['Authorization']).to be_present
        expect(response.headers['Authorization']).to start_with('Bearer ')
      end

      it 'creates user with zero balance' do
        request

        expect(User.last.balance).to eq(0)
      end
    end

    context 'with invalid parameters' do
      context 'when email is missing' do
        let(:user_params) { { password: 'password123' } }

        it 'returns unprocessable entity status' do
          request

          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'returns error message' do
          request

          expect(json_response['errors']).to include("Email can't be blank")
        end

        it 'does not create a user' do
          expect { request }.not_to change { User.count }
        end
      end

      context 'when password is missing' do
        let(:user_params) { { email: 'newuser@example.com' } }

        it 'returns unprocessable entity status' do
          request

          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'returns error message' do
          request

          expect(json_response['errors']).to include("Password can't be blank")
        end
      end

      context 'when email is invalid' do
        let(:user_params) { { email: 'invalid-email', password: 'password123' } }

        it 'returns unprocessable entity status' do
          request

          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'returns error message' do
          request

          expect(json_response['errors']).to include('Email is invalid')
        end
      end

      context 'when email is already taken' do
        let!(:existing_user) { create(:user, email: 'taken@example.com') }
        let(:user_params) { { email: 'taken@example.com', password: 'password123' } }

        it 'returns unprocessable entity status' do
          request

          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'returns error message' do
          request

          expect(json_response['errors']).to include('Email has already been taken')
        end
      end

      context 'when password is too short' do
        let(:user_params) { { email: 'newuser@example.com', password: '12345' } }

        it 'returns unprocessable entity status' do
          request

          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'returns error message' do
          request

          expect(json_response['errors']).to include('Password is too short (minimum is 6 characters)')
        end
      end
    end
  end
end
