module TranslatorTags
  include Radiant::Taggable
  
  desc %{
    All @translator@ tags live inside this one
  }
  tag 'translator' do |tag|
    tag.expand
  end
  
  desc %{
    Works just like the standard Radiant tag @<r:title />@
    
    However, this one looks for a page part named translator_config and spits out the page's title accordingly.
    
    *Usage:*
    <pre><code><r:translator:title /></code></pre>
    
    *Then in a config page part do the following*
    <pre><code>
    translator:
      es:
        title: éste es el título
      de:
        title: dieses ist der titel
    </pre></code>
  }
  tag 'translator:title' do |tag|
    page = tag.locals.page
    title = page.title
    config_content = page.render_part(:config)
    unless config_content.blank?
      lang = language(tag)
      config = YAML::load(config_content)
      config = (config.blank? || config['translator'].blank?) ? {} : config['translator']
      if config[lang]
        config[lang]['title'].blank? ? page.title : config[lang]['title']
      else
        page.title
      end
    else
      page.title
    end
  end
  
  # this is heavily based on Radaint's standard <r:content /> tag, but molded to fit our localization needs
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
    
    suffix = suffixize(language(tag))
    
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
  
protected

  def language(tag)
    # this is where we need to grab the Accept-Language
    request = tag.globals.page.request
    lang = request.env['HTTP_ACCEPT_LANGUAGE']

    # grab the two letter abbreviation -- some browsers pass multiple languages, but we just want the first one (for now)
    # there's quite a bit more we could do with this, like falling back to the other languages that the user-agent requests
    # for now, it's a simple hit or miss on the first in the series
    m = lang.match(/^([a-zA-Z][a-zA-Z])(.)+$/)
    if m && !request.session[:language]
      lang = m.captures.first.downcase
    else
      # english is set as the default
      lang = request.session[:language] || "en"
    end
    
    # send back the two-letter abbreviation, or a blank string if it's english
    lang.match(/^en/i) ? "" : lang
  end

  def suffixize(lang)
    lang.blank? ? "" : "_#{lang}"
  end

end