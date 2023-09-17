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

<li><a style='color: #d381c3' href="https://github.com/untitaker">GitHub</a></li>
<li><a style='color: #76c7b7' href="https://twitter.com/untitaker">Twitter</a></li>
<li><a style='color: #6fb3d2' href="https://woodland.cafe/@untitaker" rel="me">Mastodon</a></li>
<li><a style='color: #FF5E5E' href="https://cohost.org/untitaker">Cohost</a></li>
<li><a href="mailto:markus@unterwaditzer.net">Email</a></li>

</ul>

## Articles (<a href="/feed.xml">Atom Feed</a>)

<ul id="blog-index" class="timeline"></ul>

## Projects

<div class="timeline">

* <time>2014-2018</time> Creator and former maintainer of [vdirsyncer](http://vdirsyncer.pimutils.org/en/stable/)

* <time>2013-2017</time> Former [maintainer](https://palletsprojects.com/people/) of [Flask](https://palletsprojects.com/p/flask/)

* (For other, smaller projects, see my [GitHub](https://github.com/untitaker/))

</div>

## Work

<div class="timeline">

* <time>2018-now</time> [Sentry.io](https://sentry.io/)

* <time>2017-2018</time> [Runtastic](https://www.runtastic.com/)

</div>
