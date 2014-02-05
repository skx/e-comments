#!/usr/bin/env ruby

require_relative "../server/plugins"

require "test/unit"


#
# Simple tests of our plugin system
#
class TestPlugins < Test::Unit::TestCase

  #
  #  Test that some plugins were loaded.
  #
  #  We don't care about their types, or their count, just so long as
  # there was more than one.
  #
  def test_plugins_loaded
    assert( SpamPlugin.repository, "Plugin repository is defined." )
    assert( SpamPlugin.repository.kind_of?(Array), "The repository is an array." )
    assert( !SpamPlugin.repository.empty?, "The plugin repository is not empty." )

    #
    #  Test each plugin is an instance of the base-class.
    #
    SpamPlugin.repository.each do |plugin|
      assert_equal( plugin.kind_of?(SpamPlugin), true, "The plugin is of the correct type" )
    end
  end

  #
  # Test that comments with hyperlinks in their names are rejected
  #
  def test_hyperlinked_names

    %w( http://example.com/ https://example.com ).each do |name|

      comment  = { :author => name,  :body => "This is a comment body" }

      #
      # Is the comment SPAM?
      #
      spam = false

      #
      #  Test all the plugins
      #
      SpamPlugin.repository.each do |plugin|
        spam = true if ( plugin.is_spam? comment )
      end

      assert( spam, "A hyperlink was cause for a comment to be SPAM" )
    end
  end


  #
  # Test that bodies which reference `viagra` are SPAM.
  #
  def test_viagra_body

    #
    # Body-texts to test, and whether the result is SPAM
    #
    h  = {
      "This is OK" => false,
      "Viagra is bad" => true,
      "This is viagra" => true,
      "This is viagra in the body" => true }

    h.each do |body,is_spam|
      comment  = { :author => "Steve",  :body => body }

      #
      # Is the comment SPAM?
      #
      spam = false

      #
      # Call all the plugins
      #
      SpamPlugin.repository.each do |plugin|
        spam = true if ( plugin.is_spam? comment )
      end

      assert_equal( spam, is_spam, "The comment was correctly judged." )
    end
  end

end
