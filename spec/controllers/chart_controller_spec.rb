require 'spec_helper'
require 'active_support/core_ext/object/blank'
require 'support/mocked_classes'

require_relative '../../chart_controller.rb'

RSpec.describe Api::ChartController do
  let(:controller) { Api::ChartController.new }
  let(:valid_apikey) { 'valid_api_key' }
  let(:invalid_apikey) { 'invalid_api_key' }
  let(:valid_lat) { '50.0' }
  let(:valid_lng) { '10.0' }
  let(:invalid_lat) { '100.0' }
  let(:invalid_lng) { '200.0' }
  let(:nonexistent_lat) { '70.0' }
  let(:nonexistent_lng) { '20.0' }
  let(:invalid_lat_type) { 'not_a_number' }
  let(:invalid_lng_type) { 'not_a_number' }

  before do
    allow(controller).to receive(:render_error)
    allow(controller).to receive(:render)
  end

  describe '#get_solar' do
    context 'with valid API key and subscription' do
      let(:user) { User.new([Subscription.new(Time.now, double('SubscriptionType', period: 30))]) }
      let(:subscription_service) { instance_double(SubscriptionService, valid_subscription?: true) }
      let(:solar_data_service) { instance_double(SolarDataService, process_solar_request: { json: {}, status: :ok }) }

      before do
        allow(User).to receive(:find_by).with(apikey: valid_apikey).and_return(user)
        allow(SubscriptionService).to receive(:new).with(user).and_return(subscription_service)
      end

      it 'renders solar data for valid coordinates' do
        controller.params = { apikey: valid_apikey, lat: valid_lat, lng: valid_lng }
        allow(SolarDataService).to receive(:new).with(valid_lat, valid_lng).and_return(solar_data_service)
        expect(solar_data_service).to receive(:process_solar_request)
        controller.get_solar
      end

      it 'renders subscription data for missing coordinates' do
        controller.params = { apikey: valid_apikey }
        expect(subscription_service).to receive(:valid_subscription?).and_return(true)

        mock_response = { json: { subscription_valid: true }, status: :ok }
        allow(SolarDataService).to receive(:new).with(nil, nil).and_return(solar_data_service)
        allow(solar_data_service).to receive(:process_solar_request).and_return(mock_response)

        controller.get_solar
      end
    end

    context 'with valid API key but no subscription' do
      let(:user) { User.new([]) }
      let(:subscription_service) { instance_double(SubscriptionService, valid_subscription?: false) }

      before do
        allow(User).to receive(:find_by).with(apikey: valid_apikey).and_return(user)
        allow(SubscriptionService).to receive(:new).with(user).and_return(subscription_service)
      end

      it 'renders no valid subscription error' do
        controller.params = { apikey: valid_apikey }
        expect(controller).to receive(:render_error).with("You don't have any valid subscriptions. Visit https://pro.solary.org/signup?role_id=9 to acquire one now.", 402)
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
      let(:solar_data_service) { instance_double(SolarDataService, process_solar_request: { error: "Parameters out of range", status: 400 }) }

      before do
        allow(User).to receive(:find_by).with(apikey: valid_apikey).and_return(user)
        allow(SubscriptionService).to receive(:new).with(user).and_return(instance_double(SubscriptionService, valid_subscription?: true))
        allow(SolarDataService).to receive(:new).with(invalid_lat, invalid_lng).and_return(solar_data_service)
      end

      it 'renders coordinates out of range error' do
        controller.params = { apikey: valid_apikey, lat: invalid_lat, lng: invalid_lng }
        expect(solar_data_service).to receive(:process_solar_request)
        controller.get_solar
      end
    end

    context 'with valid API key and subscription, but location not found' do
      let(:user) { User.new([Subscription.new(Time.now, double('SubscriptionType', period: 30))]) }
      let(:solar_data_service) { instance_double(SolarDataService, process_solar_request: { error: "Location not found", status: 404 }) }

      before do
        allow(User).to receive(:find_by).with(apikey: valid_apikey).and_return(user)
        allow(SubscriptionService).to receive(:new).with(user).and_return(instance_double(SubscriptionService, valid_subscription?: true))
        allow(SolarDataService).to receive(:new).with(nonexistent_lat, nonexistent_lng).and_return(solar_data_service)
      end

      it 'renders location not found error' do
        controller.params = { apikey: valid_apikey, lat: nonexistent_lat, lng: nonexistent_lng }
        expect(solar_data_service).to receive(:process_solar_request)
        controller.get_solar
      end
    end

    context 'with invalid latitude and longitude types' do
      let(:user) { User.new([Subscription.new(Time.now, double('SubscriptionType', period: 30))]) }
      let(:solar_data_service) { instance_double(SolarDataService, process_solar_request: { error: "Parameters out of range", status: 400 }) }

      before do
        allow(User).to receive(:find_by).with(apikey: valid_apikey).and_return(user)
        allow(SubscriptionService).to receive(:new).with(user).and_return(instance_double(SubscriptionService, valid_subscription?: true))
        allow(SolarDataService).to receive(:new).with(invalid_lat_type, invalid_lng_type).and_return(solar_data_service)
      end

      it 'renders type error for invalid coordinate types' do
        controller.params = { apikey: valid_apikey, lat: invalid_lat_type, lng: invalid_lng_type }
        expect(solar_data_service).to receive(:process_solar_request)
        controller.get_solar
      end
    end
  end
end