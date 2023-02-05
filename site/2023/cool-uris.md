Cool URIs can be ugly
=====================

<time id=post-date>2023-02-05</time>

Around last year this blog, a simple static site, was running on GitHub pages, together with Cloudflare in front of it due to (perceived) unreliability with GitHub’s SSL provisioning for custom domains. In order to simplify my stack, I tried running it on [Cloudflare Pages](https://pages.cloudflare.com/).

The setup process was extremely smooth. Connecting to the GitHub repository where my blog lives worked just as expected, setting up their CI was painless, and since Cloudflare was already managing my domain’s DNS, switching over DNS records to point to the new static site was literally just a button click.

This worked fine for a week or so until I found some pretty surprising behavior in Cloudflare’s static site hosting that made me stop using their services immediately.

My blogposts have the following URL format:

```
https://unterwaditzer.net/<year>/<slug>.html
```

I inherited this decision from the static site generator I started with, [liquidluck](https://github.com/lepture/liquidluck), and have since then put a lot of care into ensuring this format never changes as I moved away from it, even though the format could perhaps be a little bit cleaner.

The corresponding file on the filesystem is `/<year>/<slug>.html`.

Yet as soon as I moved to Cloudflare Pages, I found that suddenly all blogposts were served under the following format:

```
https://unterwaditzer.net/<year>/<slug>
```

In fact, all URLs with `.html` now redirect with  `301 Permanent Redirect` to the “cleaned up” version! That’s why navigating my blog was still working fine, as literally every click on the page was being redirected to the “cleaned up” URL.

Now this is probably closer to the URL format I would start out with today if I had to start a new blog. But Cloudflare’s redirect is permanent and has been public for a few weeks, therefore all Google search results were pointing to the cleaned up URLs. If I wanted to move to a different static site host, I would have to install additional redirects so that none of those links break, just to clean up a mess I didn’t cause.

It turns out, however, that GitHub Pages does something similar, just in a slightly more conservative way: If you request `/<year>/<slug>`, it will serve up `/<year>/<slug>.html` just as if you requested it directly. However, GitHub does not issue any permanent redirects, so it does not lock me into anything at all.

This made it a rather easy decision for me to switch back to GitHub pages. Together with adding `<link rel="canonical" ...>` to all my subpages, no links are broken and the Google search results should eventually self-correct.

I can only assume that the way that Cloudflare justifies this sort of URL rewriting is through arguments similar to the ones found in [Cool URIs don’t change](https://www.w3.org/Provider/Style/URI).

However I think it would be a gross misinterpretation of that article if your takeaway is to plainly remove `.html` from all URLs and issue permanent redirects. If your URL prettification happens in a way that can easily break when moving between static site hosts, you have not made URLs more stable, you just made them prettier. In fact, Cloudflare Pages now made my URLs more brittle and less cool, because they now not only depend on the choices made by my static site generator, but also on my choice of static site host.

This blog will continue to serve cool-but-ugly URLs. If I ever attempt to make them prettier, I will do so with intent, and not on accident. And probably as part of static site generation, not in the routing layer of a random cloud service.
