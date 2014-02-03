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


require 'getoptlong'
require 'json'
require 'redcarpet'
require 'sinatra/base'

require './server/backends.rb'


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

    #
    # Markdown object.
    #
    options = {
      filter_html: true,
      safe_links_only: true,
      hard_wrap: true,
      link_attributes: { rel: "nofollow" },
    }
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

      # tokenize.
      ip,time,author,body = str.split("|")

      author = CGI.escapeHTML(author || "")

      #
      # Note the options to the Markdown constructor
      # protect us against XSS.
      #
      body = markdown.render( body )


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
