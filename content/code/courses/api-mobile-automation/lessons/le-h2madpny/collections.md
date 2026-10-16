---
title: A collection, saved as a file
version: 1
---

**A collection is the requests of one API, in folders, with what they share written once.** Shared
means the authorization, the variables, and later the scripts of lesson 5. A collection is also an
order. When it runs as a whole, its requests go top to bottom, folder by folder, which is what lets
one request use what an earlier one received.

The collection for boxoffice has three folders and six requests. Save it as `postman/boxoffice.postman_collection.json`:

```json
{
  "info": {
    "name": "boxoffice",
    "description": "The ticket API of lessons 4 to 6, one request per thing a tester asks it.",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "auth": {"type": "bearer", "bearer": [{"key": "token", "value": "{{token}}", "type": "string"}]},
  "variable": [{"key": "showId", "value": "sh-103"}, {"key": "orderId", "value": "ord-1001"}],
  "item": [
    {
      "name": "shows",
      "auth": {"type": "noauth"},
      "item": [
        {"name": "List shows", "request": {"method": "GET", "url": "{{baseUrl}}/v1/shows"}},
        {"name": "One show", "request": {"method": "GET", "url": "{{baseUrl}}/v1/shows/{{showId}}"}}
      ]
    },
    {
      "name": "auth",
      "auth": {"type": "noauth"},
      "item": [
        {
          "name": "Get token",
          "request": {
            "method": "POST",
            "url": "{{baseUrl}}/oauth/token",
            "body": {
              "mode": "urlencoded",
              "urlencoded": [
                {"key": "grant_type", "value": "client_credentials"},
                {"key": "client_id", "value": "{{clientId}}"},
                {"key": "client_secret", "value": "{{clientSecret}}"}
              ]
            }
          }
        }
      ]
    },
    {
      "name": "orders",
      "item": [
        {
          "name": "Create order",
          "request": {
            "method": "POST",
            "url": "{{baseUrl}}/v1/orders",
            "header": [{"key": "Content-Type", "value": "application/json"}],
            "body": {
              "mode": "raw",
              "raw": "{\"show_id\": \"{{showId}}\", \"seats\": 1}",
              "options": {"raw": {"language": "json"}}
            }
          }
        },
        {
          "name": "Read order",
          "request": {"method": "GET", "url": "{{baseUrl}}/v1/orders/{{orderId}}"}
        },
        {
          "name": "Cancel order",
          "request": {"method": "DELETE", "url": "{{baseUrl}}/v1/orders/{{orderId}}"}
        }
      ]
    }
  ]
}
```

Check it the way section 05 checked the environment, and then list its requests in the order a run
sends them:

```
ana@laptop:~/boxoffice$ jq empty postman/boxoffice.postman_collection.json && echo valid JSON
valid JSON
```

```
ana@laptop:~/boxoffice$ jq -r '.. | objects | select(has("request")) | .name' postman/boxoffice.postman_collection.json
List shows
One show
Get token
Create order
Read order
Cancel order
```

The jq filter walks every object in the file and keeps the ones holding a `request`, so it finds
requests at any depth and prints them in the file's order. That order is the run order.

## Reading the file

- `info.schema` names the format, **Collection v2.1**, which is what Postman exports by default
  and what Newman reads in lesson 6.
- `variable` holds the collection's own variables, the two the environment does not: the show to
  order from and the order to read.
- `item` is the tree. An entry with `item` inside is a folder; an entry with `request` is a request.
- each `url` is written as one string. When Postman exports a collection it splits every address
  into its parts, `raw`, `host` and `path`, and the file grows. Both forms are the same request, and
  Postman reads either.

## Authorization, set once

**A request inherits its authorization from its folder, and the folder from the collection**,
unless one of them says otherwise. The collection says `bearer` with `{{token}}`, which makes
Postman send `Authorization: Bearer <the token>` on every request that does not override it. Two
folders override it with `noauth`:

