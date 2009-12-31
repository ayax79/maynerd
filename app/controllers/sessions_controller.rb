# This controller handles the login/logout function of the site.  
class SessionsController < ApplicationController

  skip_before_filter :login_required

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
      @login = params[:login]
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
    logout_keeping_session!

    if params[:error]
      flash[:error] = "OpenID Authentication Failed: #{params[:error]}"
      redirect_back_or_default('/')
      return
    end

    if !params[:token]
      flash[:notice] = "OpenID Authentication Cancelled"
      redirect_back_or_default('/')
      return
    end

    data = @rpx.auth_info(params[:token], request.url)

    identifier = data["identifier"]
    primary_key = data["primaryKey"]


    # we need to create and map a new user
    if !primary_key
      user = User.new
      user.login = determine_username_from_rpx_response(data)
      user.save
      primary_key = user.id
      @rpx.map identifier, primary_key
      self.current_user
    elsif identifier
      self.current_user = User.find(identifier)
    end

    if logged_in?
      redirect_to :controller => 'site', :action => 'index'
    else
      redirect_back_or_default('/')
    end

  end

  protected
  # Track failed login attempts
  def note_failed_signin
    flash[:error] = "Couldn't log you in as '#{params[:login]}'"
    logger.warn "Failed login for '#{params[:login]}' from #{request.remote_ip} at #{Time.now.utc}"
  end

  def determine_username_from_rpx_response(data)
    profile = data['profile']
    if profile
      username = profile['preferredUsername']
      return username if username
      username = profile['displayName']
      return username if username
    end
    #Finally I guess we just use their full url
    data['primaryKey']
  end


end
