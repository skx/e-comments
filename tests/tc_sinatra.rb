#!/usr/bin/env ruby

require_relative "../server/comments.rb"

require 'test/unit'
require 'rack/test'



#
#  These test-cases make simulated HTTP-requests against our application.
#
class HTTPSiteTests < Test::Unit::TestCase

  include Rack::Test::Methods

  def app
    CommentStore
  end


  #
  # Unknown end-points should return a redirect.
  #
  def test_missing_endpoints

    #
    # Unknown end-points return a 302-redirect
    #
    %w( /  /help /version /api /foo ).each do |endpoint|

      get endpoint
      assert_equal(last_response.status, 302,
                   "We got a redirect for a missing end-point" )
    end
  end

  #
  # Test getting comments for an ID returns JSON.
  #
  def test_get
    get "/comments/foo"
    assert_equal( 200, last_response.status, "We got a 200 response" )

    assert( last_response.body =~ /^comments\(\[/, "The result looked like JSON" )
  end


  #
  #  Test various error-handlers for setting comments.
  #
  def test_set

    #
    #  Missing body
    #
    data = '{"author":"Steve","id":"foo"}'
    post '/comments/test', JSON.parse(data)

    assert_equal( 500, last_response.status, "A missing body was rejected" )
    assert( last_response.body =~ /Missing.*body/i,
            "A missing body was identified");

    #
    #  Missing author
    #
    data = '{"body":"Steve left this","id":"foo"}'
    post '/comments/test', JSON.parse(data)

    assert_equal( 500, last_response.status, "A missing author was rejected" )
    assert( last_response.body =~ /Missing.*author/i,
            "A missing author was identified");

    #
    #  Spam is rejected
    #
    data = '{"body":"Viagra is good","author":"Bobby"}'
    post '/comments/test', JSON.parse(data)

    assert_equal( 500, last_response.status, "SPAM was rejected" )
    assert( last_response.body =~ /spam/i,
            "SPAM was identified");

    #
    #  Not going to test adding because that's going to touch the
    # production use.
    #
  end


end
