# This controller handles the login/logout function of the site.  
class SessionsController < ApplicationController

  skip_before_filter :login_required

  # render new.rhtml
  def new
  end

  def create
    logout_keeping_session!
    user = User.authenticate(params[:login], params[:password])
    if user
      # Protects against session fixation attacks, causes request forgery
      # protection if user resubmits an earlier form using back
      # button. Uncomment if you understand the tradeoffs.
      # reset_session
      self.current_user = user
      new_cookie_flag = (params[:remember_me] == "1")
      handle_remember_cookie! new_cookie_flag
      redirect_back_or_default('/')
      flash[:notice] = "Logged in successfully"
    else
      note_failed_signin
      @login       = params[:login]
      @remember_me = params[:remember_me]
      render :action => 'new'
    end
  end

  def destroy
    logout_killing_session!
    flash[:notice] = "You have been logged out."
    redirect_back_or_default('/')
  end


  def rpx_return
    if params[:error]
      flash[:error] = "OpenID Authentication Failed: #{params[:error]}"
      redirect_to 'login'
      return
    end

    if !params[:token]
      flash[:notice] = "OpenID Authentication Cancelled"
      redirect_to 'login'
      return
    end

    data = @rpx.auth_info(params[:token], request.url)

    identifier = data["identifier"]
    primary_key = data["primaryKey"]

    if primary_key.nil?
      if @current_user.nil?
        flash[:notice] = "you are not signed in"
      else
        @rpx.map identifier, @current_user.id
        flash[:notice] = "#{identifier} added to your account"
      end
      redirect_to :controller => "site", :action => "index"
    else
      if @current_user.id == primary_key.to_i
        flash[:notice] = "That OpenID was already associated with this account"
        redirect_to :controller => "site", :action => "index"
      else
        # The OpenID was already associated with a different user account.
        @page_title = "Replace OpenID Account"
        session[:identifier] = identifier
        @other_user = User.find_by_id primary_key
      end
    end
  end

protected
  # Track failed login attempts
  def note_failed_signin
    flash[:error] = "Couldn't log you in as '#{params[:login]}'"
    logger.warn "Failed login for '#{params[:login]}' from #{request.remote_ip} at #{Time.now.utc}"
  end
end
