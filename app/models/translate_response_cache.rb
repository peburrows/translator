class TranslateResponseCache

  [SiteController, Admin::AbstractModelController].each do |klass|
    klass.class_eval {
      # yes, i know this is really bad, but we need it. otherwise, we'll have to reinvent the wheel
      around_filter :do_something_bad

      protected
      def do_something_bad
        klasses = [ResponseCache]
        methods = ["session", "cookies", "params", "request"]
  
        methods.each do |need|
          please = instance_variable_get(:"@_#{need}") 
  
          klasses.each do |klass|
            klass.send(:define_method, "kk_#{need}", proc { please })
          end
        end
      
        yield
  
        methods.each do |need|      
          klasses.each do |klass|
            klass.send :remove_method, "kk_#{need}"
          end
        end     
      end
    }
  end

  ActionController::AbstractRequest.class_eval {   
    def language
      # this is where we need to grab the Accept-Language
      lang = self.env['HTTP_ACCEPT_LANGUAGE']

      # grab the two letter abbreviation -- some browsers pass multiple languages, but we just want the first one (for now)
      # there's quite a bit more we could do with this, like falling back to the other languages that the user-agent requests
      # for now, it's a simple hit or miss on the first in the series
      m = lang.match(/^([a-zA-Z][a-zA-Z])(.)+$/)
      if m && !self.session[:language]
        lang = m.captures.first.downcase
      else
        lang = self.session[:language] || TranslatorExtension.defaults[:lang]
      end
      # send back the two-letter abbreviation, or a blank string if it's english
      lang.match(Regexp.new("^#{TranslatorExtension.defaults[:lang]}")) ? "" : lang
    end

    def suffixize(lang)
      lang.blank? ? "" : "_#{lang}"
    end
  }
  
  ResponseCache.class_eval {
    # in here, we're just adding a two-letter language suffix to cached pages to make sure that the wrong
    # language doesn't get served up because it has been cached inappropriately. we could change this to
    # cache in a separate directory (i.e. en/), but for now, we're just adding the extension
    private
      def translator_path(path)
        req = kk_request
        path = path + req.suffixize(req.language) unless path.match(/[\.css|\.js]$/)
        path
      end

      def page_cache_path(path)
        # set up '/' as '/index' so we don't have to worry about having cache files in the wrong directory
        # this is an error in the radiant caching
        path = page_cache_file(path)
        path = translator_path(path)
        root_dir = File.expand_path(page_cache_directory)
        cache_path = File.expand_path(File.join(root_dir,path), root_dir)
        if(cache_path.index(root_dir) == 0)
          logger.error(cache_path)
          cache_path
        end
      end
      
      # Reads a cached response from disk and updates a response object.
      def read_response(path, response, request)
        file_path = page_cache_path(path)
        if metadata = read_metadata(path)
          response.headers.merge!(metadata['headers'] || {})
          # if client_has_cache?(metadata, request)
          #   # we need to see if this is really what we want to do. it causes issues with localization
          #   # since I'm being "smart" and sending the same url. ugh. I might be too "smart" for my
          #   # own good on this one
          #   response.headers.merge!('Status' => '200 OK')
          if use_x_sendfile
            response.headers.merge!('X-Sendfile' => "#{file_path}.data")
          else
            response.body = File.open("#{file_path}.data", "rb") {|f| f.read}
          end
        end
        response
      end
  }
end