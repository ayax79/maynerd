require 'json'

class UsersController < ApplicationController

  skip_before_filter :login_required, :only => [ :create, :new ]

  def new
    @user = User.new
    if session[:registration]
      reg = session[:registration]
      @user.login = reg[:login]
      @open_id = reg[:open_id]
    end
  end

  def create
    logout_keeping_session!
    @user = User.new(params[:user])
    success = @user && @user.save
    if success && @user.errors.empty?

      # map the open_id from the session if there was one
      if session[:registration]
        reg = session[:registration]
        @rpx.map reg[:open_id], @user.id
      end

      # if this is an open id registration clear out the user from the session
      session.delete :registration

      # Protects against session fixation attacks, causes request forgery
      # protection if visitor resubmits an earlier form using back
      # button. Uncomment if you understand the tradeoffs.
      # reset session
      self.current_user = @user # !! now logged in
      redirect_back_or_default('/')
      flash[:notice] = "Thanks for signing up!"
    else
      flash[:error] = "We couldn't set up that account, sorry.  Please try again, or contact an admin (link is above)."
      render :action => 'new'
    end
  end

  def single_update
    user = self.current_user

    user_params = params[:user]

    # there should only be one in the hash but iterate anyway
    user_params.each { |k, v| user.update_attribute k, v }

    respond_to do | format |
      format.json do
        if !user_params.empty?
          render :json => user_params[user_params.keys.first]
        else
          render :head => :ok
        end
      end
    end

  end

end