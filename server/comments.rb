#!/usr/bin/env ruby
#
# This is a Sinatra application for storing/retrieving comments.
#
# It was originally designed to work on the https://tweaked.io/ site
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
require 'uuidtools'


#
# Our modules
#
require_relative './sinatra_helpers.rb'
require_relative './backends.rb'
require_relative './plugins.rb'


#
#  The actual Sinatra-based API.
#
class CommentStore < Sinatra::Base

  #
  # Our date/time-formatting helpers.
  #
  include Helpers;

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
  end


  #
  # Posting a hash of author + body, with a given ID will
  # append a simplified version of the comment to the storage-backend.
  #
  post '/comments/:id/?' do
    response.headers['Access-Control-Allow-Origin'] = '*'

    author = params[:author]
    body   = params[:body]
    id     = params[:id]

    #
    # Explicitly alert on which parameters were missing.
    #
    if ( body.nil? || body.empty? )
      halt 500, "Missing 'body'"
    end
    if ( author.nil? || author.empty? )
      halt 500, "Missing 'author'"
    end
    if ( id.nil? || id.empty? )
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
    #  Add the email and parent, if they were supplied.
    #
    obj[:email]  = params[:email] if ( params[:email] )
    obj[:parent] = params[:parent] if ( params[:parent] )

    #
    # Look for spam.
    #
    SpamPlugin.repository.each do |plugin|
      if plugin.is_spam? obj

        #
        # Show this rejection to the console, unless running
        # under the test-suite.
        #
        if ( ENV["TESTSUITE"] != "true" )
          puts "comment marked as spam by the plugin #{plugin.class} - #{obj.to_json}"
        end

        halt 500, "The server marked this comment as likely to be SPAM."
      end
    end

    #
    #  Ensure that each submission has a UUID
    #
    obj[:uuid] = UUIDTools::UUID.random_create

    #
    #  Add to the set.
    #
    $storage.add( id, obj.to_json )

    #
    #  All done
    #
    status 204
  end


  #
  #  Get the comments associated with a given ID, sorted by the date
  # (oldest first).
  #
  get '/comments/:id/?:sort?' do
    response.headers['Access-Control-Allow-Origin'] = '*'

    id = params[:id]

    result = Array.new()

    #
    #  Get the members of the set.
    #
    values = $storage.get( id )

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
      # If there are errors skip that entry.
      #
      # Even though our own script serialized the comment-data
      # I've rarely seen a couple of errors.
      #
      begin
        obj = JSON.parse str
      rescue => ex
        next
      end

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
        obj['gravitar'] = "//www.gravatar.com/avatar/#{hash}"

        # delete the email for privacy reasons
        obj.delete( "email" )
      end

      #
      # Don't leak the submitters IP address.
      #
      obj.delete( 'ip' ) if ( obj['ip'] )

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
    json = result.sort_by {|vn| vn['time']}

    # Unless the user wants the reverse.
    json = json.reverse if ( params[:sort] && params[:sort] == "reverse" )

    # Improve security in our response
    response.headers['Content-Security-Policy'] = "default-src https:; script-src https: 'unsafe-inline'; style-src https: 'unsafe-inline'";

    # now return a JSONP-friendly result, with a sane content-type
    content_type 'application/javascript'
    "comments(#{json.to_json()})";
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
# Storage system
#
$storage = nil


#
# Launch the server
#
if __FILE__ == $0

  storage_type = nil
  storage_args = nil

  opts = GetoptLong.new(
                        [ '--storage',       '-s', GetoptLong::REQUIRED_ARGUMENT ],
                        [ '--storage-args',  '-a', GetoptLong::REQUIRED_ARGUMENT ]
                        )

  begin
    opts.each do |opt,arg|
      case opt
      when '--storage'
        storage_type = arg
      when '--storage-args'
        storage_args = arg
      end
    end
  rescue
  end

  $storage = Backend.create( storage_type, storage_args )

  if ( $storage.nil? )
    puts "You must specify a storage mechanism"
    exit(1)
  end

  CommentStore.run!
end
