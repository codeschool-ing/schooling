---
title: Methods: the request's verb
---

Every HTTP request starts with a verb stating the intent. The ones you always meet:

- `GET` — give me. It must not change anything on the server.
- `POST` — take this, and create or process something.
- `PUT` — replace the resource with this.
- `PATCH` — change only these fields.
- `DELETE` — remove it.

The promise that `GET` changes nothing is not a formality. Browsers, proxies and search engines repeat `GET` freely — they prefetch links, revalidate caches, crawl pages. An application that deleted a record via `GET` would be emptied by Google's own crawler, and it has happened to serious companies.
