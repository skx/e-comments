
#
# Locally blacklisted commentors
#
class IPBlacklistPlugin < SpamPlugin

  #
  # Test the IP of the comment submitter against a local blacklist.
  #
  def is_spam?( obj )

    #
    # There should always be an IP present, but let us be cautious.
    #
    if ( obj && obj[:ip] )

      #
      #  If the IP exists as a file then we'll reject the comment.
      #
      ip = obj[:ip]

      if ( File.exists?( "/etc/blacklist.d/#{ip}" ) )
        return true
      end
    end

    #
    # Permit the comment.
    #
    false
  end

end

