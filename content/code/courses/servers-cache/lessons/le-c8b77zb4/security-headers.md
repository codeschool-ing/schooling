---
title: Headers that tell the browser what to refuse
version: 1
---

The previous two sections were about what the server says. These headers are instructions to the
**browser**: things it should refuse on this site's behalf, even if the site itself is tricked into
asking for them. None of them are sent by default:

```
ana@web:~$ curl -sI https://ipelivros.example/ | grep -ciE "^(strict-transport|content-security|x-content-type|referrer-policy|permissions-policy)"
0
```

Five lines in a snippet, included in the HTTPS server block:

```
ana@web:~$ cat /etc/nginx/snippets/security-headers.conf
add_header Strict-Transport-Security "max-age=31536000" always;
add_header X-Content-Type-Options    "nosniff" always;
add_header Referrer-Policy           "strict-origin-when-cross-origin" always;
add_header Permissions-Policy        "camera=(), microphone=(), geolocation=()" always;
add_header Content-Security-Policy   "default-src 'self'; img-src 'self' data:; frame-ancestors 'none'; base-uri 'self'; form-action 'self'" always;
ana@web:~$ sudo sed -i 's|    include snippets/ipelivros-tls.conf;|    include snippets/ipelivros-tls.conf;\n    include snippets/security-headers.conf;|' /etc/nginx/sites-available/ipelivros && grep -n 'include snippets' /etc/nginx/sites-available/ipelivros
11:    include snippets/ipelivros-tls.conf;
12:    include snippets/security-headers.conf;
ana@web:~$ curl -sI https://ipelivros.example/ | grep -iE "^(strict-transport|content-security|x-content-type|referrer-policy|permissions-policy)"
Strict-Transport-Security: max-age=31536000
X-Content-Type-Options: nosniff
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: camera=(), microphone=(), geolocation=()
Content-Security-Policy: default-src 'self'; img-src 'self' data:; frame-ancestors 'none'; base-uri 'self'; form-action 'self'
```

| header | what it tells the browser |
|---|---|
| `Strict-Transport-Security` | for the next year, use only HTTPS for this name, even if a link or a person types `http://` |
| `X-Content-Type-Options: nosniff` | believe the `Content-Type`; do not guess that a file served as text is a script |
| `Referrer-Policy` | when following a link to another site, send only this site's origin, not the full address of the page |
| `Permissions-Policy` | this site never uses the camera, the microphone or the location, so refuse any page that asks |
| `Content-Security-Policy` | load scripts, styles, pictures and forms only from these places |

**`always` matters in every one of these lines.** Without it, `add_header` adds the header only to
successful responses, as lesson 2's location test showed, and the error pages are exactly the ones
an attacker reaches for.

And HSTS is sent only over HTTPS, never on the redirect:

```
ana@web:~$ curl -sI http://ipelivros.example/ | grep -iE "^(HTTP|strict-transport)"
HTTP/1.1 301 Moved Permanently
```

That is deliberate and correct. A browser ignores HSTS received over plain HTTP, because anybody on
the path could have added it, so sending it there would only look like protection.

## HSTS, and the year you cannot take back

**HSTS fixes the one request HTTPS cannot protect: the first.** Somebody types `ipelivros.example`, the
browser tries `http://` first, and an attacker on the café's Wi-Fi answers that request before the
redirect ever arrives. After one visit with HSTS, the browser goes straight to `https://` for
`max-age` seconds without ever asking over HTTP.

The same property is its danger. **Once a browser has seen the header, nothing you change on the
server removes it until `max-age` runs out.** If HTTPS breaks during that year, an expired certificate
for instance, visitors cannot click past the warning, because HSTS forbids exactly that. Two
additions make it stronger and the commitment wider: `includeSubDomains` covers every name under
this one, including ones another team runs on plain HTTP; `preload` asks browsers to ship the name in
their built-in list, which takes months to undo. Start with a short `max-age`, an hour, raise it once
renewal has been proven, and add the other two only when every subdomain is on HTTPS for good.

## CSP, the one that does the most and breaks the most

`Content-Security-Policy` is the strongest of the five: if an attacker manages to inject a
`<script>` into a page, through a comment field or a product name that the application did not
escape, the browser refuses to run it unless it came from an allowed source. The bookshop's policy
reads, directive by directive: everything from this site only (`default-src 'self'`), pictures also
from inline `data:` addresses, no other site may put this one in a frame (`frame-ancestors 'none'`,
the modern replacement for `X-Frame-Options`), and forms may only submit here.

The bookshop's page passes it, because its one script is a file of its own, `/js/app.js`. **A page
with a script written inside the HTML, or an `onclick=` attribute, breaks under this policy**, and that
is most older sites. That is why a policy is introduced as `Content-Security-Policy-Report-Only`
first: the browser enforces nothing, reports every violation it would have blocked, and the policy is
tightened until the reports stop. This course has no browser in its lab to show that, which is why
CSP is the one header here checked only for being sent; on your own computer, the browser's developer
tools list every violation in the console.
