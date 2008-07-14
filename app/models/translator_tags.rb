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
    
    However, this one looks for a page part named config and spits out the page's title accordingly.
    
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
    request = tag.globals.page.request
    page = tag.locals.page
    title = page.title
    config_content = page.render_part(:config)
    unless config_content.blank?
      lang = request.language.split('-').first
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
    req = tag.globals.page.request
    page = tag.locals.page
    
    unless req.language == TranslatorExtension.defaults[:language]
      suffix = req.suffixize(req.language.split('-').first)
    else
      suffix = ""
    end
    
    base_part_name = tag_part_name(tag)
    # part_name = base_part_name + "#{suffix}"

    render_translated_page_part(tag, page, req, base_part_name, suffix)
  end
  
  tag 'translator:four' do |tag|
    tag.expand
  end
  
  tag 'translator:four:content' do |tag|
    # here's where we'll render the content for the page
    req = tag.globals.page.request
    page = tag.locals.page
    
    unless req.language == TranslatorExtension.defaults[:language]
      suffix = req.suffixize(req.language)
    else
      suffix = ""
    end
    
    base_part_name = tag_part_name(tag)
    render_translated_page_part(tag, page, req, base_part_name, suffix)
  end
  
  tag 'translator:four:title' do |tag|
    gimme_the_translated_title(tag)
  end
  
protected

  def gimme_the_translated_title(tag)
    # need to edit to work with the two-letter country codes
    request = tag.globals.page.request
    page = tag.locals.page
    title = page.title
    config_content = page.render_part(:config)
    unless config_content.blank?
      lang = request.language
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

  def render_translated_page_part(tag, page, req, base_part_name, suffix)
    part_name = base_part_name + suffix
    
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