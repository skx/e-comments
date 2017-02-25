
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
  @@subclasses = { }

  def self.create( type, args )
    c = @@subclasses[type]
    if c
      c.new( args )
    else
      puts "Unknown storage type `#{type}`.  Known mechanisms are:"
      @@subclasses.each do |k,v|
        puts( "\t#{k}" )
      end
      exit(1)
    end
  end

  def self.register_storage name
    @@subclasses[name] = self
  end
end


#
# The SQLite-based backend.
#
class SQLiteBackend < Backend

  #
  # Constructor.
  #
  def initialize( path = "storage.db" )
    @sqlite = SQLite3::Database.open( path )

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

  #
  #  Register our class.
  #
  register_storage "sqlite"
end



#
# The redis-based backend.
#
class RedisBackend < Backend


  #
  # Constructor.
  #
  def initialize( address = "127.0.0.1" )
    @redis = Redis.new( :host => address )
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

  #
  #  Register our class.
  #
  register_storage "redis"
end
