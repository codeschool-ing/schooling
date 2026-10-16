---
title: Behaviours, the cache key, and forgetting a file
version: 1
---

**A cache behaviour is a path pattern and the rules for what matches it**: which origin answers,
whether the answer is kept, for how long, and what a request has to have in common with an earlier
one to be answered by the same copy. The distribution of the previous section has two. The wrong
picture is that CloudFront caches "the file". It caches **one copy per cache key**, and the cache
key is something you decide.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" data-fig=\"l23-behaviours\" aria-label=\"One distribution, two behaviours. A viewer's request reaches the distribution, which tries its path patterns in order. Requests for /static/* use the CachingOptimized policy, keyed on the path and kept for a day by default, and go to the origin assets, the bucket shop-assets, which only the distribution can read through Origin Access Control and the bucket policy. Everything else matches the default behaviour, uses CachingDisabled with the AllViewer origin request policy, and goes to the origin web, the load balancer shop-web, with the viewer's cookies.\"><defs><marker id=\"l23-behaviours-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l23-behaviours-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"125.0\" width=\"110.0\" height=\"50.0\" rx=\"25\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"75.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a viewer</text><path d=\"M132.0 150.0 L176.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l23-behaviours-af-ah-paper-dim)\"></path><rect x=\"180.0\" y=\"30.0\" width=\"300.0\" height=\"250.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"330.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the distribution</text><rect x=\"196.0\" y=\"70.0\" width=\"268.0\" height=\"90.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"212.0\" y=\"90.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">/static/*</text><text x=\"212.0\" y=\"112.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">CachingOptimized</text><text x=\"212.0\" y=\"130.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">key: the path; kept a day by default</text><text x=\"212.0\" y=\"147.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">compressed</text><rect x=\"196.0\" y=\"172.0\" width=\"268.0\" height=\"92.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"212.0\" y=\"192.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">default (everything else)</text><text x=\"212.0\" y=\"214.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">CachingDisabled</text><text x=\"212.0\" y=\"232.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">AllViewer</text><text x=\"212.0\" y=\"250.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">nothing kept; cookies forwarded</text><rect x=\"560.0\" y=\"80.0\" width=\"140.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop-assets</text><text x=\"630.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">bucket, private</text><text x=\"630.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">read only via OAC</text><rect x=\"560.0\" y=\"182.0\" width=\"140.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop-web</text><text x=\"630.0\" y=\"224.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">load balancer</text><path d=\"M466.0 115.0 L556.0 115.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l23-behaviours-af-ah-amber)\"></path><text x=\"511.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">assets</text><path d=\"M466.0 217.0 L556.0 217.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l23-behaviours-af-ah-paper-dim)\"></path><text x=\"511.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">web</text><text x=\"360.0\" y=\"304.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">a path chooses the behaviour; the behaviour chooses the origin and the cache</text></svg>", "caption": "The images are cached once for everybody; the pages pass through untouched."}
```

## The cache key

**The cache key is the list of things that must match for a stored copy to answer a new request.**
By default it is the distribution and the path, so every viewer asking for `/static/logo.png` gets
the same copy. Add the `Accept-Language` header to the key and there are as many copies of the logo
as there are languages people's browsers send; add a cookie that carries a session id and there is
one copy per customer, which is no cache at all. **Everything in the key divides the hit rate**, so
only what really changes the answer belongs there.

What is sent to the origin is a separate question. An **origin request policy** forwards headers,
cookies and query strings to the origin **without** putting them in the key, which is how the API
still receives the customer's cookies while the images are shared by everybody.

Both are named in each behaviour, by policy id, and the three ids in `distribution.json` are AWS's
**managed policies**, published with fixed ids so that anybody can use them:

| id | managed policy | what it does |
|---|---|---|
| `658327ea-f89d-4fab-a63d-7e88639e58f6` | `CachingOptimized` (cache) | key on the path only; keep for a day by default, up to a year if the origin says so; compress |
| `4135ea2d-6df8-44a3-9df3-4b5a84be39ad` | `CachingDisabled` (cache) | keep nothing: every request goes to the origin |
| `216adef6-5c7f-47e4-b989-5492eafa07d3` | `AllViewer` (origin request) | forward every header, cookie and query string the viewer sent |

So `/static/*` is cached for everybody, and the pages and the API pass straight through to the load
balancer with the viewer's cookies, which is what a logged-in basket needs. Ask moto for the managed
policies and it has none to give:

```
ana@laptop:~/aws$ aws cloudfront list-cache-policies --type managed

aws: [ERROR]: An error occurred (404) when calling the ListCachePolicies operation: Not Found
```

**moto 5.2.3 does not implement cache policies**, so it took the ids in the configuration as text and
checked nothing about them; the table is from AWS's documentation of its managed policies. What it
stored is this:

```
ana@laptop:~/aws$ aws cloudfront get-distribution-config --id $id --query "DistributionConfig.CacheBehaviors.Items[].[PathPattern,TargetOriginId,CachePolicyId,Compress]" --output text
/static/*	assets	658327ea-f89d-4fab-a63d-7e88639e58f6	True
```

## TTLs, and who decides them

**A TTL here is how long an edge may keep a copy before it asks the origin again**, and it is decided
by two parties. The origin sends `Cache-Control: max-age=…` with each file; the cache policy sets a
minimum, a default for files that say nothing, and a maximum. For `CachingOptimized` those are one
second, a day and a year, so a file the origin marks `max-age=31536000` is kept a year, a file with
no header is kept a day, and an origin cannot make CloudFront keep anything for less than a second
under this policy.

When a copy expires the edge does not always download the file again: it asks the origin whether
the file changed, and an unchanged file costs a small answer instead of the whole thing. That is
also why an origin that sends no `ETag` or `Last-Modified` header is more expensive to sit behind
than one that does.

## Invalidation: telling the edges to forget

The shop changes `shop.css` and the edges still hold the old one for up to a day. **An invalidation
removes paths from every edge cache**, so that the next request for them goes to the origin:

```
ana@laptop:~/aws$ aws cloudfront create-invalidation --distribution-id $id --paths "/static/css/shop.css" "/static/js/*"
{
    "Location": "https://cloudfront.amazonaws.com/2020-05-31/distribution/DOF70T4DOCRTU/invalidation/OM16QPJ5DNZ5H",
    "Invalidation": {
        "Id": "OM16QPJ5DNZ5H",
        "Status": "COMPLETED",
        "CreateTime": "2026-10-16T16:35:14.883852+00:00",
        "InvalidationBatch": {
            "Paths": {
                "Quantity": 2,
                "Items": [
                    "/static/css/shop.css",
                    "/static/js/*"
                ]
            },
            "CallerReference": "cli-1792168514-28452"
        }
    }
}
```

```
ana@laptop:~/aws$ aws cloudfront list-invalidations --distribution-id $id --query "InvalidationList.Items[].[Id,Status]" --output text
OM16QPJ5DNZ5H	COMPLETED
```

**moto answered `COMPLETED` at once**, as it answered `INSYNC` in lesson 21: there are no edges to
clear. Against AWS an invalidation starts `InProgress` and finishes when every edge has dropped the
paths. The `CallerReference` in the answer is one the command line made up from the clock, since the
command was not given one; a script that may retry should pass its own, for the same reason lesson
21's zone did.

The `*` at the end of `/static/js/*` is a wildcard and covers every file under that path. **AWS
counts a wildcard path as one path**, which matters for the price, and it is also how a careless
`/*` empties the whole distribution's cache and sends every viewer's next request to the origin at
once.

## Why a new name beats an invalidation

**An invalidation clears CloudFront's caches, and only those.** The browser that loaded the old
`shop.css` yesterday keeps its own copy for as long as the header told it to, and so does any proxy
on the way; CloudFront has no way to reach either. And for the minutes the invalidation takes,
some edges serve the new file and some the old one, to pages that may expect the other.

The habit that avoids all of that is to **put the version in the file's name**: the build writes
`shop.3f9a2c.css`, the page links to that name, and the next change produces `shop.81d0e7.css`.

- **Nothing has to be forgotten**, because a new name has never been cached anywhere.
- **The old name keeps working** for every page that still links to it, so a visitor halfway through
  a deployment never gets a stylesheet that does not match the page.
- **The file can be kept forever**, `Cache-Control: max-age=31536000, immutable`, by CloudFront and
  by every browser, which is the best hit rate there is.
- **It costs nothing**, where invalidation paths past the monthly allowance are billed.

So the pages, which keep their names, are the ones not cached for long, and everything under
`/static/` gets a versioned name and a year. Invalidation stays for the emergency: a file that
should never have been published at all.
