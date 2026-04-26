# frozen_string_literal: true

module RequestHelpers
  def auth_headers(user)
    post user_session_path, params: { user: { email: user.email, password: 'password123' } }, as: :json
    token = response.headers['Authorization']
    { 'Authorization' => token }
  end

  def json_response
    JSON.parse(response.body)
  end
end

RSpec.configure do |config|
  config.include RequestHelpers, type: :request
end
