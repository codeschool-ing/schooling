---
title: The same ideas at a commercial CDN
version: 1
---

Cloudflare, Fastly, Amazon CloudFront, Akamai, Bunny and the rest each have their own dashboard and
their own names, and underneath they are the edge of this lesson repeated in hundreds of cities. **None
of the commands below was run for this course**: they need an account, a real domain and, for most, a
card. They are here so that you recognise each idea when you meet it.

| this lesson | at a commercial CDN |
|---|---|
| Varnish on port 6081 | the CDN's edges, reached by pointing the site's DNS at the CDN, usually with a `CNAME` |
| Nginx on 127.0.0.1:8080 | your origin; ideally it accepts requests from the CDN's addresses only |
| `X-Cache: HIT` / `MISS` | `CF-Cache-Status` at Cloudflare, `X-Cache` at CloudFront and Fastly |
| `Age` | the same header, everywhere |
| removing `utm_` from the key | "cache key" or "query string" settings |
| `PURGE` one URL | a purge API call, or a button |
| `BAN` by `Surrogate-Key` | purge by surrogate key (Fastly) or cache tag (Cloudflare, Akamai) |
| `beresp.grace` | "serve stale" or `stale-if-error` support |

**TLS ends at the edge.** The visitor's HTTPS connection is to the CDN, which holds a certificate for
your domain, often one it obtained itself through ACME (lesson 3), and opens a second connection to the
origin. That second connection should be HTTPS too, with the origin's certificate checked; a CDN set to
"flexible" or unverified TLS to the origin encrypts only half the path, and the half it leaves plain is
the one an attacker on the origin's network would choose.

**A purge is an API call with a key.** A typical one, at Cloudflare, looks like this (not run here):

```sh
curl -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/purge_cache" \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{"tags": ["book-2", "listing"]}'
```

The token in that header can empty the cache of the whole site, which turns every visitor's request
into a request to the origin at once. Treat it like a password to the origin's capacity: scoped to
purging only, kept out of the repository, and rotated when somebody leaves.

**And the origin's address becomes a secret worth keeping.** If anybody can reach the origin directly,
they can go around the edge, its cache and its protections. Restricting the origin's firewall to the
CDN's published address ranges, or requiring a header only the CDN sends, closes that door; this
lesson's origin listening on `127.0.0.1` is the same idea at the scale of one machine.
