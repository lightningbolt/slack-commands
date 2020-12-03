class ApplicationController < ActionController::Base

  protected

  def check_slack_token
    unless params[:token].in?(SLACK_TOKENS[controller_name])
      render :nothing => true, :status => :unauthorized
    end
  end

end
