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
* Support for __threaded discussion__.
   * You can limit the depth of discussions, to a given depth.
   * Or leave the defaults in-place to allow arbitrarily nested replies.
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

### Contents

* [The comment server](#the-comment-server)
    * [API](#comment-server-api)
    * [Dependencies](#comment-server-dependencies)
    * [Deployment](#comment-server-deployment)
* [Client-Side Setup](#client-side-setup)
    * [Customizaton](#client-side-customization)
* [Alternative Solutions](#alternative-systems)
* [Online Demo](#online-demo)
    * [Running Locally](#running-locally)


## The Comment Server

The comment server exports a public API allowing the javascript on your
(static) pages to add comments, and retrieve those comments which already
exist.  It is written in Ruby using the [sinatra](http://www.sinatrarb.com/),
framework.

There are two choices for storing the actual comment data:

* A [Redis server](http://redis.io/).
* An SQLite database.
    * This is preferred.

Adding new backends should be straight-forward, and pull-requests are
welcome for MySQL, CouchDB, etc.


### Comment Server API

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


### Comment Server Dependencies

These dependencies were tested on a Debian GNU/Linux stable machine,
but are a good starting point for other distributions:

    apt-get install ruby ruby-json ruby-sinatra ruby-redcarpet ruby-uuidtools ruby-rack-test

For storage you get to choose between on of these two alternatives:

    apt-get install libsqlite3-ruby

Or

    apt-get install ruby-redis


### Comment Server Deployment

Assuming you have the appropriate library available you should specify
your preferred storage mechanism via the command line options
`--redis` or `--sqlite`:

     $ ./server/comments.rb --redis | --sqlite=/tmp/foo.db

**NOTE** The server will bind to `127.0.0.1:9393` by default, so you
will need to place a suitable proxy in front of it if you wish it to
be available.

**NOTE** You need to expose http://comments.example.com/comments/ to
the outside world if client-browsers are going to connect to add/view comments.


## Client-Side Setup

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
* An optional hash of parameters, to customize behaviour.

For example one page might include comments like so:

        discussion( "http://server.name/comments/home" );

And a different page might include:

       discussion( "http://server.name/comments/about",
                   { threading: false } );


This ensures that both pages show distinct comments, and there is no confusion.

Valid options include:

* `comments`
    * The ID of the `<div>` in which comments will be inserted.
    * The default will be `comments`.
* `max_depth`
    * This should be an integer holding the maximum thread-depth permitted.
    * The default value is `0`, which allows an unlimited thread-depth.
* `threading`
    * A boolean to control whether threading is enabled/disabled.
    * The default value is `true`.
* `comment_template`
    * The ID of a script-div which contains a template for comment-formatting.
* `reply_template`
    * The ID of a script-div which contains a template for the "add comment" form.


## Client-Side Customization

There are two parts of the code which use markup, albeit with CSS too:

* The display of the individual comments.
* The display of the reply-form.

Both of these HTML-snippets are stored as [mustache.js](https://github.com/janl/mustache.js) templates, and can be overridden by passing a suitable argument to the constructor.

For example:

        discussion( "http://localhost:9393/comments/id",
                    { comment_template: '#comment_template',
                      reply_template: '#reply_form'} );

Once you do that you'll need to include the templates in your HTML
page, for example the comment-template:

    <script id="comment_template" type="x-tmpl-mustache">
     <div class="comment">
     <div class="link"><a href="#comment_{{ id }}">#{{ id }}</a></div>
     ..
    </script>

You can copy the defaults from the `e-comments.js` file itself.


## Alternative Systems


* [talkatv](https://github.com/talkatv/talkatv)
    * Python-based.
* [isso](https://github.com/posativ/isso/)
    * Python-based.
* [Juvia](https://github.com/phusion/juvia)
    * Ruby-on-rails-based.


## Online Demo

There is a live online demo you can view here:

* https://tweaked.io/guide/demo/

### Running Locally

Providing you have the dependencies installed you can run the same
demo locally:

* Launch the comment-server in one terminal.
     * `./server/comments.rb --sqlite=/tmp/foo.db`
     * The file `/tmp/foo.db` will be created, and used to store your comments.
* Start a local HTTP server in clients in another:
     * `cd client ; python -m SimpleHTTPServer`
* Open your browser:
     * http://localhost:8000/demo.html
     * Add some comments.

This local demo works because the `demo.html` file is configured to access
comments at `http://localhost:9393/`.  In a real deployment you'd hide
the comment-server behind a reverse proxy and access it via a public
name such as `comments.example.com`.


Steve
--
