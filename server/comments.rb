#!/usr/bin/ruby
#
# This is a sinatra application for storing/retrieving comments.
#
# It was originally designed to work on the http://tweaked.io/ site
# but there is nothing specific to that site here.
#
# The only dependencies are a Redis server running on localhost, and the
# appropriate Ruby packages to run sinatra
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
#
# Steve
# --


require 'sinatra'
require 'json'


#
#  Attempt to load both "redis" and "sqlite3", it doesn't matter if
# one of them fails so long as one succeeds.
#
begin
  require 'redis'
rescue LoadError
  puts "Failed to load the redis library"
end
begin
  require 'sqlite3'
rescue LoadError
  puts "Failed to load the sqlite3 library"
end



#
#  This is an abstraction layer betweent the Sinatra application
# and the backing-store.
#
#  Here we can talk to either redis or sqlite3.
#
#  The user will specify which one by setting the environmental
# variable "STORAGE" to the value "redis" or "sqlite".
#
class BackEnd
  #
  #  Handle to either Redis or an Sqlite database
  #
  attr_reader :redis, :sqlite

  #
  #  Constructor
  #
  def initialize( method )

    @sqlite = nil
    @redis  = nil

    #
    #  Create Redis handle, if that is the users' choice
    #
    if ( method == "redis" )
      @redis  = Redis.new( :host => "127.0.0.1" );

    elsif ( method == "sqlite" )

      #
      # Create an SQLite database.
      #
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
      end
    else
      raise "Unknown backend: #{method}"
    end
  end


  #
  # Get values from either redis or sqlite
  #
  def get( id )

    if (  @redis )
      return redis.smembers( "comments-#{id}" )
    end

    if ( @sqlite )

      stm = @sqlite.prepare "SELECT content FROM store WHERE id = ?"
      stm.bind_param 1, id

      a = Array.new()
      stm.execute.each do |item|
        a.push( item[0] )
      end
      a
    end
  end

  #
  #  Add content for the given ID from either redis or sqlite
  #
  def add( id, content )

    if ( @redis )
      @redis.sadd( "comments-#{id}",content )
    end

    if ( @sqlite )
      @sqlite.execute( "insert into store (id,content) VALUES( ?, ? )", id, content )
    end
  end

end




#
#  The API.
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
    @storage = BackEnd.new(storage)
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
  # appends a simplified version of the comment to a redis set.
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
  #  Get the comments associated with a given ID, sorted
  # by the date - oldest first.
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

      # Add the values to our array of hashes
      result << { :time => time,
        :ago => time_in_words(time),
        :ip => ip,
        :author => CGI.escapeHTML(author || ""),
        :body => CGI.escapeHTML(body|| "") }
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
