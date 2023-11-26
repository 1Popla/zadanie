class SolarDataService
  def initialize(lat, lng)
    @lat = lat
    @lng = lng
  end

  def process_solar_request
    @lat.present? && @lng.present? ? process_location_request : { error: "Latitude and Longitude must be provided", status: 400 }
  end

  private

  def process_location_request
    latitude, longitude = @lat.to_f.round, @lng.to_f.round
    if valid_coordinates?(latitude, longitude)
      render_location_data(latitude, longitude)
    else
      { error: "Parameters out of range", status: 400 }
    end
  end

  def render_location_data(latitude, longitude)
    location = Location.find_by(lat: latitude, lon: longitude)
    if location
      chart_solars = ChartSolar.where(location_id: location.id).presence || ChartSolar.new.create_location(location.id)
      data = calculate_solar_data(chart_solars)
      { json: data, status: :ok }
    else
      { error: "Location not found", status: 404 }
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
end
