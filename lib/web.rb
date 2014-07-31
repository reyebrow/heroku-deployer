require 'sinatra'
require 'json'
require 'magnum/payload'
require_relative 'heroku_deployer'
require_relative 'deploy_job'

class Web < Sinatra::Application
  before do
    if ENV['DEPLOY_SECRET'].nil? || ENV['DEPLOY_SECRET'].empty?
      halt "Set your DEPLOY_SECRET"
    end

    if ENV['DEPLOY_SSH_KEY'].nil? || ENV['DEPLOY_SSH_KEY'].empty?
      halt "Set your DEPLOY_SSH_KEY"
    end
  end

  get '/' do
    "Nothing to see here!"
  end

  post '/deploy/:provider/:app_name/:secret' do |provider, app_name, secret|

    payload = Magnum::Payload.parse(provider, params["payload"])

    if ENV["#{app_name}_BRANCH"]
      return unless ENV["#{app_name}_BRANCH"] == payload.branch
    elsif ENV["DEFAULT_BRANCH"]
      return unless ENV["DEFAULT_BRANCH"] == payload.branch
    end

    if secret == ENV['DEPLOY_SECRET']
      logger.info "correct secret"
      if HerokuDeployer.exists?(app_name)
        logger.info "app exists"
        DeployJob.new.async.perform(app_name)
      else
        logger.info "no app"
      end
    else
      logger.info "wrong secret"
    end
    "maybe"
  end
end
