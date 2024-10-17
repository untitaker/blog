API wrappers should be deep, not wide
=====================================

<time id=post-date>2024-10-17</time>

_(It is time to invoke John Ousterhout.)_

Whenever I want to interact with the API of some web service, chances are that
I only need to interact with a very small subset of its entities, but all of
its fundamentals.

* I might only need post, timeline and user entities, but not DMs, follow requests, "stories", "spaces".
* However, I probably want to delegate the jobs of authentication, pagination and rate-limiting to a library.

Meaning that this:

```{.sourceCode .python}
# This API is made up and does not match any real library on purpose.

from mylibrary import *

client = Client(token="...")

user = User.get(client=client, id=123)

for item in Post.get_many(user=user):
    print(item)
```

Is not inherently more appealing to me than this:

```{.sourceCode .python}
# This API is also made up.

from requests import get

for item in get("https://example.social/users/123/posts").json():
    print(item)
```

Here's what I really care about:

* **Is `get`/`get_many` handling 429 for me?** I might apprechiate it if the client library actually did handle retries by itself. There's some complications coming from this: Does the language have greenthreads/async where this is feasible, how often should the client retry. But some basic handling would allow me to write naive code that breaks less easily.
* **Do I need to handle the next page by myself?** I have seen libraries that instead expose a `next_page` property on their iterator, and make me have to think about pagination myself. How many pages to fetch? How large should a page be? Should pages be pre-fetched?
- **What kind of authentication do I need?** Above `Client` object exposes `token`, but where do I get the token from? Granted, this part is usually so complicated it requires deep integration into whatever web framework you're using.

None of which is apparent from a simple code snippet like that.

Somehow, half of the API wrappers I end up looking at don't have answers to any of these questions. They're thin, but _wide_ wrappers around the underlying HTTP client, and end up providing little more than IDE autocompletion this way (while sometimes even tying me to a HTTP client I don't even want).

That's usually not worth the added dependency for me, and it's better to write types for the API responses myself.
