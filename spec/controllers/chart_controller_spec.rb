require 'spec_helper'
require 'active_support/core_ext/object/blank'

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

module Api; end

require_relative '../../chart_controller.rb'

RSpec.describe Api::ChartController do
    let(:controller) { Api::ChartController.new }
    let(:valid_apikey) { 'valid_api_key' }
    let(:invalid_apikey) { 'invalid_api_key' }
    let(:valid_lat) { '50.0' }
    let(:valid_lng) { '10.0' }
    let(:invalid_lat) { '100.0' }
    let(:invalid_lng) { '200.0' }

    describe '#get_solar' do
      before do
        allow(controller).to receive(:render_error)
        allow(controller).to receive(:render)
      end

      context 'with valid API key and subscription' do
        let(:user) { User.new([Subscription.new(Time.now, double('SubscriptionType', period: 30))]) }

        before do
          allow(User).to receive(:find_by).with(apikey: valid_apikey).and_return(user)
          allow(controller).to receive(:calculate_valid_until).with(user).and_return(Time.now + (30 * 24 * 60 * 60)) # 30 days in seconds
        end

        it 'renders solar data for valid coordinates' do
          controller.params = { apikey: valid_apikey, lat: valid_lat, lng: valid_lng }
          expect(controller).to receive(:process_location_request).with(valid_lat, valid_lng)
          controller.get_solar
        end

        it 'renders subscription data for missing coordinates' do
          controller.params = { apikey: valid_apikey }
          expect(controller).to receive(:render_subscription_data).with(user)
          controller.get_solar
        end
      end

      context 'with valid API key but no subscription' do
        let(:user) { User.new([]) }

        before do
          allow(User).to receive(:find_by).with(apikey: valid_apikey).and_return(user)
          allow(controller).to receive(:calculate_valid_until).with(user).and_return(Time.now - (24 * 60 * 60)) # 1 day in seconds
        end

        it 'renders no valid subscription error' do
          controller.params = { apikey: valid_apikey }
          expect(controller).to receive(:render_no_valid_subscription)
          controller.get_solar
        end
      end

      context 'with invalid API key' do
        it 'renders authentication error' do
          controller.params = { apikey: invalid_apikey }
          allow(User).to receive(:find_by).with(apikey: invalid_apikey).and_return(nil)

          expect(controller).to receive(:render_error).with("Unknown ApiKey. Please sign in at https://pro.solary.org/login to check your key.", 400)
          controller.get_solar
        end
      end

      context 'with invalid coordinates' do
        let(:user) { User.new([Subscription.new(Time.now, double('SubscriptionType', period: 30))]) }

        before do
          allow(User).to receive(:find_by).with(apikey: valid_apikey).and_return(user)
          allow(controller).to receive(:calculate_valid_until).with(user).and_return(Time.now + (30 * 24 * 60 * 60))
        end

        it 'renders coordinates out of range error' do
          controller.params = { apikey: valid_apikey, lat: invalid_lat, lng: invalid_lng }
          expect(controller).to receive(:render_error).with("Parameters out of range", 400)
          controller.get_solar
        end
      end
    end
  end