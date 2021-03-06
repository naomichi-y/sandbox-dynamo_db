class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  rescue_from Exception, with: :render_500

  before_action :set_dynamo_db

  def render_500(e)
    @e = e
    render template: 'errors/error_500', status: 500
  end

  private
  def set_dynamo_db
    @dynamo_db = DynamoDb.new.connect
  end
end
