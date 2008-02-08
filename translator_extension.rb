# Uncomment this if you reference any of your controllers in activate
require_dependency 'application'

class TranslatorExtension < Radiant::Extension
  version "0.2"
  description "Allows you to render your pages in different languages based upon the browser's Accept-Language."
  url "http://dev.philburrows.com/svn/radiant-extensions/translator/trunk"
  
  # still plenty of work that needs to be done on this
  @@defaults = {
    :lang => 'en'
  }
  cattr_accessor :defaults
  
  define_routes do |map|
    map.connect 'language/set/:lang', :controller => 'language', :action => 'set_lang'
    map.connect ':lang/*url',
                :controller => 'site',
                :action => 'show_page',
                :requirements => {
                  :lang => /[a-zA-Z]{2}/
                }
  end
  
  def activate
    Page.send :include, TranslatorTags
    SiteController.class_eval{
      session :disabled => false
      before_filter :set_up_lang
    private
      def set_up_lang
        logger.error("we're setting the language \n\n\n#{params[:lang]}\n\n\n")
        if params[:lang]
          session[:language] = params[:lang]
        end
      end
    }
    TranslateResponseCache    
  end
  
  def deactivate
  end
  
end