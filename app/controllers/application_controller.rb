# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base

  include AuthenticatedSystem

  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  layout 'default'

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password

  before_filter :rpx_setup
  before_filter :login_required

  protected

  def generate_password(size=8)
    alphanumerics = [('0'..'9'), ('A'..'Z'), ('a'..'z')].map {|range| range.to_a}.flatten
    (0...size).map { alphanumerics[Kernel.rand(alphanumerics.size)] }.join
  end

  private

  def rpx_setup
    unless Object.const_defined?(:RPX_API_KEY) && Object.const_defined?(:RPX_BASE_URL) && Object.const_defined?(:RPX_REALM)
      render :template => 'shared/const_message.html.erb'
      return false
    end
    @rpx = Rpx::RpxHelper.new(RPX_API_KEY, RPX_BASE_URL, RPX_REALM)
    return true
  end

end
