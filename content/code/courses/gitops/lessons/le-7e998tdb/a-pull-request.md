---
title: The pull request is the change request
version: 1
---

**In a GitOps setup the pull request is the change request.** It names what changes, who wants it,
why, and who agreed. There is no separate ticket to keep in step with the code, because the diff is
the change itself. This section opens one and watches the rule from the last section stop it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" xmlns=\"http://www.w3.org/2000/svg\" role=\"img\" aria-label=\"A change&#x27;s path from a branch to the cluster: a branch, a pull request, the validate check and a review in parallel, the merge into main, and the reconciler applying main.\"><rect x=\"0\" y=\"0\" width=\"720\" height=\"250\" fill=\"var(--ink)\"/><rect x=\"20\" y=\"100\" width=\"110\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"75.0\" y=\"120.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">branch</text><text x=\"75.0\" y=\"138.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">banner-v2</text><rect x=\"160\" y=\"100\" width=\"120\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"220.0\" y=\"120.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">pull request</text><text x=\"220.0\" y=\"138.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">#1</text><rect x=\"320\" y=\"40\" width=\"120\" height=\"50\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\"/><text x=\"380.0\" y=\"60.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">check</text><text x=\"380.0\" y=\"78.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">validate</text><rect x=\"320\" y=\"160\" width=\"120\" height=\"50\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\"/><text x=\"380.0\" y=\"180.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">review</text><text x=\"380.0\" y=\"198.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">Bruno</text><rect x=\"470\" y=\"100\" width=\"100\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"520.0\" y=\"120.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">merge</text><text x=\"520.0\" y=\"138.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">main</text><rect x=\"600\" y=\"100\" width=\"100\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"650.0\" y=\"120.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">cluster</text><text x=\"650.0\" y=\"138.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">reconciler</text><line x1=\"130\" y1=\"125\" x2=\"148.0\" y2=\"125.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"156,125 148.0,120.5 148.0,129.5\" fill=\"var(--paper-dim)\"/><line x1=\"280\" y1=\"115\" x2=\"311.0\" y2=\"76.2\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"316,70 307.5,73.4 314.5,79.1\" fill=\"var(--paper-dim)\"/><line x1=\"280\" y1=\"135\" x2=\"311.0\" y2=\"173.8\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"316,180 314.5,170.9 307.5,176.6\" fill=\"var(--paper-dim)\"/><line x1=\"440\" y1=\"65\" x2=\"462.1\" y2=\"105.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"466,112 466.1,102.8 458.2,107.2\" fill=\"var(--paper-dim)\"/><line x1=\"440\" y1=\"185\" x2=\"462.1\" y2=\"145.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"466,138 458.2,142.8 466.1,147.2\" fill=\"var(--paper-dim)\"/><line x1=\"570\" y1=\"125\" x2=\"588.0\" y2=\"125.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"/><polygon points=\"596,125 588.0,120.5 588.0,129.5\" fill=\"var(--phosphor)\"/><text x=\"360\" y=\"232\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--amber)\">the rule waits for both</text><text x=\"360\" y=\"22\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">Nobody pushes to main: every change takes this path</text></svg>", "caption": "The path every change takes in this lesson. The protection rule on main holds the merge until the check is green and somebody other than the author has approved."}
```

## Opening it

The branch goes to the server, and the pull request asks for it to be merged into `main`:

```
ana@laptop:~/fleet$ git push --quiet -u origin banner-v2
remote: 
remote: Create a new pull request for 'banner-v2':        
remote:   http://localhost:3000/ana/fleet/pulls/new/banner-v2        
remote: 
ana@laptop:~/fleet$ curl -s -H "$AS_ANA" -H "$JSON" -d '{"head": "banner-v2", "base": "main", "title": "staging: ready for review", "body": "QA starts on staging on Monday, and the banner tells them it is ready."}' $API/pulls | jq '{number, title, state, mergeable}'
{
  "number": 1,
  "title": "staging: ready for review",
  "state": "open",
  "mergeable": true
}
```

The body is not decoration. **It is the record of why**, the part a `git log` a year from now will
not explain on its own, and lesson 12 reads it back.

## The rule at work

Ana is in a hurry and tries to merge her own change:

```
ana@laptop:~/fleet$ curl -s -w " %{http_code}\n" -H "$AS_ANA" -H "$JSON" -d '{"Do": "merge"}' $API/pulls/1/merge
{"message":"Does not have enough approvals","url":"http://localhost:3000/api/swagger"} 405
```

`Does not have enough approvals`. Being an administrator does not help, because the rule said
nobody. She tries the obvious workaround and approves it herself:

```
ana@laptop:~/fleet$ curl -s -w " %{http_code}\n" -H "$AS_ANA" -H "$JSON" -d '{"event": "APPROVED", "body": "Looks fine to me."}' $API/pulls/1/reviews
{"message":"approve your own pull is not allowed","url":"http://localhost:3000/api/swagger"} 422
```

Gitea refuses that too: **an approval counts only from somebody other than the author**. The change
waits for Bruno, which is the whole point of the rule, and the next section is what Bruno does
with it.
