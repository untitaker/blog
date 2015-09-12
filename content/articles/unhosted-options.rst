===============================
The Dream of the personal Cloud
===============================

:public: false

ownCloud
========

ownCloud_ is a server-side web application that incorporates very many services
into its user management system. As a ownCloud user you can install multiple
*apps* into ownCloud. A few examples are calendar and addressbook hosting, note
taking, file hosting (that one is actually built-in) and a feed reader.

WebDAV
======

WebDAV_ is a file access and transfer protocol created in the 90s. It has
support for file locks, arbitrary additional key-value properties on folders,
file mimetypes, and very many other features that extend this standard. It also
has very powerful access control features.

It seems to be mainly used in corporate environments, yet somehow it
has crept into the FOSS-community. Which is why I came into contact with it.

OwnCloud supports the WebDAV protocol, obviously for retrieving and uploading
files. It also supports two variants of WebDAV:

- CalDAV, a protocol for accessing calendars. Basically you send a special
  request to retrieve the *calendar root*, which is basically a WebDAV folder.
  That folder contains subfolders, each of which represents a calendar. Inside
  that calendar are events, each represented as a file in the iCalendar_
  format.

- CardDAV, the same thing as CalDAV, but for addressbooks. It uses VCard_ for
  serialization of contacts.

Both of those protocols are authored by Apple, which uses them to synchronize
data between iCloud and the built-in apps on iOS.

Both protocols are neither a superset nor a subset of WebDAV: While their RFC
mandates that such servers have to fully support WebDAV, they can (*should*)
reject invalid iCalendar/VCard data. And obviously the folder structure is
limited. You can't create a calendar folder inside another calendar folder, for
example.

I guess the idea was that you could just use an existing WebDAV client library
to access your calendar data in an easy way. However, the fact that CalDAV and
CardDAV are based on WebDAV has only downsides. In practice, most
CardDAV/CalDAV servers implement the bare minimum to stay compatible with the
majority of CardDAV/CalDAV clients. Many features of WebDAV are unused in those
protocols, some are explicitly forbidden, but the majority is simply not
supported.

Yet the spec authors added new queries to both CardDAV and CalDAV, specific to
their datamodels. For example, in WebDAV, you can send a ``PROPFIND`` HTTP
request (yes, that's a HTTP method) with a ``Depth: 1`` header and the
following XML as payload to a folder URL::

    <?xml version="1.0" encoding="utf-8" ?>
    <D:propfind xmlns:D="DAV:">
        <D:prop>
            <D:getcontenttype/>
            <D:getetag/>
        </D:prop>
    </D:propfind>

The WebDAV server then responds with another XML document that enlists URLs for
each file in that folder. It also includes the requested properties. In this
case, we requested the current etag and the MIME-type. You can also change the
``Depth`` header to recursively list files in subfolders, kind of like what the
``find`` command does. The server has to support all these fun queries,
otherwise clients will break. Or some of them. You never know.

And even though the WebDAV protocol allows for so many slightly different
queries, there was one feature missing: You can't *filter* folder listings. In
the case of CalDAV, that means you can't get a listing for a specific
timerange. You will have to download *all events from the server* when
synchronizing a calendar. This is not feasible, not only bandwidth-wise [#]_,
but also in regards to space when considering mobile devices.

.. [#] This would be a ridiculous reason given that WebDAV already uses XML.

At this point it might have made sense to extend ``PROPFIND`` requests to
filter by properties. But the authors made a different decision anyway [#]_.
WebDAV also has a method called ``REPORT``. Of course you can send XML with
that method too, why wouldn't you. Here's how it looks like::

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

.. [#] I actually couldn't find any rationale for this. Given my experience
   with those protocols I assume none.

And there you have your filtering feature, *all encapsulated in a new XML
namespace like God intended it to be*. The filtering semantics can be explained
like this: You're querying for a ``VCALENDAR`` component (basically a container
for events and timezone definitions), then you query for a ``VEVENT`` component
inside it (an event, duh), and since every event has a start and end datetime,
you can finally filter by those too.

But why would you want to filter by events? What else could there be inside of
a calendar? Turns out you can also store tasks (``VTODO``) and diary entries
(``VJOURNAL``) inside one. Remember that Apple uses this protocol? This is
why when you delete a tasklist in the Tasks app, it warns you that your
same-named calendar will also be deleted [#]_. This is how your iPhone calendar
syncs to iCloud. And people think the legacy of HTTP or TCP is crippling.

.. [#] Tested on an old iPod touch, running iOS 6. (FIXME: Check that) I'm
   pretty sure nothing has changed since then.

.. _ownCloud: http://owncloud.org/
.. _WebDAV: https://en.wikipedia.org/wiki/WebDAV
.. _iCalendar: https://tools.ietf.org/html/rfc5545
.. _VCard: https://tools.ietf.org/html/rfc6350
