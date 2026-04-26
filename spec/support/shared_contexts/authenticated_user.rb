# frozen_string_literal: true

RSpec.shared_context 'authenticated user' do
  let(:user) { create(:user, balance: 100.00) }
  let(:headers) { auth_headers(user) }
end

RSpec.shared_context 'unauthenticated request' do
  let(:headers) { {} }
end
