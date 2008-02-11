class LanguageController < ApplicationController
  # Remove this line if your controller should only be accessible to users
  # that are logged in:
  no_login_required
  
  def set_lang
    # setting up the :language session variable which will be referenced in the tags
    if params[:language].downcase == 'reset'
      session[:language] = nil
    else
      session[:language] = params[:language].downcase
    end
    
    if !params[:from].blank?
      redirect_to params[:from] and return
    else
      redirect_to '/' and return
    end
  end
end
