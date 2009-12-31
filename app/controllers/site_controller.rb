class SiteController < ApplicationController

  def index
    @mappings = @rpx.mappings(@current_user.id)
  end

end
