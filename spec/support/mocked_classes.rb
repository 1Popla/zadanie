# Mocks and stubs
class ApplicationController
  attr_accessor :params

  def initialize
    @params = {}
  end

  def self.skip_load_and_authorize_resource(*args)
    # No-op (No Operation)
  end

  def render_error(message, status)
    # Mock implementation
  end

  def render(json:, status:)
    # Mock implementation
  end
end

class Subscription
  attr_accessor :created_at, :subscription_type
  def initialize(created_at, subscription_type)
    @created_at = created_at
    @subscription_type = subscription_type
  end
end

class User
  attr_accessor :subscriptions
  def self.find_by(apikey:)
    # Mock implementation
  end

  def initialize(subscriptions)
    @subscriptions = subscriptions
  end
end

class Location
  def self.find_by(lat:, lon:)
    # Mock implementation
  end

  def id
    # Mock implementation
  end
end

class ChartSolar
  def self.where(location_id:)
    # Mock implementation
  end
end

class SubscriptionService
  def initialize(user); end
  def valid_subscription?; end
end

class SolarDataService
  def initialize(lat, lng); end
  def process_solar_request; end
end

module Api; end