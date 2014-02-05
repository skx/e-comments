#
# This is a simple module for implementing plugins.
#
module Plugin
  module ClassMethods

    #
    # Create an array for storing our plugins.
    #
    def repository
      @repository ||= []
    end

    #
    # Every time this class is derived from store a new instance of that
    # derived class in our local repository.
    #
    def inherited(klass)
      repository << klass.new
    end
  end

  #
  # This is "somewhat controversial".
  #
  def self.included(klass)
    klass.extend ClassMethods
  end
end



#
# This is the base-class for our anti-spam plugins.
#
class SpamPlugin
  include Plugin

  #
  # If this method returns TRUE the incoming message is silently dropped.
  #
  def is_spam?( obj )
    raise NotImplementedError.new('OH NOES!')
  end

end

#
# Load all our server-plugins.
#
Dir.glob("./server/plugins/**/*.rb").each{|f| require f}
Dir.glob("./plugins/**/*.rb").each{|f| require f}
