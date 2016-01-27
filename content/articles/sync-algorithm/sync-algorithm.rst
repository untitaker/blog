A simple synchronization algorithm
==================================

:date: 2016-01-25
:category: dev
:tags: vdirsyncer, algorithm, sync

I am writing this article out of my experience with writing vdirsyncer_, a
simple synchronization program for calendar events. The same ideas can be used
for file synchronization. The whole article is targeted at people who need to
write some sort of "cloud synchronization" and have no idea where to start,
and/or when journal-based approaches are not an option due to API restrictions.

Recap: The problem and OfflineIMAP's approach
---------------------------------------------

For a start, read `How OfflineIMAP works by E.Z. Yang`_. It deals
with the synchronization algorithm used by OfflineIMAP, a program that can be
used to synchronize emails between IMAP accounts and/or Maildir_ folders.

OfflineIMAP's algorithmic problem can be summarized as follows:

    You are given two "sets" ``A`` and ``B`` of "items", where the items have
    immutable content and globally unique IDs. Define the function ``sync``.
    If items are added to one set, then ``sync(A, B)`` should copy those items
    to the other set. If items are deleted from one set, those deletions should
    also be performed on the other set.

The presented solution involves maintaining a third set, called the ``status``,
that keeps track of the item IDs (not content) that were present after the
previous sync process. On first synchronization, that set is empty.

For each item ID (from ``A, B, status``), there are several possibilities as to
which sets it is in:

* .. image:: /articles/sync-algorithm/simplevenn-a.png
     :align: right
  
  ``A - B - status`` -- If the ID exists on side ``A``, but not on ``B`` or the
  ``status``, it must have been created on ``A``. Copy the item from ``A`` to
  ``B`` and update the ``status`` with the latest etags for both sides.

  + .. image:: /articles/sync-algorithm/simplevenn-b.png
       :align: right

    ``B - A - status`` -- Likewise if the ID exists only in ``B``, it must have
    been created there.

* .. image:: /articles/sync-algorithm/simplevenn-as.png
     :align: right
  
  ``A + status - B`` -- If the ID exists on side ``A`` and the status, but not
  on ``B``, it has been deleted on ``B``. Delete it from ``A`` and the
  ``status``.

  + .. image:: /articles/sync-algorithm/simplevenn-bs.png
       :align: right
    
    ``B + status - A`` -- If the ID exists on side ``B`` and the status, but
    not on ``A``, it has been deleted on ``A``.

* .. image:: /articles/sync-algorithm/simplevenn-ab.png
     :align: right

  ``A + B - status`` -- If it exists on side ``A`` and side ``B``, but not in
  ``status``, add the ID to the status.

* .. image:: /articles/sync-algorithm/simplevenn-s.png
     :align: right
  
  ``status - A - B`` -- If it exists only in the ``status`` it doesn't exist in
  reality, delete the ID from the status.

This algorithm assumes that items are immutable. In order to use it with
mutable items, one could declare that modified items are treated as entirely
new items.  If an item is changed in one set, it would be first deleted from,
then created again at the other side. However elegant that approach might seem,
it has two huge flaws:

* If an item is modified on both sides, both versions will be present on both
  sides. This is actually desirable in applications that don't know anything
  about the item content anyway (such as file sync), but in other cases this is
  nearly useless behavior.

* In practice, deleting and then creating often requires more API calls than a
  single update.

The problem with mutable items
------------------------------

Let's restate the problem above with mutable items:

    You are given two "sets" ``A`` and ``B`` of "items", where each item has a
    globally unique ID and mutable content. Define the function ``sync``.
    
    * If items are added to one set, then ``sync(A, B)`` should copy those
      items to the other set.

    * If items are deleted from one set, those deletions should also be
      performed on the other set.

    * If items on one side are modified, they should replace the items on the
      other side.

Let's also assume that there's a cheap way to determine a checksum (an
``etag``) for each item, cheap enough to be run for all items in both sets. In
the case of a file sync tool you could use file's mtimes [1]_, or if you
don't have too tight performance constraints, just hash the content of each
file. The ``etag`` for an item on side ``A`` may differ from the ``etag`` of
the same exact item on side ``B``.

The algorithm
-------------

Before we create the algorithm, we need to redefine our ``status`` from a set
to a mapping. Now it not only has to keep track of the item IDs, but also has
to map each item ID to a tuple of two etags: One for each side of ``{A, B}``.
Here's an example:

+-----------------+----------+----------+
| Item ID (index) | ETag A   | ETag B   |
+-----------------+----------+----------+
| 1               | 771627ff | caf893af |
+-----------------+----------+----------+
| 2               | dc165135 | 07b92840 |
+-----------------+----------+----------+

.. image:: /articles/sync-algorithm/simplevenn-abs.png
   :align: right

A few additional cases have to be added if the item exists on ``A, B, status``:

* If the etag has changed on ``A`` but not ``B``, copy from ``A`` to ``B``.

  + If the etag has changed on ``B`` but not ``A``, copy from ``B`` to ``A``.

* If the etag has changed on both ``A`` and ``B``, invoke
  ``conflict_resolution``.

And the following case has to be modified:

* ``A + B - status`` -- If the ID exists on side ``A`` and side ``B``, but not
  in ``status``, we can *not* just create it in status, since the two items
  might contain different content each. Invoke ``conflict_resolution``.

Conflict resolution
~~~~~~~~~~~~~~~~~~~

``conflict_resolution`` is its own routine, and what it actually does depends
heavily on actual usecase and the amount of knowledge your application has of
the underlying data. A few options for its implementation:

* Prompt the user which version is preferrable.

* Create both versions of each file under new IDs on both sides.

* Do some other thing that only works in specific situations.

  + Perhaps you have access to the last-modified date and can use that to
    determine the most up-to-date version?

  + Perhaps you managed to save the old version from the previous sync and can
    perform a three-way merge?

  + Perhaps the file format you're working with carries a full change history
    with it, and you can use that to get a usable merge?

What you always should do as part of conflict resolution is to check whether
the item actually has different content on each side. When called the first
time, the status is empty, so ``sync`` will call ``conflict_resolution`` for
each item ID.

.. [1] The last-modified date of a file on POSIX. If you consider using
   that, keep in mind:

   * Depending on the OS and filesystem, mtime's precision may be insufficient.
     On FAT, it has only 2-second resolution, and POSIX ``st_mtime`` may vary
     in precision (there's also ``st_mtime_ns``). This means that mtime-based
     change detection might miss some changes, as mtime after file modification
     is the same as the old one.

   * You can randomly touch files (updating their mtimes) without modifying
     their content, such that your application sees "bogus changes" in items.
     This might lead to more synchronization conflicts and unnecessary calls to
     ``conflict_resolution``.

   Vdirsyncer uses mtimes only as an indicator that a file *might* have
   changed, and gets rid of false positives by comparing hashes of item's
   content.

.. _vdirsyncer: https://github.com/untitaker/vdirsyncer
.. _How OfflineIMAP works by E.Z. Yang: http://blog.ezyang.com/2012/08/how-offlineimap-works/
.. _Maildir: https://cr.yp.to/proto/maildir.html
