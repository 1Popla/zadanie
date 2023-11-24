class Api::ChartController < ApplicationController
  skip_load_and_authorize_resource

  def get_solar
    user = authenticate_user(params[:apikey])
    return unless user

    valid_subscription?(user) ? process_solar_request(params[:lat], params[:lng], user) : render_no_valid_subscription
  end

  private

  def authenticate_user(apikey)
    user = User.find_by(apikey: apikey)
    return user if user

    render_error("Unknown ApiKey. Please sign in at https://pro.solary.org/login to check your key.", 400)
    nil
  end

  def valid_subscription?(user)
    valid_until = calculate_valid_until(user)
    valid_until > Time.now
  end

  def process_solar_request(lat, lng, user)
    lat.present? && lng.present? ? process_location_request(lat, lng) : render_subscription_data(user)
  end

  def process_location_request(lat, lng)
    latitude, longitude = lat.to_f.round, lng.to_f.round
    valid_coordinates?(latitude, longitude) ? render_location_data(latitude, longitude) : render_error("Parameters out of range", 400)
  end

  def render_location_data(latitude, longitude)
    location = Location.find_by(lat: latitude, lon: longitude)
    if location
      chart_solars = ChartSolar.where(location_id: location.id).presence || ChartSolar.new.create_location(location.id)
      data = calculate_solar_data(chart_solars)
      render json: data, status: :ok
    else
      render_error("Location not found", 404)
    end
  end

  def calculate_solar_data(chart_solars)
    chart_solars.each_with_object({ values: [], max_azymut: 0, max_elevation: 0, min_azymut: 180, min_elevation: 180, sum_power: 0.0 }) do |value, obj|
      obj[:values] << { azymut: value.azymut, elevation: value.elevation, power: value.power }
      obj[:max_azymut] = [obj[:max_azymut], value.azymut.to_i].max
      obj[:max_elevation] = [obj[:max_elevation], value.elevation.to_i].max
      obj[:min_azymut] = [obj[:min_azymut], value.azymut.to_i].min
      obj[:min_elevation] = [obj[:min_elevation], value.elevation.to_i].min
      obj[:sum_power] += value.power.to_f
    end
  end

  def valid_coordinates?(latitude, longitude)
    latitude.between?(-65, 65) && longitude.between?(-180, 180)
  end

  def render_subscription_data(user)
    valid_until = calculate_valid_until(user)
    data = {
      subscription_valid: true,
      expiration_date: valid_until,
      valid_for_days: (valid_until - Time.now).to_i / (60 * 60 * 24)
    }
    render json: data, status: :ok
  end

  def calculate_valid_until(user)
    user.subscriptions.reduce(Time.new(1970)) do |final, subscription|
      period_in_seconds = subscription.subscription_type.period * 86_400
      [final, subscription.created_at + period_in_seconds].max
    end
  end

  def render_no_valid_subscription
    render_error("You don't have any valid subscriptions. Visit https://pro.solary.org/signup?role_id=9 to acquire one now.", 402)
  end

  def render_error(message, status)
    render json: { error: message }, status: status
  end
end
