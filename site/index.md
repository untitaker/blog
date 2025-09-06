<h1 id="brand">Markus <span id="surname">Unterwaditzer</span> (a.k.a. untitaker)</h1>

<script>
var surnames = [
    "Unterwaditzer",
    "Underwhat'sit",
    "Underwhatever",
    "Underwater",
];
var surnameIndex = 0;
document.getElementById("surname").onclick = function() {
    surnameIndex = (surnameIndex + 1) % surnames.length;
    this.innerText = surnames[surnameIndex];
};
</script>

<style>
    #brand {
        text-align: center;
    }

    .socials {
        list-style: none;
        text-align: center;
        line-height: 2.5em;
    }

    .socials li {
        display: inline;
        padding: 0 8px;
    }
</style>


<ul class=socials>

<li><a class=c-purple href="https://github.com/untitaker">GitHub</a></li>
<li><a class=c-purple href="https://codeberg.org/untitaker">GitHub</a></li>
<li><a class=c-blue href="https://gts.woodland.cafe/@untitaker" rel="me">Mastodon</a></li>
<li><a href="mailto:markus@unterwaditzer.net">Email</a></li>

</ul>

<div class=multi-heading><h2>Posts</h2><a class=c-orange href=/feed.xml>RSS</a></div>

<ul id="blog-index" class="timeline"></ul>

[All posts](/archive)

## Projects

<div class="timeline">

* <time>2014-2018</time> Creator and former maintainer of [vdirsyncer](http://vdirsyncer.pimutils.org/en/stable/)

* <time>2013-2017</time> Former [maintainer](https://palletsprojects.com/people/) of [Flask](https://palletsprojects.com/p/flask/)

[More projects on GitHub](https://github.com/untitaker/)

</div>

## Hosted services and bots

* [Mastodon Bookmark RSS](https://bookmark-rss.woodland.cafe) is a tool to let users on any mastodon instance subscribe to their bookmarks via RSS.
* [RSSHub](https://rsshub.woodland.cafe) for subscribing to other social media platforms via RSS.
* [Mastodon List Bot](https://list-bot.woodland.cafe) for (ab)using Mastodon's list feature to build alternative home feeds.
* [@a11y_link_bot](https://mastodon.social/@a11y_link_bot) Mastodon bot
* [Breezewiki](https://breezewiki.woodland.cafe), a Fandom mirror.
* [Redlib](https://redlib.woodland.cafe), a Reddit mirror.

## Work

<div class="timeline">

* <time>2018-now</time> [Sentry.io](https://sentry.io/)

* <time>2017-2018</time> [Runtastic](https://www.runtastic.com/)

</div>
