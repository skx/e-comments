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


require 'digest/md5'
require 'getoptlong'
require 'json'
require 'redcarpet'
require 'sinatra/base'
require 'time'


#
# Our backends
#
require './server/backends.rb'

#
# Our anti-spam plugins
#
require './server/plugins.rb'


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
  # Create the backend storage object.
  #
  def initialize
    super
    @storage = Backend.create(ENV["STORAGE"] || "redis")
  end

  #
  # Format the given number of seconds into something more friendly.
  #
  def seconds_to_ago( a )
    case a
    when 0 then
      'just now'
    when 1 then
      'a second ago'
    when 2..59 then
      a.to_s+' seconds ago'
    when 60..119 then
      'a minute ago' #120 = 2 minutes
    when 120..3540 then
      (a/60).to_i.to_s+' minutes ago'
    when 3541..7100 then
      'an hour ago' # 3600 = 1 hour
    when 7101..82800 then
      ((a+99)/3600).to_i.to_s+' hours ago'
    when 82801..172000 then
      'a day ago' # 86400 = 1 day
    when 172001..518400 then
      ((a+800)/(60*60*24)).to_i.to_s+' days ago'
    when 518400..1036800 then
      'a week ago'
    else
      ((a+180000)/(60*60*24*7)).to_i.to_s+' weeks ago'
    end
  end


  #
  # Given a date-string such as "2014-02-03 17:22:13 +0000" work out
  # how long ago that was.
  #
  def time_ago( str )
    # convert the given date to seconds-since-epoch
    past = Time.parse(str).to_i

    # convert the current date to seconds-since-epoch
    now = Time.now.to_i

    # Calculate the time-different in seconds.
    seconds = now - past

    # format that
    seconds_to_ago( seconds )
  end


  #
  # Posting a hash of author + body, with a given ID will
  # append a simplified version of the comment to the storage-backend.
  #
  post '/comments/:id' do

    author = params[:author]
    body   = params[:body]
    id     = params[:id]

    #
    # Explicitly alert on which parameters were missing.
    #
    if ( !body || ( !body.length ) )
      halt 500, "Missing 'body'"
    end
    if ( !author || ( !author.length ) )
      halt 500, "Missing 'author'"
    end
    if ( !id || (!id.length ) )
      halt 500, "Missing 'ID'"
    end

    #
    #  Test for spam, via our plugins
    #
    obj = { :author => author, :body => body,
      :ip => request.ip, :site => request.host,
      :time => Time.now }

    #
    #  TODO: params.each ...
    #
    obj[:email] = params[:email] if ( params[:email] )

    #
    # Look for spam.
    #
    SpamPlugin.repository.each do |plugin|
      if plugin.is_spam? obj
        halt 500, "Dropping comment as spam #{plugin.class} - #{obj.to_json}"
      end
    end

    #
    #  Add to the set.
    #
    @storage.add( id, obj.to_json )

    #
    #  All done
    #
    status 204
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

    #
    # Markdown renderer options.
    #
    options = {
      filter_html: true,
      safe_links_only: true,
      hard_wrap: true,
      link_attributes: { rel: "nofollow" },
    }

    #
    # Markdown extensions.
    #
    extensions = {
      autolink: true,
      no_intra_emphasis: true
    }

    renderer = Redcarpet::Render::HTML.new(options)
    markdown = Redcarpet::Markdown.new(renderer, extensions)

    i = 1

    #
    # For each comment add to our array a hash of the comment-data.
    #
    values.each do |str|

      #
      # Convert the stored JSON comment to an object, a hash.
      #
      obj = JSON.parse str

      #
      # Note the options to the Markdown constructor
      # protect us against XSS.
      #
      obj[:body] = markdown.render( obj['body'] )

      #
      # Add 'rel="nofollow"' to all links.  The markdown arguments
      # should do that, but they do not.
      #
      obj['body'].gsub!( /href=/, "rel=\"nofollow\" href=" )

      #
      # CGI-escape author
      #
      obj['author'] = CGI.escapeHTML( obj['author'] || "")

      #
      # If we have a stored email address then create a gravitar
      #
      if ( obj['email'] )
        email  = obj['email'].downcase

        # create the md5 hash
        hash = Digest::MD5.hexdigest(email)

        # set the gravitar URL
        obj['gravitar'] = "http://www.gravatar.com/avatar/#{hash}"

        # delete the email for privacy reasons
        obj.delete( "email" )
      end


      #
      #  Add in missing fields.
      #
      obj['ago'] = time_ago(obj['time'] )
      obj['id' ] = i

      # Add the values to our array of hashes
      result << obj

      i += 1
    end

    # sort to show most recent last.
    json = result.sort_by {|vn| vn['time']}.to_json()

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

  opts = GetoptLong.new(
                        [ '--redis',  '-r', GetoptLong::NO_ARGUMENT ],
                        [ '--sqlite', '-s', GetoptLong::REQUIRED_ARGUMENT ]
                        )

  begin
    opts.each do |opt,arg|
      case opt
      when '--redis'
        ENV["STORAGE"]= "redis"
      when '--sqlite'
        ENV["STORAGE"]= "sqlite"
        ENV["DB"] = arg
      end
    end
  rescue
  end

  CommentStore.run!
end
