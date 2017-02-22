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
// Called when the JSONP data is loaded.
//
function comments(data) {
    //
    // We're given a DIV with ID comments.  Empty it.
    //
    //
    $("#comments").html("");
    id = 1

    //
    // If there are some comments we should post a header.
    //
    if (data.length > 0) {
        $("#comments").prepend("<h2>Comments</h2>");
    }

    $.each(data, function(key, val) {

        //
        //  The variables from the comment
        //
        var author = val["author"];
        var body = val["body"];
        var ago = val["ago"];
        var gravitar = val["gravitar"];

        //
        // We might not have a gravitar, so we'll only include
        // it if it is set
        //
        if ( gravitar ) {
            gravitar = "<img alt=\"[gravitar]\" src=\"" + gravitar + "\" class=\"avatar\" width=\"33\" height=\"32\">&nbsp;&nbsp;";
        } else {
            gravitar = "";
        }

        $("#comments").append("<div class=\"comment\"> \
<div class=\"link\"><a href=\"#comment_" + id + "\">#" + id + "</a></div> \
<div class=\"title\">" + gravitar + "<a name=\"comment_" + id + "\">Author: " + author + "</a></div> \
<div class=\"tagline\">Posted " + ago + ".</div> \
<div class=\"body\">" + body + "</div> \
</div><div class=\"comment-spacing\"></div>");

        id += 1;
    });
}

//
// Generate the reply-form for users to add comments.
//
function populateReplyForm(url, options, err) {


    //
    //  Once the comments are loaded we can populate the reply-area.
    //
    if (options && options["reply-placement"]) {
        if (options["reply-placement"] == "above") {
            $("#comments").prepend("<div id=\"comments-reply\"></div>");
        }
        else if (options["reply-placement"] == "below") {
            $("#comments").append("<div id=\"comments-reply\"></div>");
        }
        else {
            alert("Illegal 'reply-placement' value.   You may only use 'above' or 'below'");
        }
    }
    else {
        $("#comments").append("<div id=\"comments-reply\"></div>");
    }

    //
    //  If we got options we might have a DIV to use for Reply-purposes.
    //
    //  If so use it.
    //
    if (options && options["reply-div"]) {
        $("#comments-reply").html($(options["reply-div"]).html());
    }
    else {
        //
        //  This is unpleasant.
        //
        $("#comments-reply").html(" \
<h2>Add Comment</h2> \
<blockquote> \
<form method=\"POST\" id=\"ecommentsreply\" action=\"\"> \
      <table> \
        <tr> \
          <td>Your Name</td> \
          <td><input type=\"text\" name=\"author\" /></td> \
        </tr> \
        <tr> \
          <td>Your Email</td> \
          <td><input type=\"text\" name=\"email\" /> (Optional)</td> \
        </tr> \
        <tr> \
          <td colspan=\"2\"><textarea name=\"body\" rows=\"5\" cols=\"50\"></textarea></td> \
        </tr> \
        <tr> \
          <td></td> \
          <td align=\"right\"><input type=\"submit\" value=\"Add Comment\"/></td> \
        </tr> \
      </table> \
    </form> \
  </blockquote> \
");
    }

    if (err) {
        $("#comments-reply").prepend("<h2>Comment Rejected</h2><blockquote><p>Your comment was not submitted: " + err + "</p></blockquote>");
    }

    //
    // Capture form-submissions.
    //
    $("#ecommentsreply").bind("submit", (function() {

        //
        // Hide the form when submitting.
        //
        $("#ecommentsreply").hide();

        //
        // Send the POST
        //
        $.ajax({
            type: "POST",
            url: url,
            data: $("#ecommentsreply").serialize(),
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
