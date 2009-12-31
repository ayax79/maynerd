module SessionsHelper

  def rpx_signin_url
    dest = url_for :controller => :rpx, :action => :login_return, :only_path => false
    @rpx.signin_url(dest)
  end

  def rpx_token_url
    dest = url_for :controller => :rpx, :action => :associate_return, :only_path => false
    @rpx.signin_url(dest)
  end

  def rpx_widget_url
    RPX_BASE_URL + '/openid/v2/widget'
  end
  
end