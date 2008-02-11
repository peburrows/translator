# Uncomment this if you reference any of your controllers in activate
require_dependency 'application'

class TranslatorExtension < Radiant::Extension
  version "0.2"
  description "Allows you to render your pages in different languages based upon the browser's Accept-Language."
  url "http://dev.philburrows.com/svn/radiant-extensions/translator/trunk"
  
  # still plenty of work that needs to be done on this
  @@defaults = {
    :language => 'en-US'
  }
  cattr_accessor :defaults
  
  define_routes do |map|
    map.connect 'language/set/:language', :controller => 'language', :action => 'set_lang'
    map.connect ':language/*url',
                :controller => 'site',
                :action => 'show_page',
                :requirements => {
                  :language => /[a-zA-Z]{2}/
                }
  end
  
  def activate
    Page.send :include, TranslatorTags
    SiteController.class_eval{
      session :disabled => false
      before_filter :set_up_lang
    private
      def set_up_lang
        if params[:language]
          # we want to save the four-letter language code, not just the two
          # logger.error("we're setting the language \n\n\n#{params[:language]}\n\n\n")
          # session[:language] = params[:language]
          session[:language] = request.language
        end
      end
    }
    TranslateResponseCache    
  end
  
  def deactivate
  end
  
end