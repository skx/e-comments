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
require 'redis'
require 'json'


class CommentStore < Sinatra::Base

  #
  # Listen on 127.0.0.1:9393
  #
  set :bind, "127.0.0.1"
  set :port, 9393

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

    if ( author && body && id )

      ip = request.ip

      #
      #  Trivial stringification.
      #
      content = "#{ip}|#{Time.now}|#{author}|#{body}"

      #
      #  Add to the set.
      #
      @redis = Redis.new( :host => "127.0.0.1" );
      @redis.sadd( "comments-#{id}",content )

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
    @redis = Redis.new( :host => "127.0.0.1" );
    values = @redis.smembers( "comments-#{id}" )


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
        :author => CGI.escapeHTML(author),
        :body => CGI.escapeHTML(body) }
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
