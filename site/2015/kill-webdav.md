I hope WebDAV dies
==================

<time id=post-date>2015-09-14</time>

WebDAV
------

[WebDAV](https://en.wikipedia.org/wiki/WebDAV) is a file access and
transfer protocol created in the 90s. It has support for file locks,
arbitrary key-value properties attached to folders, file mimetypes, and
many other features that extend this standard. It also has powerful
access control features.

There are also two protocols that extend WebDAV. This blogpost is more
about them:

-   CalDAV, a protocol for accessing calendars. Basically you send a few
    requests to retrieve URLs to special folders that represent a
    calendar each. Inside those calendar folders are events, each
    represented as a file in the
    [iCalendar](https://tools.ietf.org/html/rfc5545) format.
-   CardDAV, the same thing as CalDAV, but for addressbooks. It uses
    [VCard](https://tools.ietf.org/html/rfc6350) for serialization of
    contacts.

Both of those protocols are authored by Apple, which uses them to
synchronize data between iCloud and the built-in apps on iOS.
FOSS-software like [ownCloud](http://owncloud.org/) or
[Baikal](http://baikal-server.com/) also supports them. Nowadays those
are the standard protocols for accessing calendar and contacts data from
a server.

Both protocols are neither a superset nor a subset of WebDAV: While
their RFC mandates that such servers have to fully support WebDAV, they
can (*should*) reject invalid iCalendar/VCard data. And obviously the
folder structure is limited. You can\'t create a calendar folder inside
another calendar folder, for example.

The spec authors also added new queries to both CardDAV and CalDAV,
specific to their datamodels. For example, in WebDAV, you can send a
`PROPFIND` HTTP request (yes, that\'s a HTTP method) with a `Depth: 1`
header and the following XML as payload to a folder URL:

    <?xml version="1.0" encoding="utf-8" ?>
    <D:propfind xmlns:D="DAV:">
        <D:prop>
            <D:getcontenttype/>
            <D:getetag/>
        </D:prop>
    </D:propfind>

The WebDAV server then responds with another XML document that enlists
URLs for each file in that folder. It also includes the requested
properties for each file. In this case, we requested the current etag
and the MIME-type. You can also change the `Depth`-header to recursively
list files in subfolders, kind of like what the `find`-command does. The
server has to support all these fun queries, otherwise clients will
break. Or some of them. You never know.

And even though the WebDAV protocol allows for so many slightly
different queries, there was one feature missing: You can\'t *filter*
folder listings. In the case of CalDAV, that means you can\'t get a
listing for a specific timerange. You will have to download *all events
from the server* when synchronizing a calendar. This is not feasible,
not only bandwidth-wise[^1], but also in regards to space when
considering mobile devices.

At this point it might have made sense to extend `PROPFIND` requests to
filter by properties. But the authors made a different decision. WebDAV
also has a method called `REPORT`. Of course you can send XML with that
method too, why wouldn\'t you. Here\'s what it looks like:

    <?xml version="1.0" encoding="utf-8" ?>
    <C:calendar-query xmlns:D="DAV:"
        xmlns:C="urn:ietf:params:xml:ns:caldav">
        <D:prop>
            <D:getcontenttype/>
            <D:getetag/>
        </D:prop>
        <C:filter>
            <C:comp-filter name="VCALENDAR">
                <C:comp-filter name="VEVENT">
                    <C:time-range start="20150909T000000Z" end="20300909T000000Z"/>
                </C:comp-filter>
            </C:comp-filter>
        </C:filter>
    </C:calendar-query>

And there you have your filtering feature, *all encapsulated in a new
XML namespace like God intended it to be*. The filtering semantics can
be explained like this: You\'re querying for a `VCALENDAR` component
(basically a container for events and timezone definitions), then you
query for a `VEVENT` component inside it, and since every event has a
start and end property, you can finally filter by those too.

But why would you want to filter by events? What else could there be
inside of a calendar? Turns out you can also store tasks (`VTODO`) and
diary entries (`VJOURNAL`) inside one. Remember that Apple uses this
protocol? This is why when you delete a tasklist in the Tasks app, it
warns you that your same-named calendar will also be deleted[^2]. This
is how your iPhone calendar syncs to iCloud. And people think the legacy
of HTTP or TCP is crippling.

WebDAV in practice
------------------

[Flock](https://github.com/WhisperSystems/Flock) was an Android app that
offered end-to-end encrypted contact and calendar sync. Under the hood
they used the CalDAV and CardDAV protocols. They shut down a few months
ago. [Their main developer wrote a short note on the technical reasons
behind it](https://gist.github.com/rhodey/873ae9d527d8d2a38213).

The fact that CalDAV and CardDAV are based on WebDAV has fatal downsides
in practice. I guess the idea was that you could just use an existing
WebDAV client library to access your calendar data in an easy way. In
practice, all of this complexity makes servers really hard to implement
properly. Consequently most servers only implement a subset, which leads
to massive compatibility problems, and leaves client developers with the
challenge to find a subset of the protocol that is supported by the
servers they care about. In practice, you can\'t use a WebDAV client
library. In practice, you copy-paste XML from the examples in the RFC
into your source code and hope for the best.

I also wrote a client called \"vdirsyncer\". I even [blogged about
it](https://unterwaditzer.net/2014/vdirsyncer.html). Yes, CalDAV and
CardDAV being derived from WebDAV does allow for some pretty cool tricks
involving a WebDAV FUSE filesystem and a bunch of shellscripts that
scrape the files in that filesystem and add them up to a listing of
contacts and calendars. But that\'s about it with the upsides of that
protocol. And in practice that trick works with only a few servers
anyway.

Vdirsyncer\'s integration tests spawn several popular WebDAV servers and
run a massive amount of tests against them. In some servers, that
testsuite found bugs that one couldn\'t even call edgecases. Things like
renaming a calendar, or fetching multiple events in a single request
were completely broken. The fact that those bugs don\'t seem to get
noticed by the user shows how flexible clients are when it comes to
working around buggy implementations. And those are just the ones that
are actually testable in a sane way. The most broken servers are part of
massive groupwares that would probably eat up all of the RAM in Travis\'
VMs.

The future
----------

I\'m currently playing around with
[remoteStorage](http://remotestorage.io/). It\'s a file transfer
protocol, like WebDAV. But at least the protocol is simple, based on
HTTP, and a little JSON for file listings. It doesn\'t support locks. It
doesn\'t support ACLs, or whatever they are called. It doesn\'t support
attaching arbitrary properties to a folder. It doesn\'t support all
those crazy features that make CalDAV- and CardDAV-servers hard to
implement, and as a result clients. Yes, it\'s slow to fetch all events,
but so is parsing XML. And since remoteStorage doesn\'t restrict the way
I store files, I can always change the way I store files to somehow
implement that time-range querying feature CalDAV has. Or not, I don\'t
want to end up with something like CalDAV. Perhaps I\'ll just run a
cronjob to automatically delete old events, I don\'t know.

The only thing that is more complex in remoteStorage than in WebDAV is
authentication. RemoteStorage requires the server to support a subset of
OAuth, and that\'s the only kind of authentication supported. It also
requires WebFinger support instead of making it optional (like in
WebDAV, where it\'s almost a luxury if the DAV client actually *finds*
the HTTP endpoints it\'s supposed to use). It also has a simple
permission system baked into the authentication protocol that actually
gives the user control over the data applications can access.

I\'m hoping to replace WebDAV in my personal infrastructure as far as
possible. It probably won\'t ever go away, but at least I can try. I\'ve
also [extended
vdirsyncer](https://github.com/untitaker/vdirsyncer/pull/265) so I can
use it to synchronize a CalDAV/CardDAV-server with a
remoteStorage-server. It\'s still a work-in-progress, but at least it\'s
not a Sisyphean task like writing a CalDAV/CardDAV-client that actually
works.

For the users of vdirsyncer this means nothing, because I still rely on
WebDAV myself. But as I dive deeper into the remoteStorage protocol,
I\'m less and less inclined to work around bugs in your stupid
groupware.

------------------------------------------------------------------------

Thanks to [\@skddc](https://twitter.com/skddc) for reviewing.

[^1]: This would be a ridiculous reason given that WebDAV already uses
    XML.

[^2]: Tested on an old iPod touch, running iOS 6. I\'m pretty sure
    nothing has changed since then.
