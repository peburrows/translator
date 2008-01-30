require File.dirname(__FILE__) + '/../test_helper'

class TranslatorExtensionTest < Test::Unit::TestCase
  
  # Replace this with your real tests.
  def test_this_extension
    flunk
  end
  
  def test_initialization
    assert_equal File.join(File.expand_path(RAILS_ROOT), 'vendor', 'extensions', 'translator'), TranslatorExtension.root
    assert_equal 'Translator', TranslatorExtension.extension_name
  end
  
end
