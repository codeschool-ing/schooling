---
title: SnapStart, provisioned concurrency, and the ping that does not work
version: 1
---

When the module is as light as it will get and a person is still waiting on the first request,
two features remove the init phase from that request, and one widespread trick only seems to.
**The two features remove it by doing it in advance; the trick does not remove it at all, it just
moves where you stop looking.**

## SnapStart: init once, restore many times

SnapStart turns the init phase into something done at deployment rather than at request time.
When you publish a version, Lambda runs that version's init phase once, takes a snapshot of the
initialised environment's memory and disk, encrypts it and caches it. A cold start of that
version then **restores the snapshot instead of running the init phase**: the interpreter is
already started, `boto3` already imported, the client already built. AWS documents it for Java 11
and later, Python 3.12 and later, and .NET 8 and later, and only on published versions, which is
the same reason provisioned concurrency needs one: a snapshot of `$LATEST` would be a snapshot of
something that can change.

moto accepts the setting and records nothing, which is worth seeing once because it fails in the
quietest possible way. The function is created with SnapStart asked for, and the answer says it is
off:

```
ana@laptop:~/aws$ aws lambda create-function --function-name snappy --runtime python3.12 --handler app.handler --role arn:aws:iam::123456789012:role/fn-role --zip-file fileb://fn.zip --snap-start ApplyOn=PublishedVersions --query SnapStart
{
    "ApplyOn": "None",
    "OptimizationStatus": "Off"
}
ana@laptop:~/aws$ aws lambda publish-version --function-name snappy --query "{Version: Version, SnapStart: SnapStart}"
{
    "Version": "1",
    "SnapStart": {
        "ApplyOn": "None",
        "OptimizationStatus": "Off"
    }
}
```

`ApplyOn` came back `None`, on the function and on the version, although the request said
`PublishedVersions`. On AWS both would say `PublishedVersions`, and the version would carry an
`OptimizationStatus` of `On` once its snapshot exists. Nothing about snapshots was run here: moto
runs no code, so there is nothing for it to snapshot.

Three things from AWS's documentation decide whether SnapStart fits:

- **State captured at init is restored into every environment.** A random seed, a unique id or a
  temporary credential created at the top of the file is the same in every restored copy. A
  database connection opened at init was opened by an environment that no longer exists, and has to
  be checked or opened again. Python offers hooks that run before the snapshot and after each
  restore, for exactly this.
- **It does not combine with provisioned concurrency**, nor with EFS, nor with more than 512 MB of
  ephemeral storage.
- **For Python and .NET it is billed**, for keeping the snapshot cached and for each restore; for
  Java it is not. Neither of the two prices is on the sheet of lesson 1, so this course quotes no
  figure for it.

## Provisioned concurrency, from the other side

Lesson 16 priced it: environments initialised before any request and kept ready, billed for every
second they are configured, and in sa-east-1 never cheaper than on demand. From the cold-start
side, it is the only remedy that removes the init phase **up to a number you choose**, and
everything above that number is cold as before. It needs no change to the code and no thought
about restored state, which is what the money buys.

## Why a ping every five minutes does not do it

The trick is a schedule, an EventBridge rule that invokes the function every five minutes with
an empty event, so that an environment is always warm. It is the first thing many teams try and
it works on the graph of a single developer clicking a button. **It keeps one environment warm,
and lesson 16 is why one is not enough.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" aria-label=\"Six requests arrive in the same second. An arrow from each goes to an environment. The first goes to the one environment the ping kept warm; the other five go to new environments, each drawn dashed and marked as a cold start.\"><defs><marker id=\"pg-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"100\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">six requests, one second</text><text x=\"555\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">where each one runs</text><rect x=\"40\" y=\"40\" width=\"120\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"100\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">request 1</text><path d=\"M162 53 L414 53\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pg-ah)\"></path><rect x=\"420\" y=\"40\" width=\"270\" height=\"26\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"555\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">warm, kept by the ping</text><rect x=\"40\" y=\"76\" width=\"120\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"100\" y=\"89\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">request 2</text><path d=\"M162 89 L414 89\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pg-ah)\"></path><rect x=\"420\" y=\"76\" width=\"270\" height=\"26\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"555\" y=\"89\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">new environment: cold start</text><rect x=\"40\" y=\"112\" width=\"120\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"100\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">request 3</text><path d=\"M162 125 L414 125\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pg-ah)\"></path><rect x=\"420\" y=\"112\" width=\"270\" height=\"26\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"555\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">new environment: cold start</text><rect x=\"40\" y=\"148\" width=\"120\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"100\" y=\"161\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">request 4</text><path d=\"M162 161 L414 161\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pg-ah)\"></path><rect x=\"420\" y=\"148\" width=\"270\" height=\"26\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"555\" y=\"161\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">new environment: cold start</text><rect x=\"40\" y=\"184\" width=\"120\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"100\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">request 5</text><path d=\"M162 197 L414 197\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pg-ah)\"></path><rect x=\"420\" y=\"184\" width=\"270\" height=\"26\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"555\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">new environment: cold start</text><rect x=\"40\" y=\"220\" width=\"120\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"100\" y=\"233\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">request 6</text><path d=\"M162 233 L414 233\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pg-ah)\"></path><rect x=\"420\" y=\"220\" width=\"270\" height=\"26\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"555\" y=\"233\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">new environment: cold start</text><text x=\"288\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\" font-style=\"italic\">one ping keeps one environment warm</text></svg>", "caption": "A ping keeps one environment from being retired, and one environment serves one request at a time. Six requests in the same second find one warm environment and five cold starts."}
```

A ping is one request, so it keeps one environment from being retired. When six people arrive
in the same second, one of them gets the warm environment and five get new ones, each with the
full init phase; the burst of traffic that a person notices is exactly the moment the ping does
not cover. Pinging with six concurrent requests keeps six warm, until the seventh. And AWS
retires environments on its own schedule, warm or not, so even the one is not a promise. **What
the ping buys is a cold start that is rarer for a lone user and as bad as ever for a crowd**, plus
288 extra invocations a day, every day, in every metric of the function.

The honest ladder, then, cheapest first: make the module light; give it the memory its init
needs; publish versions and try SnapStart if the runtime has it; and if a cold start still costs
something real, pay for provisioned concurrency for the hours when it does. Lesson 18 removes the
one cold start this list does not mention, the one a function inside a VPC used to carry.
