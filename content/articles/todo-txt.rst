=========================================================================
Be careful with todo.txt, or: Dropbox isn't the solution to every problem
=========================================================================

:date: 2017-01-26
:category: dev
:tags: sync, dropbox, todo.txt, unix

This is one of those posts that I've wanted to write for a while now, but given
that the situation hasn't changed in the slightest, and that people are still
unaware of the general problem, I guess it's time for a blogpost.

You may or may not know `todo.txt <http://todotxt.com/>`_. It is a very simple
task management script, basically a thin wrapper around a single textfile that
stores all your tasks. On desktop it is very easy to edit that file by hand, on
mobile devices, todo.txt offers various apps that are wrappers around this
plaintext format. Since this is just a file you're editing, it seems natural to
use Dropbox to synchronize your tasks between your devices. In fact Dropbox is
what the offered mobile apps integrate with.

Unfortunately, that idea comes with severe drawbacks. Just take two devices
offline and edit your task list on either of them. Then take the devices online
again, and let Dropbox sync. Of course Dropbox does not know anything about the
file format, so it doesn't dare to merge and creates a separate file (for
example ``todo (hostname's conflicted copy 2017-01-26).txt``) that contains the
version of your tasklist from the other device instead. So whenever you edit
anything on two devices while they're offline, you're left with merging two
textfiles manually.

This wouldn't be so bad in situations where you are directly interacting with
the filesystem anyway, such as when editing the file on desktop with a normal
texteditor. But when you use the mobile apps, the entire point is that you
don't have to edit textfiles with a on-screen keyboard. At least the Android
application doesn't do anything about this either. It ignores all the files
that Dropbox may have created.

The leakiest abstractions are the most unixoid ones
---------------------------------------------------

Aesthetically, this separation of data editing and synchronization and the fact
that you have very direct control and knowledge of the underlying datastructure
is very appealing to the average Unix-Fan, and if I had to guess, the feel of
control one gains from this design made todo.txt a success.

My main gripe is with a certain belief it creates: The idea that arbitrary file
synchronization programs are suitable for synchronizing arbitrary data.
Sometimes your constraints force you into a situation where you have to use
Dropbox to sync your data, but it appears that most users don't consider the
tradeoffs that come with this solution.
