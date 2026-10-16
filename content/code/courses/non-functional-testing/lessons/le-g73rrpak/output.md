---
title: Output encoding, and a policy behind it
version: 1
---

Cross-site scripting, XSS, is injection into the page. Text a user supplied is written into HTML
without being encoded, and the browser reads part of it as markup or script. A booking holder's
name, a search term echoed back, a review: anything a page shows that it did not write itself.
**The defence is encoding on the way out, for the context the text lands in**, and a
Content-Security-Policy header as a second layer for the day the first one is missed.

The probe is a marker that is markup but does nothing: `<em>nft-probe</em>`. If it comes back as
`<em>`, the page sent it as markup and the encoding is missing. If it comes back as `&lt;em&gt;`, the
browser will show the angle brackets as text.

```
ana@nft:~/boxoffice$ curl -s -X POST localhost:8001/bookings -H "Authorization: Bearer $(cat ~/ana.token)" -d '{"show_id": 991, "seat": 3, "holder": "<em>nft-probe</em>"}'
{"id": 2}
ana@nft:~/boxoffice$ curl -s -b ~/ana.jar localhost:8001/account | grep 'nft-probe'
<li>Show 991, seat 3, for &lt;em&gt;nft-probe&lt;/em&gt;
ana@nft:~/boxoffice$ curl -s -b ~/ana.jar 'localhost:8001/account?q=nft%22probe' | grep 'name="q"'
<form action="/account"><label>Search <input name="q" value="nft&quot;probe"></label>
ana@nft:~/boxoffice$ curl -s -b ~/ana.jar -o /dev/null -D - localhost:8001/account | grep -i 'content-security\|nosniff'
X-Content-Type-Options: nosniff
Content-Security-Policy: default-src 'none'; form-action 'self'; frame-ancestors 'none'
```

Four answers, four checks:

- **The holder's name** came back as `&lt;em&gt;nft-probe&lt;/em&gt;`. `account.py` passes it
  through `html.escape` before writing it into the list.
- **The search term inside an attribute** came back as `value="nft&quot;probe"`. This is the context
  people forget: inside `value="…"` the dangerous character is the double quote, because it would end
  the attribute. `html.escape` encodes it by default; a hand-written escape that only handled `<` and
  `>` would pass the first check and fail this one.
- **`Content-Security-Policy: default-src 'none'`** tells the browser to run no script and load
  nothing from anywhere, on a page that needs neither. Even an encoding mistake could then not run
  anything. A page that does load scripts lists where from, and a tester checks the policy names no
  more than it needs.
- **`X-Content-Type-Options: nosniff`** stops the browser guessing a type different from the one the
  server declared, which matters for the uploads of the last section.

**Encoding belongs at the output, not the input.** Stripping angle brackets when a booking is saved
mangles a real name and still misses every other context: the same text written into a URL, a
JavaScript string or a CSS value needs a different encoding each time. Templating libraries that
encode by default, such as Jinja2 with autoescaping or React's JSX, are the usual way a team stops
forgetting; the test is the same either way.

`HttpOnly` on the session cookie, from lesson 17, is a third layer: a script that did run could
still not read the session. None of the three is a reason to drop the others.
