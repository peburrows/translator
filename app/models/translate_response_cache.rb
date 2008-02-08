class TranslateResponseCache

  ResponseCache.class_eval{
    private
    def page_cache_path(path)
      logger.error("\n\n-------------------\n i was called? \n---------------------\n\n")
      
      # set up '/' as '/index' so we don't have to worry about having cache files in the wrong directory
      path = page_cache_file(path)
      path = translator_path(path)
      root_dir = File.expand_path(page_cache_directory)
      cache_path = File.expand_path(File.join(root_dir,path), root_dir)
      if(cache_path.index(root_dir) == 0)
        logger.error(cache_path)
        cache_path
      end
    end
    
    # def page_cache_file(path)
    #   name = ((path.empty? || path == "/") ? "/index" : URI.unescape(path))
    # end
    
    def translator_path(path)
      path = path + '_en' unless path.match(/[\.css|\.js]$/)
      path
    end
  }
  
end