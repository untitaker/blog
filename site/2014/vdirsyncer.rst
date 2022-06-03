Why I created vdirsyncer
========================

.. raw:: html

    <time>2014-11-16</time>

It was only after the introduction of Buzz and Google+ when I started looking
for alternatives to Google's services, which I used wherever possible up to
that point. I won't try to convince anybody to cease using certain web-services
in this article, it's a trade-off between privacy and convenience everybody has
to decide about on their own. I myself was mostly worried about my address
books, calendars and private messages though. I didn't want to have anybody
read those for sure, at the same time, I wanted to have them synchronized
between all my devices.

I eventually came across the Card- and CalDAV protocols for accessing contact
and calendar data from a server, and promptly set up ownCloud. It did
synchronize fine with my phone [1]_, but all the desktop apps I tried were
tightly bound to a desktop environment. The only application whose feature set
I found to be somewhat enjoyable was Evolution, but at that time, Evolution
seemed to combine Email, Calendar and Contacts in one huge monolithic
application for which the CPU of my underpowered laptop wasn't ready. I briefly
tried to switch to KDE, but the software for this desktop environment did not
only look terrible, but the dependency situation seemed to be much worse there,
and everything seemed to somehow depend on MySQL which I found to be
unacceptable.  It seems that with Gnome 3, calendars, contacts and email have
now been separated into separate applications, but using those mean dealing
with Gnome 3.

Two years later, I started to use CLI applications and avoid the ones with
graphical interfaces. The reasons were entirely unrelated to the calendar and
contacts situation: I didn't care that much about any keyboard shortcuts,
although it has now become a primary reason why I wouldn't want to switch back.
The real, and even more important reason was (and still is) that I wouldn't
have to deal with gconf, dconf, or whichever clone of the Windows Registry they
have now, as if the original was good idea to begin with. Yeah, global state is
bad, and it's even worse if we can't guarantee that programs will delete their
config keys when uninstalled, but storage is cheap on Desktop machines, so why
bother, right? Command-line apps usually store their data in flat files which
also turn into leaked state after uninstallation, but at least I can now safely
delete state from one application without accidentally loosing my system
settings.

There is another advantage to storing data in flat (text) files, which I only
realized when starting to use Mutt in combination with OfflineIMAP_ and
notmuch_: Even if both programs fail you, you're still able to view your
downloaded data with a simple text editor. This might not make a huge
difference to the end user, but to me it does. It also allows you to check your
data into a VCS such as Git, to prevent accidental deletion or file corruption,
although I currently don't do that.

Coming back to my calendar and contacts story, I couldn't find any CLI software
which was able to synchronize with ownCloud [2]_. It seemed that most users in
that area prefer storing their tasks in simple text file, but that solution
would have provided me with basically no integration with Android's calendar
and contact applications. At some point I was so desperate that I tried
accessing my data in ownCloud through a WebDAV client.

Since CalDAV/CardDAV standards are based on WebDAV [3]_, a file-management
protocol, I thought it must be possible to mount my ownCloud calendars and
contacts through a FUSE file system like davfs, and access them as normal
files. It did actually work::

    $ tree /mnt/contacts/default/
    /mnt/contacts/default/
    ├── 08fdaec4-2791-4908-91ef-262b1669dfd7.vcf
    ├── 0cb226b3-9259-4da2-bfac-a92ed9f6ab88.vcf
    ├── 12c57540-c013-4e72-8754-a0f15e1a018d.vcf
    ├── 185ff452-4e89-48d7-8e07-32011e151d24.vcf
    ...

And the corresponding entry from my fstab::

    https://owncloud.unterwaditzer.net/remote.php/carddav/addressbooks/untitaker/ /mnt/contacts davfs user,noauto,uid=untitaker,file_mode=600,dir_mode=700,_netdev 0 1

There is a patch for abook_ which adds a feature for importing ``.vcf`` files,
so I wrote a bash script that removed abook's current database and imported all
files from the ``~/.contacts`` folder. I also wrote watdo_, an extremely shitty
task application for the command line which also accessed ownCloud's calendars
through the mounted filesystem. I also added unison_, a file synchronization
tool, to make my data available offline.

I ran ownCloud on a Raspberry Pi. Because both ownCloud and the Raspberry Pi
are slow, I needed to switch to Radicale_, which is a lightweight CalDAV and
CardDAV server. The main problem I experienced was that Radicale only
implements the subset that is needed to be compatible with the majority of
clients [4]_. It wasn't possible to mount my contacts, calendars and tasks as a
file system, so I had to write my own solution.

I also stumbled upon khal_, which seemed to be the only CLI calendar
application that was able to synchronize with CalDAV. However, khal storing its
data in a sqlite database didn't really help me in any way with my task
application, so I asked khal's author, Christian Geier, about a possible
collaboration to standardize a storage format for events and contacts, storing
data in flat files similarly to how Maildir_ (the storage format used by
OfflineIMAP and Mutt) does it with emails. I wrote the first version of
vdirsyncer_. The storage format vdir_ matches exactly what ownCloud exposes
when mounted via davfs, with some additional restrictions.

.. [1] Using `CalDAV-Sync and CardDAV-Sync by dmfs <http://dmfs.org/>`_. Later
   his Tasks application also got added.

.. [2] I don't think khal_ existed at this point, at least I wasn't able to
   find it. pycarddav_ did exist but it didn't have more features than my
   hacked solution.

.. [3] Which was probably `not a good idea <http://evertpot.com/250/>`_.
   Because CardDAV and CalDAV are huge complex beasts, few servers fully
   implement them, so those protocols are not pleasant to work with from a
   client perspective either.

.. [4] `Which is an intentional choice made by the author
   <http://radicale.org/technical_choices/#idid14>`_.

.. _OfflineIMAP: http://offlineimap.org/
.. _notmuch: http://notmuchmail.org/
.. _watdo: https://github.com/untitaker/watdo
.. _unison: http://www.cis.upenn.edu/~bcpierce/unison/
.. _Radicale: http://radicale.org/
.. _khal: http://lostpackets.de/khal/
.. _pycarddav: https://github.com/geier/pycarddav/
.. _abook: http://abook.sourceforge.net
.. _Maildir: http://cr.yp.to/proto/maildir.html
.. _vdirsyncer: https://vdirsyncer.readthedocs.org/
.. _vdir: https://vdirsyncer.readthedocs.org/en/latest/vdir.html
