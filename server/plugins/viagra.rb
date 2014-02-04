#
# Blacklist if the comment mentions viagra.
#
class ViagraPlugin < SpamPlugin

  #
  # Test the content of the message.
  #
  def is_spam?( obj )

    #
    # There should always be a body, but be defensive.
    #
    if ( obj && obj[:body] )

      body = obj[:body]

      if ( body =~ /viagra/i )
        return true
      end
    end

    #
    # Permit the comment.
    #
    false
  end

end

