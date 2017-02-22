//
//  e-comments.js - Inline comments via 100% Javascript/jQuery.
//
//  This script allows you to include comments in any static page,
//  by making GET and POST requests against the URL:
//
//      http://comments.example.com/comments/ID
//
//  To use this script add the following to the head of your HTML:
//
//  // begin
//  <link rel="stylesheet" type="text/css" href="css/e-comments.css">
//  <script src="http://code.jquery.com/jquery-1.10.1.min.js"></script>
//  <script src="js/mustache.js" type="text/javascript"></script>
//  <script src="js/e-comments.js" type="text/javascript"></script>
//  <script type="text/javascript">
//     $( document ).ready(function() {
//        discussion( "http://comments.example.com/comments/id" );
//     });
//  </script>
//  // end
//
//
//  Once you've done that place a suitable DIV in your document body:
//
//    <div id="comments"></div>
//
//  et voila.
//
//  If comments are present they will be retrieved and displayed, otherwise
// the user will be able to add them.
//
// Steve
// --



//
//
// Load the comments by making a JSONP request to the given URL.
//
// The comments will invoke the `comments(data)` function, when loaded.
//
function loadComments(url, options, err) {
    $.ajax({
        url: url + "?callback=?",
        dataType: 'jsonp',
        crossDomain: true,
        complete: (function() {
            populateReplyForm(url, options, err);
        })
    });
}

//
// Return a comment-form referring to the specified parent.
//
// This is used to create a dynamic reply-to form which can reply to
// a specific parent-comment.kfor the given comment
//
//  TODO: Make this a mustache template too.
//
function replyForm(parent) {
    var form_template = '\
<h2>Add Your Comment</h2> \
<blockquote> \
<form method="POST" class="formy" action="#"> \
  <input type="hidden" name="parent" value="{{#parent}}{{ parent }}{{/parent}}"> \
      <table width="100%" cellpadding="2" cellspacing="2"> \
        <tr><td valign="top" width="50%"> \
        <table> \
        <tr> \
          <td><b>Your Name</b>:</td> \
          <td><input type="text" name="author" size="40%"/></td> \
        </tr> \
        <tr> \
          <td><b>Your Email</b>:</td> \
          <td><input type="text" name="email" size="40%"/><br/>(Optional)</td> \
        </tr> \
        <tr> \
          <td></td>\
          <td><textarea name="body" rows="15" cols="60%"></textarea></td> \
        </tr> \
        <tr> \
          <td></td> \
          <td align=right"><input type="submit" value="Add Comment"/></td> \
        </tr> \
      </table> \
            </td> \
            <td valign="top">\
              <p>Here you can enter your text, we support markdown as you would expect:</p>\
              <ul>\
               <li><code>_italic_</code> -&gt; <i>italic</i></li> \
               <li><code>__bold__</code> -&gt; <strong>bold</strong></li> \
               <li><code>[Link](http://example.com/</code> -&gt; <a href="http://example.com/">Link</a></li> \
              </ul>\
           </td>\
        </tr>\
      </table>\
    </form> \
  </blockquote> \
';

    var html = Mustache.render( form_template, { parent: parent } );
    return( html );
}


