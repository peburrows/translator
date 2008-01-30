# Uncomment this if you reference any of your controllers in activate
require_dependency 'application'

class TranslatorExtension < Radiant::Extension
  version "0.1"
  description "Allows you to render your pages in different languages based upon the browser's Accept-Language."
  url "http://philburrows.com"
  
  define_routes do |map|
    map.connect 'language/set/:lang', :controller => 'language', :action => 'set_lang'
  end
  
  def activate
    Page.send :include, TranslatorTags
    SiteController.class_eval{session :disabled => false}
  end
  
  def deactivate
    # don't really need anything here
  end
  
end