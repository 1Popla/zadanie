class Api::ChartController < ApplicationController
  skip_load_and_authorize_resource

  # http://sea-test.deltacodes.pl/api/solar_chart?apikey=96cd5edf0049380c21f30981b3762cd2&lat=40&lng=-74
  def get_solar
    user = User.find_by(:apikey => params[:apikey])
    if params[:apikey].present? && user
      subscription_types = SubscriptionType.all()
      subscriptions = Subscription.where(:user_id => user.id)
      final_subscription = Time.new(1970)
      valid_until = Time.new(1970)
      subscriptions.each do |subscription| 
        # Dodac sprawdzanie typu
        period = SubscriptionType.find(subscription.subscription_type).period
        valid_until = subscription.created_at + period.days
        if final_subscription < valid_until
          final_subscription = valid_until
        end
      end

      unless valid_until > Time.now
        #no vlid subscriptions
        respond_to do |format|
          format.json { render json: {:error => "You don't have any valid subscriptions. Visit <a href='https://pro.solary.org/signup?role_id=9' title='Sign up at pro.solary.org'>pro.solary.org</a> to acquire one now."}, status: 402}
        end
      else
        #valid subscription 
        unless params[:lat].present? && params[:lng].present?
          data = {
            :subscription_valid => true,
            :expiration_date => valid_until,
            :valid_for_days => (valid_until - Time.now).to_i / (60*60*24)
          }
          respond_to do |format|
            format.json { render json: data, status: :ok}
          end
        else
          latitude = params[:lat].to_f.round
          longitude = params[:lng].to_f.round
         
          if latitude.between?(-65,65) && longitude.between?(-180,180)
              
              location = Location.where(lat: latitude, lon: longitude).take

              chart_solars = ChartSolar.where(location_id: location.id)
              if true #chart_solars.blank?
                  cs = ChartSolar.new
                  chart_solars = cs.create_location(location.id)
              end
              
              # cs = ChartSolar.new
              # chart_solars = cs.create_location(location.id)

              values = []    
              data = {}

              max_azymut, max_elevation, sum_power = 0, 0, 0.0
              min_azymut, min_elevation = 180, 180
              chart_solars.each do |value|
                  values << { :azymut => value['azymut'], :elevation => value['elevation'], :power => value['power'] }

                  if max_azymut < value['azymut'].to_i
                      max_azymut = value['azymut'].to_i
                  end
                  if max_elevation < value['elevation'].to_i
                      max_elevation = value['elevation'].to_i
                  end
                  if min_azymut > value['azymut'].to_i
                      min_azymut = value['azymut'].to_i
                  end
                  if min_elevation > value['elevation'].to_i
                      min_elevation = value['elevation'].to_i
                  end

                  sum_power += value['power'].to_f

              end

              data["values"] = values
              data["max_azymut"] = max_azymut
              data["min_azymut"] = min_azymut
              data["max_elevation"] = max_elevation
              data["min_elevation"] = min_elevation
              data["sum_power"] = sum_power

              respond_to do |format|
                format.json { render json: data, status: :ok}
              end
          else
              respond_to do |format|
                format.json { render json: {:error => "Parameters our of range"}, status: 400}
              end
          end
        end
      end
    else
      respond_to do |format|
        format.json { render json: {:error => "Unknown ApiKey. Please sign in at <a href='https://pro.solary.org/login' title='Login at pro.solary.org'>pro.solary.org</a> to check your key."}, status: 400}
      end
    end
  end
end