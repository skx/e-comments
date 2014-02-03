
#
#  Attempt to load both "redis" and "sqlite3", it doesn't matter if
# one of them fails so long as the other succeeds!
#
%w( redis sqlite3 ).each do |library|
  begin
    require library
  rescue LoadError
    puts "Failed to load the library: #{library}"
  end
end


#
#  This is an abstraction layer between our Sinatra application
# and the storage of the comments.
#
class Backend

  #
  # Class-Factory
  #
  def self.create type
    case type
    when "sqlite"
      SQLiteBackend.new
    when "redis"
      RedisBackend.new
    else
      raise "Bad backend type: #{type}"
    end
  end


  #
  # Return an array of strings for the given ID.
  #
  def get( id )
    raise "Subclasses must implement this method!"
  end


  #
  # Add a new string (of concatenated comment-data) to the given identifier.
  #
  def set( id, values )
    raise "Subclasses must implement this method!"
  end

end


#
# The SQLite-based backend.
#
class SQLiteBackend < Backend

  #
  # Constructor.
  #
  def initialize
    db = ENV["DB"] || "storage.db"
    @sqlite = SQLite3::Database.open db

    begin
      @sqlite.execute <<SQL
  CREATE TABLE store (
   idx INTEGER PRIMARY KEY,
   id  VARCHAR(255),
   content String
  );
SQL
    rescue => e
      #
      #  Error here is expected if the table exists.
      #  Other errors are silently masked which is perhaps a mistake.
      #
    end
  end


  #
  # Return an array of strings for the given ID.
  #
  def get(id)
    stm = @sqlite.prepare( "SELECT content FROM store WHERE id = ?" )
    stm.bind_param 1, id

    a = Array.new()
    stm.execute.each do |item|
      a.push( item[0] )
    end
    a
  end


  #
  # Add a new string (of concatenated comment-data) to the given identifier.
  #
  def add( id, content )
    @sqlite.execute( "INSERT INTO store (id,content) VALUES(?,?)", id, content )
  end

end



#
# The redis-based backend.
#
class RedisBackend < Backend


  #
  # Constructor.
  #
  def initialize
    rehost = ENV["REDIS"] || "127.0.0.1"
    @redis = Redis.new( :host => rehost )
  end


  #
  # Return an array of strings for the given ID.
  #
  def get( id )
    @redis.smembers( "comments-#{id}" )
  end


  #
  # Add a new string (of concatenated comment-data) to the given identifier.
  #
  def add( id, content )
    @redis.sadd( "comments-#{id}",content )
  end

end





