---
title: Three kinds of local data, and only one of them is a cache
version: 1
---

**Not everything an app keeps on the device is a cache, and treating it all as one is how data
gets lost.** The word is used loosely for anything stored locally, and that looseness is the bug.
A cache is a copy of something the server still has, kept to save a request. The test is short:
if this file vanished tonight, would anything be lost, or only fetched again?

That question sorts the planner's data into three kinds.

| kind | what it is in the planner | if it vanishes | where it lives |
|---|---|---|---|
| **source of truth** | a session typed on the train and not yet sent | lost for good | the database, in the backed-up part of the sandbox |
| **pinned for offline** | the notes of a course the person marked "keep offline" | the person finds it missing in the tunnel they pinned it for | the database or `files/`, never evicted by size |
| **cache** | the catalogue, a course's cover picture | one request, the next time there is a network | `cache/` on Android, `Library/Caches/` on iOS |

**The first kind is not a cache even when the server will have it later.** Until the outbox of
lesson 8 has delivered a session, the phone holds the only copy. Lessons 7 to 12 are about that
kind, and none of what follows applies to it: nothing here may expire it, evict it or let the
system clear it.

**The second kind looks like a cache and is a promise.** The person asked for those notes to be
there offline, so evicting them to make room for a cover picture breaks the promise silently. A
pinned item is kept until the person unpins it, and its size is shown to them, because they are the
one who can decide it is too much. Lesson 18 counts the disk it takes.

**The third kind is the only one this lesson's rules are for.** A cache answers three questions,
one section each: how long a copy may be shown before it is checked (expiry, next section), how
large the whole cache may grow (size limits), and what happens when the system deletes it without
asking (the last section). A cache that answers all three can disappear at any moment and the
person notices nothing but a picture that loads a second later.

## The three platforms

All three offer an HTTP cache that follows the server's headers, and a place to put your own:

- **Android**: OkHttp's `Cache`, given a directory under `cacheDir` and a size in bytes; Coil and
  Glide keep their own memory and disk caches for images.
- **iOS**: `URLCache`, which `URLSession` uses by default, with a memory and a disk capacity;
  Kingfisher and SDWebImage for images.
- **React Native**: `fetch` goes through the platform's own HTTP stack, so the cache above applies;
  `expo-image` keeps a memory and a disk cache, chosen per image with `cachePolicy`.

*Those are named from each library's documentation, and no app using them was run for this
course.* The rest of the lesson builds the same machinery in Node, where you can watch it decide.
