class LanguageController < ApplicationController
  no_login_required
  
  def set_lang
    session[:language] = params[:language].downcase == 'reset' ? nil : params[:language].downcase
    redirect_to(params[:from] || '/')
  end
end
