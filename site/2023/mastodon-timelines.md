Alternative timelines in Mastodon
=================================

<time id=post-date>2023-11-07</time>

Many words have been spilled over the problems with “algorithmic” timelines. [Most of those words come from Cory Doctorow](https://pluralistic.net/tag/algorithms-exposed/) (subjectively speaking, I haven’t counted).

This post is about the opposite extreme: Mastodon’s chronological timeline, which just shows you posts in the order they were created, but comes with some UX issues on its own. The same problems apply to other social media with chronological timelines though, and in my experience has just as well applied to Twitter in the past when chronological timelines were still the default way to use it.

I encountered the following problems with Mastodon:

- Chronological sorting makes it hard to catch up with posts across timezones. If you log onto Mastodon at the same time every day, you mostly get to see posts from people in your timezone or whoever happens to post at that time. If anybody posts while you are asleep, you are unlikely to see it. This is bad if your social circle is distributed across timezones, and probably irrelevant if it isn’t.
- In order to work around this issue (and to kind of “game” the algorithm), people boost (=retweet) their own posts a few times per day. This is very annoying if you are a heavy lurker and are seeing the same post pop up on your timeline multiple times.
- Chronological sorting strongly favors active posters over inactive ones, with no regard over whether one poster has a greater signal/noise ration than the other. This is really noticeable if you try to follow a few friends who post about once per day, and then the automatic feed of a major newssite that posts every hour.
- This one is specific to Mastodon: When a post becomes popular, you see boosts of the same post multiple times on your own timeline.

Those issues are exarcerbated as Mastodon strongly incentivizes following a lot of accounts if you are on a smaller instance.

## RSS-style interfaces

I don’t have these kinds of problems in my RSS feed reader. I do have to do a bit of curation, but because every content creator is their own tab in the sidebar, high-frequency posters do not drown out low-frequency posters. You can just follow Mastodon accounts in your feed reader anyway, and I do that for some whose content I really do not want to miss, even though I already have a Mastodon account.

There is also a Mastodon client that looks like an RSS reader, but I forgot the name.

## Lists

Mastodon allows you to take control over this mess with lists. The basic idea is that you pick a subset of the accounts you follow, add them to a list, and now you have a separate “feed” for those accounts that mostly works the same as your main timeline, except it shows posts from only those accounts. Now you can:

1. stuff all your friends into a list, so you can check that list when browsing Mastodon and not miss any posts from them.
2. stuff all the powerusers and high-frequency posters into a list, as a way to remove them from your home timeline (there’s a setting to remove list members from the main timeline in, I think, version 4.2.0 of Mastodon)

In theory this sounds great, but it doesn’t change much about the default experience. As a new user with no pre-existing social graph, after I have put in effort to solve discoverability problem (”how do I get stuff into my home feed?”), I now have to put in extra effort to curate this experience, continuously.

For that reason I never got really into lists, it was simply too much effort to curate them. At some point I created a list of all my mutuals (people who I follow and follow me back), and that was really it.

## Digests

[mastodon-digest](https://github.com/hodgesmr/mastodon_digest) is a Python script that attempts to summarize your timeline, and present the most popular posts from your timeline (by some metric) as a kind of newsletter. There are various spinoffs of this such as [fediview](https://fediview.com/), but from what I can tell, all of them can be summarized as separate client applications that do not integrate at all with existing desktop and mobile clients.

Mastodon’s Explore tab does integrate with clients, but the problem it attempts to solve is one of discovering new posts and people you do *not* follow. It’s not personalized to who you follow, and rather aggregates the most popular posts on your server.

## Boost deduplication

Mastodon does actually make attempts to solve the problem of “too many boosts of the same post”. Specifically, a boost will be hidden from the timeline if there was already a boost of the same post in the last 40 items of the home timeline. The problem still exists though, and [I made my own attempt to fix it](https://github.com/mastodon/mastodon/pull/22946) that unfortunately didn’t go anywhere.

The problem with just fixing this behavior in isolation is that aggressively deduplicating boosts can lead to an effect where viral (or generally, interesting) content gets depromoted so much that the overall experience just becomes more boring. I noticed this with my own PR (and a predecessor of it) as well: There were viral posts everybody was subtweeting that I never got to see, and I think it is because I patched in more aggressive noise reduction without solving discoverability first.

Some sort of combination of `mastodon-digest` (or some other solution to the same problem) together with more sophisticated boost deduplication might work well.

## Lists, but automated

At some point I got tired of manually curating my “mutuals” list. So I wrote [mastodon-list-bot](https://github.com/untitaker/mastodon-list-bot), which is basically just a script that, on a daily basis, updates lists based on some hardcoded criteria. I now have three lists:

- A list of all my mutuals
- A list of low-frequency posters (1 day without posting)
- A list of ultra-low-frequency posters (3 days without posting)

I have all of those lists configured as tabs in [Tusky](https://tusky.app/). Switching back and forth between them I notice that especially the latter two lists contain people I have not read from in months.

However, this approach has limitations too. The list bot can only make decisions on a per-account basis, and in order to not overwhelm the API, it cannot make them in realtime. This limits the amount of interesting programmatic lists one can create.

I would like to have something like [fediview](https://fediview.com/) but without the extra hassle of having to go to a separate website to read content. Ideally in whichever Mastodon client I already use, or alternatively in my email inbox or RSS reader, but certainly not on an entirely separate website I have to regularly visit.

## Lists, but as a vehicle for algorithmic timelines?

If there was an API with which Mastodon apps could insert arbitrary posts into a list (instead of just adding and removing accounts), people could experiment with algorithmic timelines in Mastodon that integrate into all clients that support lists, without binding up more resources from the core team, and could iterate on them without the extremely long update cycles that most Mastodon servers have.

This sounds resource-intensive for server operators, but for most kinds of low-frequency feeds, one could probably get away with a very strict rate limit per user. Also this new API would likely only write to Redis, not Postgres.
