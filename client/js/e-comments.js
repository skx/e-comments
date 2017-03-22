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
//  <script src="https://code.jquery.com/jquery-1.12.4.js"></script>
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


var GLOBAL = {
    //
    // Is threading enabled?
    //
    threading: true,

    //
    // Max depth of threaded-replies, if enabled.
    //
    max_depth: 0,

    //
    // ID of the div to work with
    //
    comments: "comments",
};


//
// Load the comments by making a JSONP request to the given URL.
//
// The comments will invoke the `comments(data)` function, when loaded.
//
function loadComments(url, options, err) {

    //
    // Save any supplied options away.
    //
    if ( options ) {
        jQuery.each(options, function (name, value) {
            GLOBAL[name] = value;
        } );
    }

    $.ajax({
        url: url + "?callback=?",
        dataType: 'jsonp',
        crossDomain: true,
        complete: (function() {
            bindEventHandlers(url, options, err);
        })
    });
}

//
// Return a comment-form referring to the specified parent.
//
// This is used to create a dynamic reply-to form which can reply to
// a specific parent-comment.kfor the given comment
//
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
          <td align="right"><input type="submit" value="Add Comment"/></td> \
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

    //
    // If we were given a template, then use that.
    //
    if (GLOBAL && GLOBAL['reply_template']) {
        form_template = $(GLOBAL['reply_template']).html();
    }

    var html = Mustache.render(form_template, {
        parent: parent
    });
    return (html);
}


