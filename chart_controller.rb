class Api::ChartController < ApplicationController
  skip_load_and_authorize_resource

  def get_solar
    user = authenticate_user(params[:apikey])
    return unless user

    subscription_service = SubscriptionService.new(user)
    if subscription_service.valid_subscription?
      solar_data_service = SolarDataService.new(params[:lat], params[:lng])
      solar_response = solar_data_service.process_solar_request

      if solar_response.is_a?(Hash) && solar_response.key?(:json) && solar_response.key?(:status)
        render json: solar_response[:json], status: solar_response[:status]
      else
        render_error("An unexpected error occurred", 500)
      end
    else
      render_no_valid_subscription
    end
  end

  private

  def authenticate_user(apikey)
    user = User.find_by(apikey: apikey)
    return user if user

    render_error("Unknown ApiKey. Please sign in at https://pro.solary.org/login to check your key.", 400)
    nil
  end

  def render_no_valid_subscription
    render_error("You don't have any valid subscriptions. Visit https://pro.solary.org/signup?role_id=9 to acquire one now.", 402)
  end

  def render_error(message, status)
    render json: { error: message }, status: status
  end
end
