#
# This is a simple plugin that will inspect the submitted comment
# and reject those that have hyperlinks in their names.
#
class HyperlinkNamePlugin < SpamPlugin

  #
  # Get the name of the commentor, and test it for a hyperlink.
  #
  def is_spam?( obj )

    if ( obj && obj[:author] )

      name = obj[:author]

      if ( name =~ /^https?:\/\// )
        return true
      end
    end

    #
    # Permit the comment.
    #
    false
  end
end
