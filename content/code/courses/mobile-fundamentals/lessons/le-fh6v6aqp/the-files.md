---
title: The two files the website serves, and the headers that are checked
version: 1
---

**A verified link is verified by the website, so its proof is two small JSON files at fixed addresses
on the domain.** Android fetches `/.well-known/assetlinks.json`; iOS fetches
`/.well-known/apple-app-site-association`, with no extension. Each one names the apps allowed to open
the site's links. The system fetches them when the app is installed, compares them with the app, and
from then on routes matching links to it, or does not.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l11-verify\" aria-label=\"How a verified link is verified, in four steps from left to right. The app is installed, and it declares a domain. The system fetches the domain's file over https: assetlinks.json on Android, apple-app-site-association on iOS. It compares the file with the app: the package and certificate fingerprint on Android, the team and bundle id on iOS. If they match, links to the domain open the app; if not, they open the browser.\"><defs><marker id=\"l11-verify-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l11-verify-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l11-verify-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"70\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"85.0\" y=\"88.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the app is installed,</text><text x=\"85.0\" y=\"101.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">and declares a domain</text><rect x=\"190\" y=\"70\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"265.0\" y=\"88.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the system fetches</text><text x=\"265.0\" y=\"101.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the domain's file</text><rect x=\"370\" y=\"70\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"445.0\" y=\"88.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">it compares the file</text><text x=\"445.0\" y=\"101.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">with the app</text><rect x=\"556\" y=\"30\" width=\"154\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"633.0\" y=\"46.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">match: links to the</text><text x=\"633.0\" y=\"59.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">domain open the app</text><rect x=\"556\" y=\"114\" width=\"154\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"633.0\" y=\"130.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">no match: links</text><text x=\"633.0\" y=\"143.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">open the browser</text><path d=\"M160 95 L190 95\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-verify-ah-paper-dim)\"></path><path d=\"M340 95 L370 95\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-verify-ah-paper-dim)\"></path><path d=\"M520 88 L556 56\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-verify-ah-phosphor)\"></path><path d=\"M520 102 L556 134\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-verify-ah-amber)\"></path><text x=\"265\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">over https, no redirect</text><text x=\"265\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">assetlinks.json</text><text x=\"265\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">apple-app-site-association</text><text x=\"392\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">Android</text><text x=\"392\" y=\"151\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">package +</text><text x=\"392\" y=\"163\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">certificate fingerprint</text><text x=\"392\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">iOS</text><text x=\"392\" y=\"195\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">team id +</text><text x=\"392\" y=\"207\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">bundle id</text></svg>", "caption": "Verification happens once the app is installed, not when a link is tapped. The tap only follows what was decided then."}
```

## What each file says

**Android's file names a package and the fingerprint of the certificate the app is signed with.**
Android's documentation on configuring website associations gives the shape: a list of statements,
each with the relation `delegate_permission/common.handle_all_urls` and a target naming the
`package_name` and its `sha256_cert_fingerprints`. The fingerprint is what stops an impostor: another
app can copy the package name, but it cannot be signed with the planner's key. The value below is the example printed in that documentation, not a real key; how the
real one is made and kept is lesson 1 of `mobile-delivery`.

**Apple's file names an app id and the paths it may open.** Apple's documentation on supporting
associated domains gives the shape: an `applinks` object whose `details` list `appIDs`, each the team
id and the bundle id joined by a dot, and `components` that match parts of the URL. `ABCDE12345` is
the team id Apple's own example uses. The planner's components let `/course/*`, `/courses` and `/week`
open the app, which is the same list the parser accepts, and every other path on the site stays a web
page.

## A website that serves them

Here is the planner's website, as far as the two platforms care about it: the two files, a web page for
each course, and a 404 for everything else. It is Node's own `http` module, with nothing to install.
Save it as `site.ts`:

```typescript
// site.ts: the planner's website, as far as the two platforms care about it
import { createServer } from "node:http";

// Android: which app may open this site's links, and the certificate it is
// signed with. The fingerprint is the example from Android's documentation.
const assetlinks = [{
  relation: ["delegate_permission/common.handle_all_urls"],
  target: {
    namespace: "android_app",
    package_name: "com.example.planner",
    sha256_cert_fingerprints: [
      "14:6D:E9:83:C5:73:06:50:D8:EE:B9:95:2F:34:FC:64:16:A0:83:42:E6:1D:BE:A8:8A:04:96:B2:3F:CF:44:E5",
    ],
  },
}];

// iOS: which app may open which paths. ABCDE12345 is the team id from
// Apple's documentation, not a real one.
const aasa = {
  applinks: {
    details: [{
      appIDs: ["ABCDE12345.com.example.planner"],
      components: [{ "/": "/course/*" }, { "/": "/courses" }, { "/": "/week" }],
    }],
  },
};

const files: Record<string, unknown> = {
  "/.well-known/assetlinks.json": assetlinks,
  "/.well-known/apple-app-site-association": aasa,
};

const server = createServer((req, res) => {
  res.sendDate = false; // no Date header, so every run prints the same
  const body = files[req.url ?? ""];
  if (body !== undefined) {
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify(body, null, 2) + "\n");
  } else if (req.url?.startsWith("/course/")) {
    res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
    res.end("<h1>This course, on the web</h1>\n");
  } else {
    res.writeHead(404, { "Content-Type": "text/plain" });
    res.end("not found\n");
  }
});
server.listen(8011, "127.0.0.1", () => console.log("http://127.0.0.1:8011"));
```

Start it in a second terminal with `node site.ts`, which prints the address it listens on and keeps
running until you press Ctrl+C. Then, in the first terminal, ask for each file the way a platform would.
`-i` prints the response's headers above its body, and `-s` keeps curl quiet about its progress:

```
ana@dev:~/planner$ curl -si http://127.0.0.1:8011/.well-known/assetlinks.json
HTTP/1.1 200 OK
Content-Type: application/json
Connection: keep-alive
Keep-Alive: timeout=5
Transfer-Encoding: chunked

[
  {
    "relation": [
      "delegate_permission/common.handle_all_urls"
    ],
    "target": {
      "namespace": "android_app",
      "package_name": "com.example.planner",
      "sha256_cert_fingerprints": [
        "14:6D:E9:83:C5:73:06:50:D8:EE:B9:95:2F:34:FC:64:16:A0:83:42:E6:1D:BE:A8:8A:04:96:B2:3F:CF:44:E5"
      ]
    }
  }
]
ana@dev:~/planner$ curl -si http://127.0.0.1:8011/.well-known/apple-app-site-association
HTTP/1.1 200 OK
Content-Type: application/json
Connection: keep-alive
Keep-Alive: timeout=5
Transfer-Encoding: chunked

{
  "applinks": {
    "details": [
      {
        "appIDs": [
          "ABCDE12345.com.example.planner"
        ],
        "components": [
          {
            "/": "/course/*"
          },
          {
            "/": "/courses"
          },
          {
            "/": "/week"
          }
        ]
      }
    ]
  }
}
ana@dev:~/planner$ curl -si http://127.0.0.1:8011/.well-known/assetlinks
HTTP/1.1 404 Not Found
Content-Type: text/plain
Connection: keep-alive
Keep-Alive: timeout=5
Transfer-Encoding: chunked

not found
ana@dev:~/planner$ curl -si http://127.0.0.1:8011/course/sql
HTTP/1.1 200 OK
Content-Type: text/html; charset=utf-8
Connection: keep-alive
Keep-Alive: timeout=5
Transfer-Encoding: chunked

<h1>This course, on the web</h1>
```

## What the platforms check, and what this one cannot

**Three things in those headers are what a platform's fetch looks at, and the documentation names
each.** The status is `200`; a missing file is a 404, like the one for `assetlinks` without its
extension, and a link verified against a 404 is not verified. The `Content-Type` is
`application/json`, which Android's documentation requires in so many words. And there is no
redirect: both platforms' documentation says the file must be served without one, so a site that
sends `/.well-known/...` on to `www.` with a 301 has, as far as verification goes, no file at all.

**What this server cannot show is the `https` half.** Both platforms fetch the file over `https`, and
Apple's documentation asks for a valid certificate. This server speaks plain `http` on your own
computer, and nothing on the internet can reach it, so it checks the status, the type and the absence
of a redirect, and leaves the certificate to a real host. Since iOS 14, Apple's documentation adds, the
device does not even fetch the file from your server: it asks a content delivery network Apple runs,
which fetched it from you.

**The two files are the same promise in two vocabularies.** Each says *this app, and no other, may open
links to this domain*. Each is public, by design: anybody can read which apps a site vouches for, and
that is fine, because a fingerprint and a team id are not secrets. Stop the server with Ctrl+C before
you go on.
