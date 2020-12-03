class TrashTalkController < ApplicationController
  before_action :check_slack_token, only: [:index]

  def index
    entity = params[:text]
    entity = entity.upcase unless entity.first == "@"
    slack_text = ERB.new(INSULTS.sample).result(binding)
    response_payload = {:response_type => 'in_channel',
      :text => slack_text,
      :username => params[:user_name]}
    Rails.logger.info(slack_text.inspect)
    render :json => response_payload, :status => :ok
  end
end
