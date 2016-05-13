XSS vulnerabilities in Flattr
=============================

:date: 2016-05-13
:category: dev
:tags: flattr, security, disclosure

Last week (May 7th) I disclosed multiple security vulnerabilities to Flattr,
which have since been fixed.  I'm posting them here for sake of transparency,
also because Flattr doesn't have a policy to do so themselves.

Flattr basically lets you send money to any user, with any URL as payment
reference. For that purpose, it allows you to embed JavaScript buttons on your
site that take the user to Flattr. The main difference to other donation
systems is that it doesn't require you to register each piece of content
separately at Flattr, while still allowing you to gather statistics due to
which content the user donated.

If you don't want to use the Flattr button, you can also use `Auto-submit URLs
<http://developers.flattr.net/auto-submit/>`_:

    Instead of the embedded buttons you can use a specific kind of URL that just
    like the button will autocreate, "auto-submit", a Flattr thing on its first
    flattr. This is useful for when you can't use javascript on a site (or don’t
    want to) – just create a static link to an auto-submit URL instead.

The simplest example looks like this::

    https://flattr.com/submit/auto?user_id=[USERNAME]&url=[URL]

Here are the two vulnerabilities:

- ``user_id`` was part of the response body, unescaped, allowing for a very
  simple reflected XSS.

- ``url`` could have any scheme. This also includes ``data`` and ``javascript``
  URIs, which run within the linking site's origin. This means that
  ``javascript:alert(document.cookie)`` would give you cookies for
  ``flattr.com``, and so does the slightly more complex
  ``data:text/html,<script>alert(document.cookie)</script>``.

They have been fixed each:

- Flattr didn't check whether the user specified in ``user_id`` exists. They
  now do. A valid user ID has such a narrow character range, it makes XSS
  impossible.

- ``url`` is now restricted to only a few schemes. It appears that only
  ``http`` and ``https`` work.

Those have been successfully tested with Firefox 46. Chrome seems not to work
with the second vulnerability `as it violates the spec for a reason
<https://bugzilla.mozilla.org/show_bug.cgi?id=1016491>`_.

Below the full conversation.

----

**You wrote:**
    
    Hello,

    What is an appropriate contact/email address for security vulnerability disclosures?

**Flattr replied:**

    Hi

    Simplest is to do it here =)

    Regards Linus

**You wrote:**

    Please visit the following URL:

    https://flattr.com/submit/auto?user_id=%3Cscript%3Ealert%28document.cookie%29;%3C/script%3E&url=https://unterwaditzer.net/2014/vdirsyncer.html

    Furthermore it is possible to use auto-submit with URLs with the javascript-scheme, which can be used for a subset of the things the above XSS already allows. Try clicking the thing's URL here:

    https://flattr.com/submit/auto?user_id=untitaker&url=javascript:alert%28document.cookie%29

**Flattr replied:**

    Hi

    Thanks we will look into it asap.

    Regards Linus

**Flattr replied:**

    Hi

    It should now have been fixed. We would love if you also could check.

    And you have our extreme appreciation!

    Regards Linus

**You wrote:**

    https://flattr.com/submit/auto?user_id=untitaker&url=data:text/html,%3Cscript%3Ealert(document.cookie)%3C/script%3E

    Please use a whitelist of URI schemes

**You wrote:**

    Also UX-wise I'm not sure if responding with a 400 Bad Request (making flattring for such URIs impossible) is better rather than just fixing the XSS?

**You wrote:**

    BTW the remedy against the first attack seems fine. I suspect you're now rejecting unknown user_ids?

**Flattr replied:**

    Until now I thought it would be enough to just escape the output, but I failed to account for the "data:" construct.

    I'm now filtering the url before it's used which also allowed me to, as you suggested, return an error instead of just sanitizing.

    Feel free to mail me directly at [REDACTED] if you have further input or find other issues.

    Best regards, Leif

**You wrote:**

    The fix seems to be appropriate. Thanks for your quick responses.

    Two things:

    1. It would be nice if there were more documentation about how to disclose security issues. Even if that information was specified on /contact/, I don't think using the contact field was a good idea for that, since those messages are publicly visible for anybody knowing the URL. And those URLs are transmitted over unencrypted email for notification.

    2. May I publicly disclose this conversation?

**Flattr replied:**

    Hi,

    Sorry for the late reply, things are quite crazy at the moment.

    You are welcome to publicly disclose the details concerning this issue.

    You are absolutely right that we should be more informative about how to handle security issues and no this contact form is not ideal. We'll try to improve in that area as well.

    Thanks again! Leif
