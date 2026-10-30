---
title: Regions, zones and the private backbone
version: 1
---

**A region is a place on the map; a zone is a separate failure inside it.** The `cloud` course drew
that picture for every provider. This section is Google Cloud's spelling of it, and the two details
Google adds that change how a design is drawn.

The common wrong picture is that a zone is a datacentre. **A zone is a deployment area inside a
region, with its own power, cooling and network**, built so that one zone can fail while its
neighbours carry on. Google does not say how many buildings a zone is, and the answer would not
change a design. A region holds three or more zones, close enough that a round trip between two of
them stays well under a few milliseconds. The arrangement is the same as everywhere: **you choose the
zones, Google chooses the buildings**, and a system spread across two or three zones survives the loss
of one.

## The names

A region's name is a continent, a direction and a number. A zone's name is the region's with a
letter on the end:

| name | what it is |
|---|---|
| `southamerica-east1` | São Paulo, the region every lesson of this course uses |
| `southamerica-east1-a`, `-b`, `-c` | its three zones |
| `southamerica-west1` | Santiago, the other region in South America |
| `us-central1` | Iowa, the region a great deal of Google's own documentation uses in its examples |

**A zone's name means the same building to everybody.** Google does not shuffle the letters between
customers, so `southamerica-east1-a` in your project is `southamerica-east1-a` in the next one. That
matters when two teams plan around the same failure: when one says "zone a was down", the other knows
which.

## Asking for the list, and being refused

`gcloud compute regions list` is the command that prints every region with its quotas and its state.
Run it in the lab:

```
ana@laptop:~/gcp$ gcloud compute regions list
ERROR: (gcloud.compute.regions.list) Some requests did not succeed:
 - Request had invalid authentication credentials. Expected OAuth 2 access token, login cookie or other valid authentication credential. See https://developers.google.com/identity/sign-in/web/devconsole-project.

ana@laptop:~/gcp$ curl -sS https://compute.googleapis.com/compute/v1/projects/planner-dev/zones
{
  "error": {
    "code": 401,
    "message": "Request is missing required authentication credential. Expected OAuth 2 access token, login cookie or other valid authentication credential. See https://developers.google.com/identity/sign-in/web/devconsole-project.",
    "errors": [
      {
        "message": "Login Required.",
        "domain": "global",
        "reason": "required",
        "location": "Authorization",
        "locationType": "header"
      }
    ],
    "status": "UNAUTHENTICATED",
    "details": [
      {
        "@type": "type.googleapis.com/google.rpc.ErrorInfo",
        "reason": "CREDENTIALS_MISSING",
        "domain": "googleapis.com",
        "metadata": {
          "method": "compute.v1.ZonesService.List",
          "service": "compute.googleapis.com"
        }
      }
    ]
  }
}
```

**That refusal is the real Compute Engine API, in Google's datacentres, answering a request that
carried the word `placeholder` as its credential.** The lab has no emulator for Compute Engine, so
the CLI did what it does when nothing overrides an address: it sent the request to
`compute.googleapis.com`. The second command sends the same kind of request with `curl` and no
credential at all, and Google says so in a different sentence: the first request carried a credential
that failed, the second carried none. Lesson 24 reads that kind of answer field by field.

So the regions are taught here from Google's documentation, and **this list was not produced by a
command**. At the end of October 2026 Google listed more than forty regions, two of them in South
America; the number grows every year, which is why a course should never be the place you look it up.

## The backbone

The second detail is the one that makes Google Cloud's network unusual. **Google carries traffic
between its regions on its own fibre**, and in the default arrangement it carries traffic between a
region and the user on its own fibre too, as far as the point of presence nearest the user. A request
from Recife to a service in São Paulo enters Google's network near Recife and never crosses the public
internet in between.

That default has a name, **Premium Tier**, and the alternative, **Standard Tier**, hands the traffic to
the public internet near the region instead, for a lower price per gibibyte. The choice is made per
address, and lesson 20 meets it again on a load balancer. It is also the reason a single network can
span every region, which lesson 15 builds: the packets between two regions of one network never leave
Google.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l01-backbone\" aria-label=\"Two ways a request from a user in Recife reaches a service in São Paulo. Above, Premium Tier: the request enters Google's network at a point of presence near Recife and travels on Google's own backbone to the region southamerica-east1, which holds three zones, a, b and c. Below, Standard Tier: the request crosses the public internet all the way and enters Google's network only at the region. Between southamerica-east1 and southamerica-west1, Santiago, traffic always travels on the backbone.\"><defs><marker id=\"l01-backbone-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l01-backbone-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l01-backbone-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"130.0\" width=\"110.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"75.0\" y=\"153.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a user</text><text x=\"75.0\" y=\"166.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">in Recife</text><rect x=\"430.0\" y=\"70.0\" width=\"270.0\" height=\"180.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"565.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">southamerica-east1</text><rect x=\"448.0\" y=\"108.0\" width=\"74.0\" height=\"54.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"485.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">a</text><rect x=\"532.0\" y=\"108.0\" width=\"74.0\" height=\"54.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"569.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">b</text><rect x=\"616.0\" y=\"108.0\" width=\"74.0\" height=\"54.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"653.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">c</text><text x=\"565.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">three zones: separate power,</text><text x=\"565.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cooling and network</text><rect x=\"560.0\" y=\"278.0\" width=\"140.0\" height=\"40.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"630.0\" y=\"298.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">southamerica-west1</text><path d=\"M630.0 252.0 L630.0 274.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\" marker-end=\"url(#l01-backbone-af-ah-phosphor)\" marker-start=\"url(#l01-backbone-af-ah-phosphor)\"></path><text x=\"548.0\" y=\"264.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">always the backbone</text><rect x=\"170.0\" y=\"40.0\" width=\"92.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"216.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">point of presence</text><path d=\"M130.0 145.0 L168.0 72.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l01-backbone-af-ah-paper-dim)\"></path><path d=\"M264.0 60.0 L426.0 100.0\" stroke=\"var(--phosphor)\" stroke-width=\"2.4\" fill=\"none\" marker-end=\"url(#l01-backbone-af-ah-phosphor)\"></path><text x=\"330.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">Premium Tier</text><text x=\"340.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">Google's fibre</text><path d=\"M130 178 C 200 240, 260 200, 300 236 S 380 250, 426 222\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l01-backbone-af-ah-amber)\"></path><text x=\"250.0\" y=\"280.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">Standard Tier</text><text x=\"250.0\" y=\"298.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">the public internet, to the region</text></svg>", "caption": "Premium Tier is the default: the request joins Google's network near the user."}
```

What the backbone does not change is the bill: the next section prices the arrows between those
boxes, and the most surprising one is the one leaving São Paulo.
