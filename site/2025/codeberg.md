Moving from GitHub to Codeberg, for lazy people
===============================================

<time id=post-date>2025-09-06</time>

I've just started to migrate some repositories from GitHub to Codeberg. I've
wanted to do this for a long time but have stalled on it because I perceived
Codeberg as not being ready and the migration process as being a lot of
(boring) work.

It turns out that is only partially true and wildly depends on your project. If
you're in a similar position as me, hopefully these notes serve as motivation
and starting point. These solutions are not what I might stick around with
long-term, but aimed at what I think is *easiest to get started with* when
migrating from GitHub.

First, there's the migration of issues, pull requests and releases along with
their artifacts. This is actually the easiest part since Codeberg offers
repository import from GitHub that just works, and all these features have a UI
nearly identical to GitHub's. The import preserves issue numbers, labels,
authorship. The user experience is very much a step above the extremely awkward
hacks that people use to import from other issue trackers into GitHub.

If you're using GitHub Pages you can use
[codeberg.page](https://codeberg.page/). There's a warning about it not
offering any uptime SLO, but I haven't noticed any downtime at all, and for now
it's fine. You push your HTML to a branch, very much like the old GitHub Pages.

The by far nastiest part is CI. GitHub has done an excellent job luring people
in with free macOS runners and infinite capacity for public repos [^1]. You
will have to give up on both of those things. I recommend looking into
cross-compilation for your programming language, and to [self-host a runner for
Forgejo Actions](https://docs.codeberg.org/ci/actions/), to solve those
problems respectively.

Why [Forgejo Actions](https://forgejo.org/docs/latest/user/actions/reference/)
and not Woodpecker CI, [isn't Woodpecker on Codeberg more
stable?](https://docs.codeberg.org/ci/) Yes, absolutely, in fact [the
documentation for Forgejo Actions on Codeberg is out of date right
now](https://codeberg.org/Codeberg/Documentation/pulls/667), but Forgejo
Actions will just feel way more familiar coming from GitHub Actions. The UI and
YAML syntax is almost identical, and the existing actions ecosystem mostly
works as-is on Codeberg. For example, where my GitHub Actions workflow would
say `uses: dtolnay/rust-toolchain`, my Forgejo Actions workflow would just
change to `uses: https://github.com/dtolnay/rust-toolchain`.

If you absolutely need macOS runners I'd recommend sticking with GitHub Actions
on the GitHub repository, mirroring all commits from Codeberg to GitHub and
using Forgejo Actions to poll the GitHub API and sync the CI status back to
Codeberg. I haven't tried this one yet, but I have tried some other CI
providers offering macOS builds and I don't think they're easier or cleaner to
integrate into Codeberg than GitHub Actions.

Finally, what to do with the old repo on GitHub? I've just updated the README
and archived the repo.

You could tell Codeberg to push new commits to GitHub, but this allows users to
still file PRs and comment on issues and commits [^2]. Some folks have dealt with
this by disabling issues on the GitHub repo, but that is a really destructive
action as it will 404 all issues, and pull requests cannot be disabled. Some
repos like `libvirt/libvirt` have written a GitHub Action that automatically
closes all pull requests.

[^1]: This itself has some terrible consequences for self-hosting and the broader software ecosystem, as folks have no incentive to optimize their builds or how often they download a release tarball from your website.

[^2]: You might still want to maintain a read-only mirror during a transitionary period, or to keep using GitHub pages and GitHub Actions.