//
// Called when the JSONP data is loaded.
//
function comments(data) {

    //
    // We're given a DIV with ID comments.  Empty it.
    //
    $("#comments").html("");

    //
    // We might lose this - I'm undecided.
    //
    id = 1

    //
    // If there are some comments we should post a header.
    //
    if (data.length > 0) {
        $("#comments").prepend("<h2>Comments</h2>");
    } else {
        $("#comments").prepend("<h2>No Comments</h2>");
    }

    //
    // For each comment.
    //
    $.each(data, function(key, val) {

        //
        // This builds a (hidden) reply-to form for the given comment.
        //
        val.reply = function() {
            return function(uuid){
                return( replyForm( val.uuid) );
            }
        };

        //
        // We have a hash of data in the val-argument,
        // which we're going to interpolate into our template.
        //
        // The only one that will have special handling is the
        // gravitar value.  That will either contain a (protocol-agnostic)
        // URL, or be empty.
        //
        if ( val['gravitar'] ) {
            val['gravitar'] = "<img alt=\"[gravitar]\" src=\"" + val['gravitar'] + "\" class=\"avatar\" width=\"33\" height=\"32\">&nbsp;&nbsp;";
        }

        //
        // The template for displaying a single comment.
        //
        // Ideally this would come from our constructor-arguments.
        //
        var comment_template = ' \
<div class="comment"> \
  <div class="link"><a href="#comment_{{ id }}">#{{ id }}</a></div> \
  <div class=\"title\">{{{ gravitar }}}<a name="comment_{{ id }}">Author: {{ author }}</a></div> \
  <div class="tagline">Posted {{ ago }}.</div> \
  <div class="body">{{{ body }}}</div> \
  <div class="replyto"><a href="#">Reply to this comment</a>\
    <div style="display:none; margin:50px; padding:50px; border:1px solid black;">{{#reply}}{{ uuid }}{{/reply}}</div> \
  </div> \
</div> \
<div class="comment-spacing"></div> \
<div style="margin: 50px;" id="replies-{{ uuid }}"></div> \
';

        //
        // Render the output.
        //
        var html = Mustache.render( comment_template, val );

        //
        // If this particular comment is a nested one then we
        // need to insert it into the correct location.
        //
        if ( val['parent'] )
        {
            //
            // Append this comment beneath the named comment.
            //
            $("#replies-" + val['parent']).append(html);
        }
        else
        {
            //
            // Otherwise just append to the bottom of our list
            // of comments.
            //
            $("#comments").append(html);
        }

        //
        // Next comment.
        //
        id += 1;
    });

    //
    // Add a new top-level reply form.
    //
    $("#comments").append(replyForm(null));

}

//
// Generate the reply-form for users to add comments.
//
function populateReplyForm(url, options, err) {

    //
    // Now we've rendered the comments, and populated the
    // hidden forms for replying to particular comments.
    //
    // The next step is to ensure that the various (hidden)
    // forms actually do their magic properly.
    //
    // We do that by binding the submit buttons to send an
    // AJAX POST.
    //
    // We also want to make sure that the cancel-button does
    // a suitable thing.  (i.e. hides the div.)
    //
    //

    //
    // Capture form-submissions.
    //
    $(".formy").bind("submit", (function() {

        //
        // Hide the form(s) when submitting.
        //
        $(".formy").hide();

        //
        //      alert( "Submitting to URL " + url );
        //      alert( $(this).serialize() );
        //
        var data = $(this).serialize();

        // Send the POST
        //
        $.ajax({
            type: "POST",
            url: url,
            data: data,
            error: function(r, e) {
                var err = false;
                if (r.status == 500 )
                {
                    err = r.responseText;
                }
                loadComments(url, options, err );
            },
            complete: function(r, e) {
                var err = false;
                if (r.status == 500 )
                {
                    err = r.responseText;
                }
                loadComments(url, options, err );
            },
            datatype: 'jsonp',
        });
        return false;
    }));


    //
    // Toggle reply-to comment div.
    //
    $(".replyto a").on( 'click', (function () {
        $(this).closest("div").children("div").toggle();
        return false;
    }));


    if (err) {
        alert("<h2>Comment Rejected</h2><blockquote><p>Your comment was not submitted: " + err + "</p></blockquote>");
    }
}

//
// Entry point.
//
// Assumes the URL specified can be used to GET/POST comments, and has
// the identifier associated with it already.
//
//  e.g. http://comments.example.com/comments/apache
//
//
function discussion(url, options) {

    //
    //  Load the comments, and populate the <div id="comments"> area with them
    //
    loadComments(url, options)

}
