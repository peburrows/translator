module TranslatorTags
  include Radiant::Taggable
  
  tag 'translator' do |tag|
    tag.expand
  end
  
  
  # we're ripping this from Radiant's StandardTags module and molding it to fit our needs
  desc %{
    Works just like the standard Radiant tag @<r:content />@
    
    The translator tag, however, renders the page part that is suffixed with the browser's
    Language-Accept header.
    
    *Usage:*
    <pre><code><r:translator:content [part="part_name"] [inherit="true|false"] [contextual="true|false"] /></code></pre>
    <pre><code><r:translator:content part="body" /></code></pre>
    
    If the Language-Accept header was set to fr-ca (French, Canadian), it would render the "body_fr" content part.
  }
  tag 'translator:content' do |tag|
    page = tag.locals.page
    
    # this is where we need to grab the Accept-Language
    request = tag.globals.page.request
    lang = request.env['HTTP_ACCEPT_LANGUAGE']
    
    # grab the two letter abbreviation -- some browsers pass multiple languages
    m = lang.match(/^([a-zA-Z][a-zA-Z])(.)+$/)
    if m && !request.session[:language]
      lang = m.captures.first.downcase
    else
      # english is set as the default
      lang = request.session[:language] || "en"
    end
    
    logger.error(request.session)
    
    # and now the part's suffix will be determined by the accept-language
    suffix = lang.match(/^en/i) ? "" : "_#{lang}"
    
    base_part_name = tag_part_name(tag)
    part_name = base_part_name + "#{suffix}"

    boolean_attr = proc do |attribute_name, default|
      attribute = (tag.attr[attribute_name] || default).to_s
      raise TagError.new(%{`#{attribute_name}' attribute of `content' tag must be set to either "true" or "false"}) unless attribute =~ /true|false/i
      (attribute.downcase == 'true') ? true : false
    end
    inherit = boolean_attr['inherit', false]
    part_page = page
    if inherit
      while (part_page.part(part_name).nil? and part_page.part(base_part_name).nil? and (not part_page.parent.nil?)) do
        part_page = part_page.parent
      end
    end
    contextual = boolean_attr['contextual', true]
    if inherit and contextual
      if part_page.part(part_name).nil?
        part = part_page.part(base_part_name)
      else
        part = part_page.part(part_name)
      end
      page.render_snippet(part) unless part.nil?
    else
      if part_page.part(part_name).nil?
        part_page.render_part(base_part_name)
      else
        part_page.render_part(part_name)
      end
    end
  end

end