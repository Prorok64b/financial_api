# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  respond_to :json

  def destroy
    super { return render json: { message: 'Logged out' }, status: :ok }
  end

  private

  def respond_with(resource, _opts = {})
    if resource.persisted?
      render json: {
        message: 'Logged in',
        user: user_response(resource)
      }, status: :ok
    else
      render json: { error: 'Invalid Email or password.' }, status: :unauthorized
    end
  end

  def user_response(user)
    user.as_json(only: %i[email created_at updated_at])
  end

  def respond_to_on_destroy(_resource = nil)
    render json: { message: 'Logged out' }, status: :ok
  end
end
