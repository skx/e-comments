External Comments
=================

This is an open source commenting system, allowing you to include
comments on your static website(s) without the privacy concerns of
using an external system such as disqus.

Embedding comments is as simple as including a 5k Javascript file,
(2k when minified) and a CSS file for styling.

Features:

* Multiple backends for storage:
   * Redis
   * SQlite
   * Adding new backends is simple.
* Markdown formatting of comments.
* Anti-spam plugins:
   * Three simple plugins included as a demonstration.
   * The sample plugins block hyperlinks in comment-author names, bodies which reference `viagra`, and any remote IPs which have been locally blacklisted.
* Simplicity
   * The code is small enough to easily understand and extend for your custom needs, but functional as-is.
* Degrades gracefully when Javascript is disabled
   * No white boxes, empty spaces, or error-messages.

Anti-features:

* Comments are flat, not threaded.
* There is no administrative panel to edit/delete comments.
   * This requires manual intervention in the back-end.


This server was originally written for my [server optimization guide](http://tweaked.io/) but since it seemed like a generally-useful piece of code it was moved into its own repository.


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

* The URL of the comment-server you've got running, including a discussion ID.
* An optional hash of parameters, to customize the comments.

For example one page might include comments like so:

        discussion( "http://server.name/comments/home" );

And a different page might include:

        discussion( "http://server.name/comments/about" );

This ensures that both pages show distinct comments, and there is no confusion.



#### Customization

There are three different ways that you can customize the client-side comments:

* Via CSS.
* Via options passed to the `discussion` function.
* By appending `/reverse` to the URL, to show comments most-recent first.
   * For example `discussion( "http://server.name/comments/about/reverse" );`

The comments are retrieved from the comment-server as a JSON-encoded array
of hashes.  These comments are then wrapped inside some `<div class="xx"..>`,
such that they can be styled for display.

The basic formatting that exists by default is contained within
the `/css/e-comments.css` file, and you can update that freely.

> **NOTE**: I welcome the contribution of different styling examples.

The second means of customization is by passing a hash of options
to the `discussions()` method.  Currently the following options are
supported:

|Parameter|Meaning|
|---------|-------|
|`reply-div`|If this value is present then the hardcoded "Add your comment" form is not used.  Instead the content of the specified DIV is displayed instead.|
|`reply-placement`|This should be set to `before` or `after`, and will specify whether the reply-form will be displayed above or below the list of existing comments.|


> **NOTE**: If you wish to use a custom reply form you **must** give the FORM the ID `ecommentsreply`.  (i.e. `<form id="ecommentsreply" ..>`)


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
