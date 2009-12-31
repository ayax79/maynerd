# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def rpx_token_url
    dest = url_for :controller => :sessions, :action => :rpx_return, :only_path => false
    @rpx.signin_url(dest)
  end

  def rpx_map_url
    dest = url_for :controller => :sessions, :action => :rpx_map_return, :only_path => false
    @rpx.signin_url(dest)
  end

end
