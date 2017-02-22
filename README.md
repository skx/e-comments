External Comments
=================

This is an open source commenting system, allowing you to include
comments on your static website(s) without the privacy concerns of
using an external system such as disqus.

Embedding comments is as simple as including a couple of small javascript
files, along with a CSS file for styling.

Features:

* Multiple backends for storage:
   * Redis
   * SQlite
   * Adding new backends is simple.
* Markdown formatting of comments.
* Support for threaded discussion.
* Anti-spam plugins:
   * Three simple plugins included as a demonstration.
   * The sample plugins block hyperlinks in comment-author names, bodies which reference `viagra`, and any remote IPs which have been locally blacklisted.
* Simplicity
   * The code is small enough to easily understand and extend for your custom needs, but functional as-is.
* Degrades gracefully when Javascript is disabled
   * No white boxes, empty spaces, or error-messages.

Anti-features:

* There is no administrative panel to edit/delete comments.
   * This requires manual intervention in the back-end.
* Commenters do not get their details remembered.
   * Nor can they receive emails on replies to their comments.

Run-time (client-side) dependencies:

* jQuery
* mustache.js
    * Included in this repository.

This server was originally written for my [server optimization guide](https://tweaked.io/) but since it seemed like a generally-useful piece of code it was moved into its own repository.


Comment Server
--------------

The comment server is written using [sinatra](http://www.sinatrarb.com/),
and currently contains two diffent choices for storing the actual comment data:

* A [Redis server](http://redis.io/).
* An SQLite database.

Adding new backends should be straight-forward, and pull-requests are
welcome for MySQL, CouchDB, etc.

SQLite is the preferred form for storage, but Redis is a reasonable
choice too.



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
   * Optionally the submission might contain a `parent` field.
       * This is used to support nested comments.
       * There are no limits on the number of nested comments.


#### Comment Server Dependencies

These dependencies were tested on a Debian GNU/Linux stable machine,
but are a good starting point for other distributions:

    apt-get install ruby ruby-json ruby-sinatra ruby-redcarpet ruby-uuidtools

For storage you get to choose between on of these two alternatives:

    apt-get install libsqlite3-ruby

Or

    apt-get install ruby-redis


#### Comment Server Deployment

Assuming you have the appropriate library available you should specify
your preferred storage mechanism via the command line options
`--redis` or `--sqlite`:

     $ ./server/comments.rb --redis | --sqlite=/tmp/foo.db

**NOTE** The server will bind to `127.0.0.1:9393` by default, so you
will need to place a suitable proxy in front of it if you wish it to
be available.

**NOTE** You need to expose http://comments.example.com/comments/ to
the outside world if client-browsers are going to connect to add/view comments.


Client-Side Inclusion
---------------------

Permitting comments on your sites static-pages is a simple as including the
following in your HTML HEAD section:

    <script src="https://code.jquery.com/jquery-1.12.4.js"></script>
    <script src="/js/mustache.js" type="text/javascript"></script>
    <script src="/js/e-comments.js" type="text/javascript"></script>

    <script type="text/javascript">
      $( document ).ready(function() {
        discussion( "http://server.name/comments/id" );
    });
    </script>

Then inside your body somewhere place the following:

    <div id="comments"></div>

The `discussion()` method accepts two arguments:

* The URL of the comment-server you've got running, including a discussion ID.
* An optional hash of parameters, to customize the comments.

For example one page might include comments like so:

        discussion( "http://server.name/comments/home" );

And a different page might include:

        discussion( "http://server.name/comments/about" );

This ensures that both pages show distinct comments, and there is no confusion.



#### Customization

In the past it used to be possible to (easily) customize the display
of the comments.  Currently the display _is_ templated, but that is
handled via an included pair of [mustache.js](https://github.com/janl/mustache.js) templates, and requires tweaking the javascript.

It is hoped in the future this will not be required, although you
should be safe to fork and modify the CSS file at least.


Alternative Systems
-------------------

* [talkatv](https://github.com/talkatv/talkatv)
    * Python-based.
* [isso](https://github.com/posativ/isso/)
    * Python-based.
* [Juvia](https://github.com/phusion/juvia)
    * Ruby-on-rails-based.


Online Demo
-----------

There is a live online demo you can view here:

* https://tweaked.io/guide/demo/

Steve
--
