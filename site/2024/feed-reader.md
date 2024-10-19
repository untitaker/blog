A modern feed reader
====================

<time id=post-date>2024-10-18</time>

I used to operate a public [Nitter](https://github.com/zedeus/nitter) instance for half of 2023. Nitter is a public proxy of Twitter, which gives a stripped-down view of Twitter in spite of whatever strange changes are being made there.

A big problem were (and are) scrapers. RSS feeds were crucial to make Nitter an attractive target for them, because Nitter's feeds are complete and actually useful. The scraping in turn caused issues for regular users, as it competes with them for API quota and server resources. [Even for regular blogs, the volume of feed readers can become a problem](https://rachelbythebay.com/w/2024/06/28/fsr/).

Eventually, most of the Nitter network of public instances shut down due to a variety of reasons, and the few that remain don't have RSS feeds, leaving everybody miserable.

Recently, a blogpost lamented [Cloudflare's interference with feed readers](https://openrss.org/blog/using-cloudflare-on-your-website-could-be-blocking-rss-users). What I found more interesting is the commentary around it on HackerNews and lobste.rs. People are unhappy that:

* Sites don't care about the quality of their RSS feeds
* Sites don't display the full content in their RSS feeds
* Sites sometimes don't even provide RSS feeds

This is the same commentary as 10+ years ago. So given that sites haven't meaningfully changed in that timeframe, what can you do about it? I think feed readers need to adapt to this reality, and find other ways to achieve the same outcome.

Ignore the protocol for a second. To me, the purpose of a feed reader is to centralize content consumption,  for putting independent websites on equal footing with other platforms that are their own distribution (and syndication) network. Both taking away power from platforms and giving power to smaller creators. RSS works fine for small blogs. But that's not enough for most people to consider feed readers as a way to consume content, when they can simply rely on centralized platforms instead, forcing independent creators to [post to social media anyway](https://www.citationneeded.news/posse/).

Most SaaS feed readers have realized that plain RSS doesn't work to achieve that purpose, and adapted accordingly. A bunch of them now integrate with all kinds of social media APIs to syndicate content by other means than RSS, and offer website scraping features on their paid plans.

For self-hosted feed readers, I have no idea how they can adapt. Right now you have to rely on things like [rsshub](https://docs.rsshub.app/en/) to turn them back into the universal content reader that they used to be.
