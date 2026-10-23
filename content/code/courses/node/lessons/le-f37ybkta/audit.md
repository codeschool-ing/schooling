---
title: npm audit, and reading an advisory
version: 1
---

**`npm audit` sends the list of what you have installed to the registry and gets back the published
security advisories that apply to it.** Every install runs it, which is the `found 0 vulnerabilities`
line under each one so far. To see what a positive answer looks like, install an old release of Express
in a scratch project, 4.17.1 from 2019:

```
ana@dev:~/server/audited$ echo '{ "name": "audited", "private": true }' > package.json
ana@dev:~/server/audited$ npm install express@4.17.1

added 50 packages, and audited 51 packages in 609ms

1 package is looking for funding
  run `npm fund` for details

7 vulnerabilities (3 low, 4 high)

To address issues that do not require attention, run:
  npm audit fix

To address all issues, run:
  npm audit fix --force

Run `npm audit` for details.
```

```
ana@dev:~/server/audited$ npm audit
# npm audit report

body-parser  <=1.20.5
Severity: high
body-parser vulnerable to denial of service when url encoding is enabled - https://github.com/advisories/GHSA-qwcr-r2fm-qrc7
body-parser vulnerable to denial of service when invalid limit value silently disables size enforcement - https://github.com/advisories/GHSA-v422-hmwv-36x6
Depends on vulnerable versions of qs
fix available via `npm audit fix`
node_modules/body-parser
  express  <=4.21.2 || 5.0.0-alpha.1 - 5.0.0
  Depends on vulnerable versions of body-parser
  Depends on vulnerable versions of cookie
  Depends on vulnerable versions of path-to-regexp
  Depends on vulnerable versions of qs
  Depends on vulnerable versions of send
  Depends on vulnerable versions of serve-static
  node_modules/express

cookie  <0.7.0
cookie accepts cookie name, path, and domain with out of bounds characters - https://github.com/advisories/GHSA-pxg6-pf52-xh8x
fix available via `npm audit fix`
node_modules/cookie


path-to-regexp  <=0.1.12
Severity: high
path-to-regexp outputs backtracking regular expressions - https://github.com/advisories/GHSA-9wv6-86v2-598j
path-to-regexp contains a ReDoS - https://github.com/advisories/GHSA-rhx6-c78j-4q9w
path-to-regexp vulnerable to Regular Expression Denial of Service via multiple route parameters - https://github.com/advisories/GHSA-37ch-88jc-xwx2
fix available via `npm audit fix`
node_modules/path-to-regexp

qs  <=6.15.3
Severity: high
qs vulnerable to Prototype Pollution - https://github.com/advisories/GHSA-hrpp-h998-j3pp
qs's arrayLimit bypass in comma parsing allows denial of service - https://github.com/advisories/GHSA-w7fw-mjwx-w883
qs's arrayLimit bypass in its bracket notation allows DoS via memory exhaustion - https://github.com/advisories/GHSA-6rw7-vpxm-498p
qs: Denial of Service via Attacker Controlled isBuffer - https://github.com/advisories/GHSA-4mjr-xmp4-gh2g
fix available via `npm audit fix`
node_modules/qs

send  <0.19.0
send vulnerable to template injection that can lead to XSS - https://github.com/advisories/GHSA-m6fv-jmcg-4jfg
fix available via `npm audit fix`
node_modules/send
  serve-static  <=1.16.0
  Depends on vulnerable versions of send
  node_modules/serve-static


7 vulnerabilities (3 low, 4 high)

To address all issues, run:
  npm audit fix
```

## How to read it

Each entry is one vulnerable package, and every line in it says something you need:

- **the package and the vulnerable range**: `qs <=6.15.3`. Your installed version is inside it.
- **the severity**, which is the advisory's own estimate. `high` is not an emergency by itself, and
  `low` is not safe to ignore by itself.
- **the advisory's title and address**, `GHSA-...`, which says what the flaw is and under what
  conditions it can be used. Read it: a denial of service in a parser you never feed untrusted input
  matters less than one in the parser behind every request.
- **the path**: `qs` is not something you installed. Express depends on `body-parser`, which depends
  on `qs`, and the indented lines say so. The fix for a deep package is almost always an update of the
  direct one above it.
- **whether a fix exists**: `fix available via npm audit fix`.

## Fixing it

`npm audit fix` updates what it can within your ranges:

```
ana@dev:~/server/audited$ npm audit fix

added 18 packages, changed 23 packages, and audited 69 packages in 717ms

16 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
ana@dev:~/server/audited$ npm ls express
audited@ /home/ana/server/audited
└── express@4.22.3
```

Everything in Express 4's own patch releases was enough here: the newest 4.x carries fixed versions of
every package in the report. When it is not, the report says the fix needs a major version, and the
decision of the previous section is the way through, with the advisory as the reason to make it now.

**What not to do with a report is ignore it until it is long.** A project audited every week faces one
advisory at a time, and a project audited once a year faces this screen. `npm audit --omit=dev`
reports only what production installs, which is the list that matters most on a server.
