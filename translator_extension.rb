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
  end
  
  def activate
    Page.send :include, TranslatorTags
    SiteController.class_eval{session :disabled => false}
    TranslateResponseCache    
  end
  
  def deactivate
  end
  
end