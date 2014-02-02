#!/usr/bin/ruby
#
# This is a Sinatra application for storing/retrieving comments.
#
# It was originally designed to work on the http://tweaked.io/ site
# but there is nothing specific to that site here.
#
# The only dependencies are either the Redis client libraries, and a
# Redis server running on localhost, or the SQLite libraries and a writeable
# path somewhere.
#
#
#
#
# Storing Comments
# ----------------
#   POST "body" + "author" to /comments/ID
#
#
# Retrieving Comments
# -------------------
#   GET /comments/ID -> JSON array of hashes.
#
#
# IDs
# ---
#   Arbitrary IDs are supported, so long as they are unique for each page,
#   and don't contain slashes.  Ahem.
#
#
# Deployment
# ----------
#   Run this on a host such as comments.example.com, behind nginx, or similar.
#
#   NOTE: By default the server will bind to 127.0.0.1:9393
#
#   Specify the backend to use via the environmental variable STORAGE
#
#     STORAGE=redis ./server/comments.rb
#
#    or
#
#     DB=/tmp/comments.db STORAGE=sqlite ./server/comments.rb
#
#
# Steve
# --


require 'sinatra/base'
require 'json'


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
#  This is an abstraction layer between the Sinatra application
# and the storage the user has chosen.
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

  def get( id )
    raise "Subclasses must implement this method"
  end

  def set( id, values )
    raise "Subclasses must implement this method"
  end

end


#
# An SQLite backend.
#
# This stores comments in a simple SQLite database, on-disk.
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
      #
      #  Other errors are silently masked which is perhaps a shame.
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
  #  Add a new string (of concatenated comment-data) to the given identifier.
  #
  def add( id, content )
    @sqlite.execute( "INSERT INTO store (id,content) VALUES(?,?)",
                     id, content )
  end

end



#
# A redis-backend.
#
# This stores comments in a redis instance running on the localhost.
#
class RedisBackend < Backend


  #
  # Constructor.
  #
  def initialize
    @redis  = Redis.new( :host => "127.0.0.1" );
  end


  #
  # Return an array of strings for the given ID.
  #
  def get( id )
    @redis.smembers( "comments-#{id}" )
  end


  #
  #  Add a new string (of concatenated comment-data) to the given identifier.
  #
  def add( id, content )
    @redis.sadd( "comments-#{id}",content )
  end

end







#
#  The actual Sinatra-based API.
#
class CommentStore < Sinatra::Base

  #
  # Backend Storage
  #
  attr_reader :storage

  #
  # Listen on 127.0.0.1:9393
  #
  set :bind, "127.0.0.1"
  set :port, 9393


  #
  # Create the back-end storage object.
  #
  def initialize
    super
    storage = ENV["STORAGE"] || "redis"
    @storage = Backend.create(storage)
  end


  #
  # Simple method to work out how old a comment-was.
  #
  def time_in_words(date)
    date = Date.parse(date, true) unless /Date.*/ =~ date.class.to_s
    days = (date - Date.today).to_i

    return 'today'     if days >= 0 and days < 1
    return 'tomorrow'  if days >= 1 and days < 2
    return 'yesterday' if days >= -1 and days < 0

    return "in #{days} days"      if days.abs < 60 and days > 0
    return "#{days.abs} days ago" if days.abs < 60 and days < 0

    return date.strftime('%A, %B %e') if days.abs < 182
    return date.strftime('%A, %B %e, %Y')
  end


  #
  # Posting a hash of author + body, with a given ID will
  # append a simplified version of the comment to the storage-backend.
  #
  post '/comments/:id' do
    author = params[:author]
    body   = params[:body]
    id     = params[:id]

    if ( author && ( author.length > 0 ) &&
         body &&  ( body.length > 0 ) &&
        id )

      ip = request.ip

      #
      #  Trivial stringification.
      #
      content = "#{ip}|#{Time.now}|#{author}|#{body}"

      #
      #  Add to the set.
      #
      @storage.add( id, content )

      #
      #  All done
      #
      status 204
    end

    halt 500, "Missing field(s)"
  end

  #
  #  Get the comments associated with a given ID, sorted by the date
  # (oldest first).
  #
  get '/comments/:id' do
    id = params[:id]

    result = Array.new()

    #
    #  Get the members of the set.
    #
    values = @storage.get( id )

    i = 1

    #
    # For each comment add to our array a hash of the comment-data.
    #
    values.each do |str|

      # tokenize.
      ip,time,author,body = str.split("|")

      author = CGI.escapeHTML(author || "")
      body   = CGI.escapeHTML(body   || "")

      body = body.gsub( /\n\n/, "<p>" )
      body = body.gsub( /\r\n\r\n/, "<p>" )

      # Add the values to our array of hashes
      result << { :time => time,
        :ago => time_in_words(time),
        :ip => ip,
        :author => author,
        :body => body }
      i += 1
    end

    # sort to show most recent last.
    json = result.sort_by {|vn| vn[:time]}.to_json()

    # now return a JSONP-friendly result.
    "comments(#{json})";
  end

  #
  # If the user hits an end-point we don't recognize then
  # redirect
  #
  not_found do
    site = ENV["SITE"] || 'http://tweaked.io/'
    redirect site
  end

end



#
# Launch the server
#
if __FILE__ == $0
  CommentStore.run!
end