```
ana@laptop:~/boxoffice$ jq -r '"collection: " + .auth.type, (.item[] | .name + ": " + (.auth.type // "inherit"))' postman/boxoffice.postman_collection.json
collection: bearer
shows: noauth
auth: noauth
orders: inherit
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 292\" role=\"img\" aria-label=\"The collection sets bearer {{token}}. Its folder shows sets noauth, so List shows and One show send no token. The folder auth sets noauth, so Get token sends none either. The folder orders inherits, so Create order, Read order and Cancel order all send the bearer token.\"><defs><marker id=\"f04inherit-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"250\" y=\"14\" width=\"200\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"350\" y=\"29\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">collection</text><text x=\"350\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">bearer {{token}}</text><line x1=\"350\" y1=\"58\" x2=\"130\" y2=\"96\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f04inherit-ah)\"></line><rect x=\"40\" y=\"98\" width=\"180\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"130\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shows</text><text x=\"130\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">noauth</text><rect x=\"50\" y=\"160\" width=\"160\" height=\"26\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"130\" y=\"173\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">List shows</text><rect x=\"50\" y=\"194\" width=\"160\" height=\"26\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"130\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">One show</text><line x1=\"130\" y1=\"138\" x2=\"130\" y2=\"158\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f04inherit-ah)\"></line><line x1=\"350\" y1=\"58\" x2=\"350\" y2=\"96\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f04inherit-ah)\"></line><rect x=\"260\" y=\"98\" width=\"180\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"350\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">auth</text><text x=\"350\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">noauth</text><rect x=\"270\" y=\"160\" width=\"160\" height=\"26\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"350\" y=\"173\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Get token</text><line x1=\"350\" y1=\"138\" x2=\"350\" y2=\"158\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f04inherit-ah)\"></line><line x1=\"350\" y1=\"58\" x2=\"570\" y2=\"96\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f04inherit-ah)\"></line><rect x=\"480\" y=\"98\" width=\"180\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"570\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">orders</text><text x=\"570\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">inherit</text><rect x=\"490\" y=\"160\" width=\"160\" height=\"26\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"570\" y=\"173\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Create order</text><rect x=\"490\" y=\"194\" width=\"160\" height=\"26\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"570\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Read order</text><rect x=\"490\" y=\"228\" width=\"160\" height=\"26\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"570\" y=\"241\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Cancel order</text><line x1=\"570\" y1=\"138\" x2=\"570\" y2=\"158\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f04inherit-ah)\"></line><text x=\"350\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">highlighted: sends Authorization: Bearer with the token</text></svg>", "caption": "Authorization is written once, on the collection, and two folders opt out of it."}
```

`shows` needs no token, and sending one where none is needed hides a defect: a show list that
wrongly demanded a token would still pass. `auth` is the request that obtains the token, and it
authenticates with the client's id and secret in its body instead. `orders` says nothing, so it
inherits the bearer token, and so do its three requests. Change the token in one place and every
order request follows.

## Every name defined

Section 04 left a question: does every variable this collection uses exist somewhere? grep lists
them, and how many times each is used:

```
ana@laptop:~/boxoffice$ grep -o '{{[A-Za-z]*}}' postman/boxoffice.postman_collection.json | sort | uniq -c
      6 {{baseUrl}}
      1 {{clientId}}
      1 {{clientSecret}}
      2 {{orderId}}
      2 {{showId}}
      1 {{token}}
```

```
ana@laptop:~/boxoffice$ jq -c '.variable[]' postman/boxoffice.postman_collection.json
{"key":"showId","value":"sh-103"}
{"key":"orderId","value":"ord-1001"}
```

Six names, all defined. `baseUrl`, `clientId`, `clientSecret` and `token` come from the `lab`
environment; `showId` and `orderId` from the collection. A seventh name in the first list, missing
from both files, would be a request that cannot be sent.

## Running it by hand

Import the file the way you imported the environment, with `lab` active. Restart boxoffice in its
own terminal, so it starts with no orders, and send the requests in order:

1. **List shows** and **One show** answer `200`, with no token.
2. **Get token** answers `200` with an `access_token` in the body. Copy its value, open the `lab`
   environment, and paste it as the value of `token`. Save the environment.
3. **Create order** answers `201 Created` for one seat of `sh-103`.
4. **Read order** answers `200` for `ord-1001`, and **Cancel order** answers `204`.

Step 4 works only because boxoffice numbers its first order `ord-1001` after a restart. Restart it
again before the next time, or edit `orderId` by hand. Step 2 has to be repeated after 15 minutes,
when the token expires and every order request answers `401`. **Lesson 5 removes both hand steps.**
A script saves the token and the order's `location` as they arrive, and the requests read them from
there.

The Runner, which Postman opens from the collection's **Run** button, sends the six in that order
and shows each answer. It was not captured for this course either. Lesson 6 runs the same file from
the terminal with Newman, where every line can be shown.