//
// Called when the JSONP data is loaded.
//
// This function will be invoked with a JSON array of hashes.
//
// Each array-member represents a single comment, and the hash
// will contain keys such as:
//
//   author    The author of the comment.  (Name)
//   body      The body of the comment.
//   gravitar  The Gravitar link for this auther
//   parent    The parent-comment, if any.
//
// For each comment we add a rendered fragment of HTML to the
// output-div, as well as a per-comment reply form (if nested
// comments are enabled).
//
// Once we've completed the end result will be that the `comments`
// div will be populated, then we setup event-handlers such that
// the expected functions will be invoked on clicks.
//
function comments(data) {

    //
    // We're given a DIV with ID comments.  Empty it.
    //
    $("#" + GLOBAL['comments']).html("");

    //
    // We might lose this - I'm undecided.
    //
    id = 1

    //
    // If there are some comments we should post a header.
    //
    if (data.length > 0) {
        $("#"+ GLOBAL['comments']).prepend("<h2>Comments</h2>");
    } else {
        $("#"+ GLOBAL['comments']).prepend("<h2>No Comments</h2>");
    }


    //
    // Count the thread-depth for each comment.
    //
    // The key is the UUID of the particular comment.
    //
    var nesting = {};

    //
    // For each comment.
    //
    $.each(data, function(key, val) {


        //
        // This builds a (hidden) reply-to form for the given comment.
        //
        val.reply = function() {
            return function(uuid) {
                return (replyForm(val.uuid));
            }
        };

        //
        // Calculate the thread-depth of the current comment.
        //
        val.depth = function() {
            return function(uuid) {
                return (nesting[val.uuid]);
            }
        };

        //
        // Is threading enabled?
        //
        val.threading = GLOBAL['threading'];

        //
        // We have a hash of data in the val-argument,
        // which we're going to interpolate into our template.
        //
        // The only one that will have special handling is the
        // gravitar value.  That will either contain a (protocol-agnostic)
        // URL, or be empty.
        //
        if (val['gravitar']) {
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
  <div class="title">{{{ gravitar }}}<a name="comment_{{ id }}">Author: {{ author }}</a></div> \
  <div class="tagline">Posted <span title="{{ time }} ">{{ ago }}</span>.</div> \
  <div class="body">{{{ body }}}</div> \
  {{#threading}}<div class="replyto"><a href="#">Reply to this comment</a><div style="display:none; margin:50px; padding:50px; border:1px solid black;">{{#reply}}{{ uuid }}{{/reply}}</div></div>{{/threading}} \
</div> \
<div class="comment-spacing"></div> \
<div style="margin: 50px;" id="replies-{{ uuid }}"></div> \
';

        //
        // If we were given a display-template, then use that.
        //
        if (GLOBAL && GLOBAL['comment_template']) {
            comment_template = $(GLOBAL['comment_template']).html();
        }

        //
        // Record the depth of this comment.
        //
        // The depth is the parent's depth + 1
        //
        // If there is no parent then we default to one, as expected.
        //
        if (val['parent']) {
            nesting[ val['uuid'] ] = nesting[ val['parent'] ] + 1;
        } else {
            nesting[ val['uuid'] ] = 1;
        }

        //
        // Disable replies if the current thread is "too deep".
        //
        if( ( GLOBAL['max_depth'] ) && ( val.threading ) )
            if ( ( GLOBAL['max_depth'] != 0 ) && ( nesting[ val['uuid'] ] > GLOBAL['max_depth' ] ) )
                val.threading = false;

        //
        // Render the output.
        //
        var html = Mustache.render(comment_template, val);

        //
        // If this particular comment is a nested one then we
        // need to insert it into the correct location.
        //
        if (val['parent']) {
            //
            // Append this comment beneath the named comment.
            //
            $("#replies-" + val['parent']).append(html);
        } else {
            //
            // Otherwise just append to the bottom of our list
            // of comments.
            //
            $("#"+ GLOBAL['comments']).append(html);
        }

        //
        // Next comment.
        //
        id += 1;
    });

    //
    // Now we're going to truncate the bodies of long comments.
    //
    // This should have been done when the comment-bodies were inserted
    // but for the moment it goes here.
    //
    // We'll show ten lines by default, or 1024 characters.
    //
    var minimized_elements = $('.body');
    var max_lines          = 10;
    var max_length         = 1024;

    minimized_elements.each(function(){

        //
        // Split on newlines.
        //
        var text   = $(this).html()
        var lines  = text.split(/[\r\n]/);
        var lcount = lines.length;

        var trunc = undefined;
        var rest  = undefined;

        //
        // Too many lines?
        //
        if ( lcount >= max_lines )
        {
            //
            // The truncated text, and the rest of that text.
            //
            trunc = lines.slice(0, max_lines).join("\n");
            rest  = lines.slice(max_lines, lcount).join("\n");
        }

        //
        // Too much text?
        //
        if ( ( text.length > max_length ) && ( trunc == undefined ) )
        {
            //
            // The truncated text, and the rest of the text.
            //
            trunc = text.substr(0,max_length);
            rest  = text.substr(max_length);
        }

        //
        // If we have `truncated` and `rest` of the text then
        // update the DOM to show the truncated version and the
        // magic-link to expand the text.
        //
        if ( trunc && rest )
        {
            //
            // Modify the display of the body.
            //
            $(this).html(
                trunc +
                    '<br/><a href="#" class="more">Read more ..</a>' +
                    '<span style="display:none;">'+ rest +'</span>'
            );
        }
    });

    //
    // Add a new top-level reply form.
    //
    $("#"+ GLOBAL['comments']).append(replyForm(null));

}

//
// This function is called after the JSONP-callback function,
// which is responsible for parsing and inserting the comments/forms
// into the HTML-page.
//
// This function sets up the event-handles such that those freshly
// inserted forms and divs work as expected.
//
function bindEventHandlers(url, options, err) {

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

        //
        // Send the POST-request
        //
        $.ajax({
            type: "POST",
            url: url,
            data: data,
            error: function(r, e) {
                var err = false;
                if (r.status == 500) {
                    err = r.responseText;
                }
                loadComments(url, options, err);
            },
            complete: function(r, e) {
                var err = false;
                if (r.status == 500) {
                    err = r.responseText;
                }
                loadComments(url, options, err);
            },
            datatype: 'jsonp',
        });
        return false;
    }));


    //
    // Toggle reply-to comment div.
    //
    $(".replyto a").on('click', (function() {
        $(this).closest("div").children("div").toggle();
        return false;
    }));


    //
    // Allow long comments - which are possibly SPAM? - to be displayed.
    //
    $('a.more').click(function(event){
        event.preventDefault();
        $(this).hide().prev().toggle();
        $(this).next().toggle();
    });

    //
    // If there was an error submitting the comment then handle it here.
    //
    // We do two things:
    //
    //  * Prepend the error-message to the comment-area.
    //
    //  * Scroll to make sure that is visible.
    //
    // Downside is we lose the comment/author/name, which is a shame.
    //
    // (The reason we lose this is that we nuke the existing contents
    // of the comment-div, and then reinsert the existing values from
    // scratch as a result of the AJAX POST request completing.)
    //
    if (err) {
        $("#"+ GLOBAL['comments']).prepend("<h2>Comment Rejected</h2><blockquote><p>Your comment was not submitted.</p><p><b>" + err + "</b></p></blockquote>");

        $('html, body').animate({
            scrollTop: $("#"+ GLOBAL['comments']).offset().top
        }, 1000);
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
