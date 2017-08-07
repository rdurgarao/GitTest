Sidekiq.configure_server do |config|
  unless Rails.env.development?
    config.redis = { url: Settings.Redis.url }
  end
end

Sidekiq.configure_client do |config|
  unless Rails.env.development?
    config.redis = { url: Settings.Redis.url }
  end
end

require 'sidekiq'
require 'sidekiq-status'

Sidekiq.configure_client do |config|
  config.client_middleware do |chain|
    chain.add Sidekiq::Status::ClientMiddleware
  end
end

Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add Sidekiq::Status::ServerMiddleware, expiration: 30.minutes # default
  end
  config.client_middleware do |chain|
    chain.add Sidekiq::Status::ClientMiddleware
  end
end