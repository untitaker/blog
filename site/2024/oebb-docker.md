ÖBB WiFi issues: cannot connect to railnet.oebb.at
==================================================

<time id=post-date>2024-04-09</time>

This is a note for all Austrian readers who want to connect to the Austrian
railways' WiFi but find themselves unable to do so from their Linux laptops.
It's an unusual kind of post but I haven't found a solution to this that ranks
well on Google, so this is my attempt.

If you get any of the following error messages trying to connect to
`railnet.oebb.at`:

* cURL: `Failed to connect to XXX port 80 after 3073 ms: Couldn't connect to server`
* Chrome: `This site can't be reached [...] ERR_ADDRESS_UNREACHABLE`
* Firefox: `Unable to connect`

Check what that host resolves to:

```
$ dig +short railnet.oebb.at
172.19.5.2
```

Then check your routes:

```
$ ip route
[...]
172.19.0.0/16 dev br-eade1894744d proto kernel scope link src 172.19.0.1
[...]
```

This route was most likely added by Docker and causes the
connection to `railnet.oebb.at` to never leave your
machine. You can try to get rid of it using `docker
network prune`, or by deleting the route directly:

```
sudo ip route del 172.19.0.0/16 
```

Either one will work in the short-term to get past the captive portal, but the
latter likely breaks one of your docker container networks.
