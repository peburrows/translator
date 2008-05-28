class TranslateResponseCache

  [SiteController, Admin::AbstractModelController, Admin::PageController].each do |klass|
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
    # for unusual default mappings, i.e. ones that do not match the typical 'ab' => 'ab-AB' pattern
    # examples: en-UK, en-US, es-MX
    @@mappings = {
      'en' => 'en-US'
    }
    cattr_accessor :mappings

    # when the language is requested, we'll standardize how we'd like it returned
    # currently, we're defaulting to the four letter variety. However, the normal
    # <r:translator:content /> and <r:translator:title /> tags chop off the end and only
    # use the first two letters of the requested language
    def proper_language(two_letter)
      if two_letter.length == 2
        if @@mappings[two_letter]
          @@mappings[two_letter]
        else
          two_letter.downcase + '-' + two_letter.upcase
        end
      else
        if m = two_letter.match(/^[a-zA-Z]{2}\-([a-zA-Z]{2})?/)
          splitter = m[0].split('-')
          splitter[0].downcase + '-' + splitter[1].upcase
        else
          # otherwise, send back the default
          TranslatorExtension.defaults[:language]
        end
      end
    end

    # return the requested language of the current request
    def language
      return proper_language(self.parameters[:language]) if self.parameters[:language]
      return session_lang = proper_language(self.session[:language]) if self.session[:language]
      
      lang = self.env['HTTP_ACCEPT_LANGUAGE'] || ''
      m = lang.match(/^[a-zA-Z]{2}(\-[a-zA-Z]{2})?/)

      return TranslatorExtension.defaults[:language] unless m
      match = m[0]
      return proper_language(match)
    end

    # turn the requested language into a proper suffix for the translator extension tags
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
      
      def page_cache_file(path)
        name = ((path.empty? || path == "/") ? "/index" : URI.unescape(path))
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