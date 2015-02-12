class WelcomeEmailWorker
  include Sidekiq::Worker

  def perform(user_id)
    user = User.find(user_id)
    WelcomeMailer.welcome_email(user).deliver
  end
end