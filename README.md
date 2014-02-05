External Comments
=================

This is an open source commenting system, allowing you to include
comments on your static website(s) without the privacy concerns of
using an external system such as disqus.

Embedding comments is as simple as including a 4k Javascript file,
(1k when minified) and a CSS file for styling.

Features:

* Markdown formatting for your visitors.
* Support for anti-spam plugins.
   * Three simple plugins included as a demonstration.
   * The sample plugins block hyperlinks in comment-author names, bodies which reference `viagra`, and any remote IPs which have been locally blacklisted.
* Multiple backends for storage:
   * Redis
   * SQlite
   * Adding new backends is simple.
* Simplicity
   * The code is small enough to easily understand and extend for your custom needs, but functional as-is.
* Degrades gracefully when Javascript is disabled
   * No white boxes, empty spaces, or error-messages.


Comment Server
--------------

The comment server is written using [sinatra](http://www.sinatrarb.com/),
and currently contains two diffent choices for storing the actual comment data:

* A [Redis server](http://redis.io/).
* An SQLite database.

Adding new backends should be straight-forward, and pull-requests are
welcome for MySQL, CouchDB, etc.



#### Comment Server API

The server implements the following two API methods:

* `GET /comments/ID`
   * This retrieves the comments associated with the given ID.
   * The return value is an array of hashes.
   * The hashes have keys such as  `author`, `body` & `ip`.
* `POST /comments/ID`
   * Adds a new comment to the collection for the given ID.
   * The submission should have the fields `author` and `body`.
   * Optionally the submission might contain the field `email`.
       * If an email is stored a Gravitar field will be present in the retrieval, but the actual email address will not be sent back to avoid a privacy leak.


#### Comment Server Dependencies

These dependencies were tested on a Debian GNU/Linux stable machine,
but are a good starting point for other distributions:

    apt-get install ruby ruby-json ruby-sinatra ruby-redcarpet

For storage you get to choose between on of these two alternatives:

    apt-get install libsqlite3-ruby

Or

    apt-get install rubygems
    gem install sinatra


#### Comment Server Deployment

Assuming you have the appropriate library available you should specify
your preferred storage mechanism like so:

     $ STORAGE=redis ./server/comments.rb

Or:

     $ STORAGE=sqlite ./server/comments.rb

When SQLite is chosen the database can be set to an explicit path via the
DB variable:

     $ DB=/tmp/comments.db STORAGE=sqlite ./server/comments.rb

As a shortcut you may prefer:

     $ ./server/comments.rb --redis | --sqlite=/tmp/foo.db

**NOTE** The server will bind to `127.0.0.1:9393` by default, so you
will need to place a suitable proxy in front of it if you wish it to
be available.

**NOTE** You need to expose http://comments.exaimple.com/comments/ to
the outside world if client-browsers are going to connect to add/view comments.


Client-Side Inclusion
---------------------

Including comments to the static-pages on your site is a simple as including the
following in your HTML HEAD section:

    <script src="http://code.jquery.com/jquery-1.10.1.min.js"></script>
    <script src="/js/e-comments.js" type="text/javascript"></script>
    <link rel="stylesheet" type="text/css" href="/css/e-comments.css" media="screen" />
    <script type="text/javascript">
       $( document ).ready(function() {
        discussion( "http://server.name/comments/id" );
    });
    </script>

Then inside your body somewhere place the following:

    <div id="comments"></div>

The `discussion()` method accepts two arguments:

* The URL of the comment-server you've got running, including the ID of the discussion to include.
* An optional hash of options, which is used for customization.

For example one page might include comments like so:

        discussion( "http://server.name/comments/home" );

And a different page might include:

        discussion( "http://server.name/comments/about" );

This ensures that both pages show distinct comments, and there is no confusion.



#### Customization

There are two different ways that you can customize the client-side comments:

* Via CSS.
* Via options passed to the `discussion` function.

The comments which are retrieved from the comment-server are retrieved as
a JSON-encoded array of hashes.  From there the client-side code will wrap
the comments in some `<div class="xx"..>` wrappers, with the expectation
that this will allow them to be styled differently.

The basic formatting that exists by default is contained in
the `/css/e-comments.css` file, and you can update that freely.

The second means of customization is by passing a hash of options
to the `discussions()` method.  Currently the following options are
supported:

|Parameter|Meaning|
|---------|-------|
|`reply-div`|If this value is present then the hardcoded "Add your comment" form is not used.  Instead the content of the specified DIV is displayed instead.|
|`reply-placement`|This should be set to `before` or `after`, and will specify whether the reply-form will be displayed above or below the list of existing comments.|


> **NOTE**: If you wish to use a custom reply form you **must** give the FORM the ID `ecommentsreply`.  (i.e. `<form id="ecommentsreply" ..>`)



Online Demo
-----------

There is a live online demo you can view here:

* http://www.steve.org.uk/Software/e-comments/demo.html

Steve
--
