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
    * [Advanced Usage](#advanced-usage)
    * [Theming](#theming)
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

For storage you get to choose between one of these two alternatives:

    apt-get install libsqlite3-ruby

Or

    apt-get install ruby-redis


### Comment Server Deployment

Deploying the server involves two steps:

* Actually launching the server, via systemd, runit, or similar.
* Configuring your webserver to proxy to it.

To launch the comment server you'll run one of these two commands,
depending on which storage back-end you prefer to use:

     $ ./server/comments.rb --storage=redis  --storage-args=127.0.0.1
     $ ./server/comments.rb --storage=sqlite --storage-args=/tmp/foo.db

The server will bind to `127.0.0.1:9393` by default, so you'll
need to setup a virtual host in nginx/apache which will forward
connections to that instance.

For nginx this would look something like this:

    server {
      listen          80;
      server_name     comments.example.com;
      location / {
        proxy_pass        http://127.0.0.1:9393;
        proxy_redirect    off;
        proxy_set_header  X-Forwarded-For $remote_addr;
      }
    }


## Client-Side Setup

To allow comments upon your static site you must update your page(s) to
include the appropriate javascript libraries, and the CSS.

For basic usage you'll be adding this to the `<head>` of your HTML:

    <script src="https://code.jquery.com/jquery-1.12.4.js"></script>
    <script src="/js/mustache.js" type="text/javascript"></script>
    <script src="/js/e-comments.js" type="text/javascript"></script>

    <script type="text/javascript">
      $( document ).ready(function() {
        discussion( "http://server.name/comments/COMMENT_ID" );
    });
    </script>

At the place you wish your comments to be displayed you'll add:

    <div id="comments"></div>


### Advanced Usage

The example above configured the display of comments with the defaults,
but the `discussion()` method actually accepts two arguments:

* The URL of the comment-server you've got running, including a discussion ID.
* An optional hash of parameters, to customize behaviour.

The discussion will require a unique key, which will be specified as
an URL.  For example your home-page might include this:

        discussion( "http://comments.example.com/comments/home" );

Your about page this:

        discussion( "http://comments.example.com/comments/about" );

This will ensure that each page will have a distinct discussion-thread
upon it.

The second parameter, which is optional, allows things to be customized.
Valid options for this hash include:

* `comments`
    * The ID of the `<div>` in which comments will be inserted.
    * The default will be `comments`, as documented above.
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

If you wished to disable threading, allowing only a flat discussion
hierarchy, you'd use this:

     discussion( "http://comments.example.com/comments/about",
                 { threading: false });

If you wished to allow comments, but stop arbitrary nesting:

     discussion( "http://comments.example.com/comments/about",
                 { threading: true, max_depth: 2 });


### Theming

You _could_ customize the formatting of comments, and the comment-submission
form via CSS, however you might prefer to replace the presentation with
something entirely different.

To allow this we use  [mustache.js](https://github.com/janl/mustache.js) templates for:

* The display of the individual comments.
* The display of the reply-form.

You can hide templates for both of these things inside your static HTML-files
and cause them to be used by specifing their IDs like so:

        discussion( "http://localhost:9393/comments/id",
                    { comment_template: '#comment_template',
                      reply_template: '#reply_form'} );

This would require your HTML-page to contain something like this:

    <script id="comment_template" type="x-tmpl-mustache">
     <div class="comment">
     <div class="link"><a href="#comment_{{ id }}">#{{ id }}</a></div>
     ..
    </script>

> **NOTE**: You can find the default templates which are used inside the  `e-comments.js` file.

Replacing the template entirely allows you to display different data, for example you might wish to show the thread-level of each comment.  This could be achived by adding the following to the comment-template:

     Depth:{{#depth}}{{ uuid }}{{/depth}}

I'm open to pull-requests adding more formatting options, if you have something you think would be useful.  (Similarly any improvements to the presentation of comments by default would be appreciated.)


## Alternative Systems


* [isso](https://github.com/posativ/isso/)
    * Python-based.
    * Seems active, and allows users to edit/delete their comments, which is nice.
* [talkatv](https://github.com/talkatv/talkatv)
    * Python-based.
    * No screenshots, no online demo, seems to be a [defunct project](https://github.com/talkatv/talkatv/issues/45#issuecomment-78016274).
* [Juvia](https://github.com/phusion/juvia)
    * Ruby-on-rails-based.
    * [No longer maintained](https://github.com/phusion/juvia/issues/65).

## Online Demo

There is a live online demo you can view here:

* https://tweaked.io/guide/demo/

### Running Locally

Providing you have the dependencies installed you can run the same
demo locally:

* Launch the comment-server in one terminal.
     * `./server/comments.rb --storage=sqlite --storage-args=/tmp/foo.db`
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
