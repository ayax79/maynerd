# This controller handles the login/logout function of the site.  
class SessionsController < ApplicationController

  skip_before_filter :verify_authenticity_token
  skip_before_filter :login_required, :only => [ :new, :create, :destroy, :rpx_return ]

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


    if !primary_key

      username = determine_username_from_rpx_response(data)
      user = User.find_by_login username

      # we will setup a user if it doesn't exist and
      # forward to the registration page so that it can be finished up.
      if !user
        reg = { :login => username, :open_id => identifier}
        session[:registration] = reg
        session[:open_id] = identifier
      else
        # username already exists, log them in a

        @rpx.map identifier, user.id
        self.current_user = user
      end

    else
      self.current_user = User.find(primary_key)
    end

    if logged_in?
      redirect_to :controller => 'site', :action => 'index'
    elsif session[:registration]
      redirect_to :controller => 'users', :action => 'new'
    else
      redirect_back_or_default('/')
    end

  end

  def rpx_map_return
    if params[:error]
      flash[:error] = "OpenID Authentication Failed: #{params[:error]}"
      redirect_to :controller => "site", :action => "index"
      return
    end

    if !params[:token]
      flash[:notice] = "OpenID Authentication Cancelled"
      redirect_to :controller => "site", :action => "index"
      return
    end

    data = @rpx.auth_info(params[:token], request.url)

    identifier = data["identifier"]
    primary_key = data["primaryKey"]

    if primary_key.nil?
      @rpx.map identifier, self.current_user.id
      flash[:notice] = "#{identifier} added to your account"
      redirect_to :controller => "site", :action => "index"
    else
      if self.current_user.id == primary_key.to_i
        flash[:notice] = "That OpenID was already associated with this account"
        redirect_to :controller => "site", :action => "index"
      else
        # The OpenID was already associated with a different user account.
        session[:identifier] = identifier
        @other_user = User.find_by_id primary_key
        flash[:notice] = "That OpenID was already associated with #{@other_user.login}, <a onclick=\"javascript:RPXUtil.unmap(\\'#{identifier}\\')\" href=\"#\">Unmap</a>?"
        redirect_to :controller => "site", :action => "index"
      end
    end

  end

  def rpx_unmap
    identifier = params[:open_id]

    @rpx.unmap identifier, self.current_user.id

    respond_to do |format|
      format.json { render :json => "OpenID #{identifier} removed" }
      format.html do
        flash[:notice] = "OpenID #{identifier} removed"
        redirect_to :controller => :site, :action => "index"
      end
    end
  end

  protected
  # Track failed login attempts
  def note_failed_signin
    flash[:error] = "Couldn't log you in as '#{params[:login]}'"
    logger.warn "Failed login for '#{params[:login]}' from #{request.remote_ip} at #{Time.now.utc}"
  end

  def determine_username_from_rpx_response(data)
    username = data['preferredUsername']
    return username if username
    username = data['displayName']
    return username if username
    #Finally I guess we just use their full url
    data['primaryKey']
  end

end
