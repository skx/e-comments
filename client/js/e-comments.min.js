function loadComments(url,options){$.ajax({url:url+"?callback=?",dataType:'jsonp',crossDomain:true,complete:(function(){populateReplyForm(url,options);})});}
function comments(data){$("#comments").html("");id=1
if(data.length>0){$("#comments").prepend("<h2>Comments</h2>");}
$.each(data,function(key,val){var author=val["author"];var body=val["body"];var ago=val["ago"];$("#comments").append("<div class=\"comment\"> \
<div class=\"link\"><a href=\"#comment_"+id+"\">#"+id+"</a></div> \
<div class=\"title\"><a name=\"comment_"+id+"\">Author: "+author+"</a></div> \
<div class=\"tagline\">Posted "+ago+".</div> \
<div class=\"body\">"+body+"</div> \
</div><div class=\"comment-spacing\"></div>");id+=1;});}
function populateReplyForm(url,options){if(options&&options["reply-placement"]){if(options["reply-placement"]=="above"){$("#comments").prepend("<div id=\"comments-reply\"></div>");}
else if(options["reply-placement"]=="below"){$("#comments").append("<div id=\"comments-reply\"></div>");}
else{alert("Illegal 'reply-placement' value.   You may only use 'above' or 'below'");}}
else{$("#comments").append("<div id=\"comments-reply\"></div>");}
if(options&&options["reply-div"]){$("#comments-reply").html($(options["reply-div"]).html());}
else{$("#comments-reply").html(" \
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
");}
$("#ecommentsreply").bind("submit",(function(){$("#ecommentsreply").hide();$.ajax({type:"POST",url:url,data:$("#ecommentsreply").serialize(),error:function(r,e){loadComments(url,options);},complete:function(r,e){loadComments(url,options);},datatype:'jsonp',})
return false;}));}
function discussion(url,options){loadComments(url,options)}