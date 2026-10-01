---
title: "Object storage: buckets, keys and whole objects"
version: 1
---

The wrong picture here is a very large network drive. An object store has no drive, no filesystem
and, whatever the console draws, no folders. It has three nouns.

A **bucket** is a container with a name, in one region, with its own settings: who may read it,
whether old versions are kept, which lifecycle rules apply. S3 bucket names are shared across every
AWS account, so a new bucket needs a name no other account holds, and a plain word like `photos`
will not be free.

An **object** is a sequence of bytes plus metadata: a content type, a size, a checksum called the
ETag, timestamps, and any name–value pairs you attach. One S3 object can be up to 5 TB.

A **key** is the object's name inside the bucket, any string of up to 1,024 bytes.
`photos/2026/cat.jpg` is one key. Its slashes are characters like its letters, and the namespace is
flat: there is no directory `photos` holding a directory `2026`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"A bucket called ana-uploads holding five objects, each a whole key: photos/2025/sea.jpg, photos/2026/cat.jpg, photos/2026/dog.jpg, reports/2026-q3.txt and index.html. A listing that asks the bucket to split the keys at the first slash returns two prefixes, photos/ standing for three keys and reports/ for one, and one object, index.html. No object is called photos/; the prefix exists only because keys begin with it.\"><defs><marker id=\"bkt-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"320\" height=\"210\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"34\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">bucket</text><text x=\"82.8\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">ana-uploads</text><rect x=\"34\" y=\"66\" width=\"292\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"46\" y=\"79\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">photos/</text><text x=\"92.19999999999999\" y=\"79\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2025/sea.jpg</text><rect x=\"34\" y=\"100\" width=\"292\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"46\" y=\"113\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">photos/</text><text x=\"92.19999999999999\" y=\"113\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2026/cat.jpg</text><rect x=\"34\" y=\"134\" width=\"292\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"46\" y=\"147\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">photos/</text><text x=\"92.19999999999999\" y=\"147\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2026/dog.jpg</text><rect x=\"34\" y=\"168\" width=\"292\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"46\" y=\"181\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">reports/</text><text x=\"98.8\" y=\"181\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2026-q3.txt</text><rect x=\"34\" y=\"202\" width=\"292\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"46\" y=\"215\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">index.html</text><path d=\"M342 135 L418 135\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#bkt-ah)\"></path><text x=\"380\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">delimiter=/</text><rect x=\"420\" y=\"30\" width=\"280\" height=\"210\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"434\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">a listing, split at /</text><rect x=\"434\" y=\"66\" width=\"252\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"446\" y=\"79\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">photos/</text><text x=\"674\" y=\"79\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">prefix, 3 keys</text><rect x=\"434\" y=\"100\" width=\"252\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"446\" y=\"113\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">reports/</text><text x=\"674\" y=\"113\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">prefix, 1 key</text><rect x=\"434\" y=\"134\" width=\"252\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"446\" y=\"147\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">index.html</text><text x=\"674\" y=\"147\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">object</text><text x=\"434\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">No object is called photos/.</text><text x=\"434\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">The prefix exists because keys start with it.</text><text x=\"20\" y=\"258\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Five keys, flat. The slash is a character like any other.</text></svg>", "caption": "What looks like a folder is a prefix the listing groups keys by. Delete the three photos and photos/ is gone too, because nothing was ever there."}
```

What looks like a folder is a **prefix**. A listing can ask for the keys that begin with `photos/`,
and can ask the store to cut each key at the next `/` and report each distinct beginning once, which
is how a console draws a tree. Some consoles have a "create folder" button, and what it creates is
an empty object whose key ends in `/`, so that the tree has something to show before anything is
uploaded.

## Written whole, read whole

**An object is written whole and replaced whole.** There is no append, no writing into the middle,
no truncating. To add a line to a log kept as an object, a program downloads it, adds the line and
uploads the whole thing again under the same key. Large objects are uploaded in parts that the store
joins at the end, and that is still one write of one object. Reading is more flexible: a `GET` can
ask for a byte range, so reading part of an object is cheap, while writing part of one is not
possible.

There is no rename either. The key is the name and the name is not stored anywhere else, so renaming
`reports/q3.txt` means copying the object to a new key and deleting the old one. For a million
objects that is two million requests, and renaming a "folder" is renaming every key under the
prefix. The next section watches it happen.

## The interface is HTTP, and small

| request | what it does |
|---|---|
| `PUT /bucket/key` | stores an object under that key, replacing any object already there |
| `GET /bucket/key` | returns the object, or a byte range of it |
| `HEAD /bucket/key` | returns the metadata without the bytes |
| `DELETE /bucket/key` | removes it |
| `GET /bucket?list-type=2&prefix=…` | lists keys, optionally cut at a delimiter |

Every request is signed with the caller's credentials, and lesson 7 says whose. Every request is a
line on the bill too: the sheet prices `PUT, COPY, POST, LIST` at 0.00700 per 1,000 in `sa-east-1`
and `GET` at 0.00056 per 1,000.

**S3 has been strongly consistent for reads after writes since December 2020.** Once a `PUT` has
returned success, every later `GET` and `LIST` sees the new object, and an overwrite is seen at once.
Before that date an overwrite or a delete could take a while to show, and older articles and
libraries still carry workarounds for it. What consistency does not give is a lock: two programs
writing the same key at the same moment both succeed, and the later write is the one that stays.

**S3 Standard is designed for 99.999999999% durability**, eleven nines, by keeping each object on
devices in at least three availability zones of its region. That is AWS's design figure rather than
a promise in a contract, and three sections on, the lesson separates what it covers from what it does
not.
