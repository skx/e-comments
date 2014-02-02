External Comments
=================

This repository contains a simple server used to store comments, and
an associated Javascript file which allows you to include comments
in your static-pages.

This is a self-hosted alternative to using discus.


Comment Server
--------------

The comment server is written using [sinatra](http://www.sinatrarb.com/),
and stores the comments in a [Redis](http://redis.io/) store.


Client-Side Inclusion
---------------------

Including comments in your site is a simple as including the
following in your HTML HEAD section:

    <script src="http://code.jquery.com/jquery-1.10.1.min.js"></script>
    <script src="/js/e-comments.js" type="text/javascript"></script>
    <link rel="stylesheet" type="text/css" href="/css/e-comments.css" media="screen" />
    <script type="text/javascript">
       $( document ).ready(function() {
        discussion( "http://server.name/comments/id" );
    });
    </script>




Steve
--