---
title: The only check that counts is on the server
version: 1
---

**Access control** answers one question on every request: *may this person do this, to this?* It
is the most common serious flaw in web applications. OWASP's Top 10 put **broken access control**
first in 2021, ahead of injection, and it stayed there in the 2025 edition. It is rarely a missing
idea: almost every application has a notion of roles. It is a missing line, in one route, that
nobody noticed.

The wrong idea behind most of it is that **what the screen does not show cannot be reached.** The
receptionist's console has no link to clinical notes, so receptionists cannot read clinical notes.
But a link is a convenience for an honest browser. The address it pointed to still exists, and the
server answers whoever asks it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l12-where\" aria-label=\"Three places a check can live, and the requests that cross each. On the left, the browser: the page, which hides the notes link from a receptionist, and the form, which carries a hidden field role=physio. Below it, a terminal sending a request with curl, which never shows the page. Both the browser and the terminal send their requests to the server on the right, where the check reads the name from the session and the role from the server's own table. Every request crosses the server; only the honest browser crosses the page.\"><defs><marker id=\"l12-where-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"150\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">the browser</text><rect x=\"20\" y=\"34\" width=\"260\" height=\"126\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"40\" y=\"50\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"150.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the page: link hidden</text><rect x=\"40\" y=\"104\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"150.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the form: role=physio</text><rect x=\"40\" y=\"196\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"150.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a terminal, a script</text><text x=\"150\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">skips the page entirely</text><text x=\"570\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">the server</text><rect x=\"450\" y=\"60\" width=\"240\" height=\"150\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"570.0\" y=\"115.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">name from the session</text><text x=\"570.0\" y=\"128.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">role from STAFF</text><text x=\"570.0\" y=\"141.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\"></text><text x=\"570.0\" y=\"154.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">every request crosses here</text><path d=\"M280 97 L450 110\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-where-ah-paper-dim)\"></path><path d=\"M260 216 L450 170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-where-ah-paper-dim)\"></path></svg>", "caption": "The page and the form only ever see the honest browser. The server sees every request, which is why the check lives there."}
```

Three places a check can be put, and what each one stops:

- **In the page**, by hiding a link or a button. It stops nobody who types the address, follows a
  bookmark, or sends the request from a terminal. Hiding is still worth doing: a screen that offers
  only what the person may do is a better screen. **It is design, not control.**
- **In the request**, by trusting something the client sent: a hidden form field `role=physio`, a
  cookie `is_admin=1`, a header, a parameter in the address. Everything in a request is chosen by
  whoever sends it. A browser's developer tools edit a hidden field in two clicks.
- **On the server, from what the server knows.** The session says who is asking; the server's own
  table says what that person's role is; the route says what role it needs. **This is the only check
  every request has to cross**, whatever sent it.

### Three rules

The rest of this lesson is these three, in code and in tests.

1. **Check on the server, on every request.** Not once at sign-in, not in the page, not in
   JavaScript. The server decides each time.
2. **Take the role from the server.** The session carries an identity, and the server looks up what
   that identity may do. A role written into the request, or into a cookie the client can edit, is
   a claim, not a fact.
3. **Deny by default.** A route that says nothing about who may use it is refused, not open. The
   failure of access control is almost always a route somebody forgot, and the only defence against
   forgetting is a rule that fails closed and a test that notices.

The patient portal of lesson 1 already met a fourth question, *to this?*: lucia may cancel
bookings, but only her own. That one is lesson 13. This lesson is about roles.
