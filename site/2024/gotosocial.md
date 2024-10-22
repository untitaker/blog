Moving from Mastodon to GoToSocial
==================================

<time id=post-date>2024-10-22</time>

I recently moved my Mastodon instance to GoToSocial, for these reasons:

- Mastodon is resource-intensive for single-user instances. The cost was, and continues to be, less than 5 EUR/month, but in the case of Mastodon it takes a lot of tweaking to get there, due to tradeoffs in its design that only make sense for larger instances (particularly with regard to media retention).
    - Command to keep it under 5 EUR/month for me was to run this + PG vacuum as a cronjob. It’s probably cheaper to use Cloudflare R2 — I used the disk that came with my VPS.
    
    ```jsx
    tootctl media remove -c 1 --days 1 && tootctl media remove -c 1 --prune-profiles --days 1 && tootctl preview_cards remove -c 1 --days 1 && tootctl statuses remove --days 1
    ```
    
    - Because Mastodon is being kinda stupid about it, and rarely refetches stuff, some inactive profiles on your server will lose all their avatars with the above command. That is certainly buggy behavior but hasn’t been a practical issue for me. (Also, with a single-user instance you will be browsing other Mastodon instances directly anyway, instead of viewing their users through your instance)
    - Varnish cache was necessary in front of Mastodon to make it load reasonably fast, adding more complexity next to Sidekiq and Postgres.
    - **Note:** There are some people going around saying stuff like “ActivityPub is inherently inefficient, and that’s why Mastodon is expensive.” Don’t listen to these people. That first part is kinda true but completely misses the mark on what are actual cost-drivers in practice.
- Technical curiosity, and a desire to dabble around in Golang.
- Too many rapid-fire security releases recently, which is actually the main reason this started to become a burden.

## The good

- Setup of GoToSocial 0.17 was very easy. Start a docker container, and you’re done. Database is SQLite.
- UX responsiveness is very good, resource consumption is much lower.

## The bad

- Cannot edit posts. This is fairly painful to me and my current workaround is to use “Delete and Re-draft” a lot.
- There is no web interface, but for me it didn’t matter, as I use Phanpy on desktop and Tusky on mobile (instead of Mastodon’s web interface)
- The import of follows/followers was very janky, more so than between Mastodon instances. Many accounts got stuck in “Follow requested”, and I had to re-follow them manually.
- GoToSocial does not validate any OAuth scopes — every token has full access to my account.
- I’m sure I’ll discover more eventually.

---

Overall, it’s still a win. Looking forward to not have to tune a Rails application for performance anymore.
