class SubscriptionService
  def initialize(user)
    @user = user
  end

  def valid_subscription?
    valid_until > Time.now
  end

  def calculate_valid_until
    @user.subscriptions.reduce(Time.new(1970)) do |final, subscription|
      period_in_seconds = subscription.subscription_type.period * 86_400
      [final, subscription.created_at + period_in_seconds].max
    end
  end

  private

  def valid_until
    calculate_valid_until
  end
end
