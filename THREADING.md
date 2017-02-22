Comment Threading
=================

Comment threading is nicer for users than long & flat discussions.

The problem is that we want to be efficient on the server-side, which
means that we only return a flat array of comment-data, rather than some
kind of tree-structure.

The simplest solution to this problem is the obvious one:

* Ensure that every distinct comment has a (unique) ID.
* Each comment will either have:
   * Parent is null.
   * Parent is a reference to the UUID of the parent comment.

Providing that the children occur __after__ the parent in the array
we can this handle threading at the display stage:

* For each comment.
    * If the parent is null/unset, then append to the list of comments.
    * Otherwise find the named-parent, and append to _that_.



Handling Replies
----------------

Replies are currently entered via a form at the bottom of the list of
comments, this is the default "no parent" setup.

We need to add a link "Reply to _this_ comment" beneath every comment.

All that will do is *clone* the comment-reply form, and populate the
hidden parent field.
