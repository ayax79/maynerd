module SessionsHelper

  def rpx_token_url
    dest = url_for :controller => :sessions, :action => :rpx_return, :only_path => false
    @rpx.signin_url(dest)
  end

end