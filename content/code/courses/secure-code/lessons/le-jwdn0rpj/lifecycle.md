---
title: What a session is, and its four moments
version: 1
---

HTTP has no memory. Each request arrives on its own, and nothing in the protocol says that the
request for `/bookings` comes from the same person who typed a password a minute ago. A **session**
is the memory an application adds: at sign-in the server issues a **session id**, the browser sends
it back in a cookie with every request, and the server looks it up to learn who is asking.

That makes the id worth exactly as much as the password. **Whoever presents the id is the patient,
and no password is asked again.** A session flaw is therefore an authentication flaw that skips the
password: the attacker never needs to know it.

The common wrong idea is that sessions are the framework's problem. The framework issues a cookie,
the cookie works, the patient stays signed in, and every manual test passes. What the framework
cannot decide for you is when the id must change, when it must stop working, and what "sign out"
means on the server. Those are decisions about your application, and each one is a line of code.

### Four moments

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l10-life\" aria-label=\"The four moments of a session, left to right. Born: on the first visit the server issues a random id and keeps a row for it; the browser keeps the id in a cookie marked HttpOnly, Secure and SameSite. Rotated: at sign-in the old id is deleted and a new one is issued. Expired: on every request the server checks the idle limit of 15 minutes and the absolute limit of 8 hours. Ended: sign-out, a password change or the team deletes the row on the server. Underneath, a note: the cookie carries only the id, and the server holds everything else.\"><defs><marker id=\"l10-life-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"94\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">born</text><rect x=\"20\" y=\"44\" width=\"148\" height=\"96\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"94.0\" y=\"79.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">random id, 256 bits</text><text x=\"94.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">cookie: HttpOnly,</text><text x=\"94.0\" y=\"104.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Secure, SameSite</text><path d=\"M168 92 L196 92\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-life-ah-paper-dim)\"></path><text x=\"270\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">rotated</text><rect x=\"196\" y=\"44\" width=\"148\" height=\"96\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"270.0\" y=\"79.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">at sign-in:</text><text x=\"270.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">old id deleted,</text><text x=\"270.0\" y=\"104.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">new id issued</text><path d=\"M344 92 L372 92\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-life-ah-paper-dim)\"></path><text x=\"446\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">expired</text><rect x=\"372\" y=\"44\" width=\"148\" height=\"96\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"446.0\" y=\"79.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">every request checks</text><text x=\"446.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">idle: 15 min</text><text x=\"446.0\" y=\"104.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">absolute: 8 h</text><path d=\"M520 92 L548 92\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-life-ah-paper-dim)\"></path><text x=\"622\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">ended</text><rect x=\"548\" y=\"44\" width=\"148\" height=\"96\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"622.0\" y=\"79.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">sign-out, password</text><text x=\"622.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">change, the team:</text><text x=\"622.0\" y=\"104.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">row deleted on server</text><rect x=\"20\" y=\"168\" width=\"676\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"358\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">the cookie carries only the id; the server holds everything else</text></svg>", "caption": "Four moments, each with one rule. Every rule is checked on the server, where a copied id cannot argue."}
```

Every session goes through four moments, and each has one rule.

1. **Born.** The id comes from a cryptographically secure random generator, with at least 128 bits
   of randomness, so nobody can guess or compute another person's. The cookie that carries it is
   marked `HttpOnly`, `Secure` and `SameSite`.
2. **Rotated.** When the patient signs in, or gains any new privilege, the id she had before is
   thrown away and a new one is issued. An id that existed before sign-in may have been seen by
   somebody else.
3. **Expired.** An id stops working after a period with no requests (the **idle limit**) and after
   a fixed time however busy it is (the **absolute limit**). A session left open on a clinic's
   reception computer must end on its own.
4. **Ended.** Signing out deletes the session **on the server**. Deleting the cookie in the browser
   is not enough: a copy of the id elsewhere still works for as long as the server accepts it.

### Where the session lives

Flask's built-in `session` keeps everything in the cookie itself, signed with `secret_key` so it
cannot be altered. That is convenient and it has one consequence that matters here: **a signed
cookie cannot be revoked.** The server keeps no list of the cookies it issued, so it cannot refuse
one that is still validly signed, short of changing the key and signing everybody out at once. Lesson 1's portal used it because that lesson was about
something else.

This lesson's portal keeps sessions **on the server**: the cookie carries only a random id, and a
table on the server maps each id to the patient, when the session was created and when it was last
used. Ending a session is then deleting a row. In production the table is a database or a store
such as Redis, and extensions such as Flask-Session do the bookkeeping; here it is a dictionary, so
the whole program fits on the page and every rule is a line you can read.
