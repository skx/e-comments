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

I've gone the low-effort route and added a helper to add a (hidden)
reply form beneath every comment.


Upgrading
---------

We can handle most of the changes via a combination of updates to the
server, and the javascript.

The thing that will require change to existing data is to ensure that
every comment has a UUID associated with it.  Without that it will be
impossible to reply to any existing comment.

To upgrade we've supplied two tools:

      utils/add-uuid-redis
      utils/add-uuid-sqlite
