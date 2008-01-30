class LanguageController < ApplicationController
  # Remove this line if your controller should only be accessible to users
  # that are logged in:
  no_login_required
  
  def set_lang
    if params[:lang].downcase == 'reset'
      session[:language] = nil
    else
      session[:language] = params[:lang].downcase
    end
    
    if !params[:from].blank?
      redirect_to params[:from] and return
    else
      redirect_to '/' and return
    end
  end
end
