---
title: The inventory, and the answers made from it
version: 1
---

**The forms are filled from memory in most teams, and memory is the wrong source.** A form filled
on the day of launch and never opened again describes an app that no longer exists by the third
release. The fix is to keep the answer where the code is: a file listing every kind of data the
app sends anywhere, reviewed whenever the code that sends it changes.

## The planner's data

The planner signs people in with an e-mail address, keeps their courses and sessions on the server
so they sync between devices, sends crash reports through a crash reporter, which is lesson 12, and
records a few product events, which is lesson 16. Each entry below names what it is, who receives
it, what it is for, and how each store calls it. Save this in `~/planner` as `inventory.json`:

```json
{
  "app": "Study Planner",
  "encryptedInTransit": true,
  "deletionOnRequest": true,
  "data": [
    {
      "what": "e-mail address", "to": "planner server", "thirdParty": false,
      "purposes": ["app functionality", "account management"],
      "linked": true, "tracking": false, "optional": false,
      "apple": "Contact Info / Email Address", "google": "Personal info / Email address"
    },
    {
      "what": "courses and sessions", "to": "planner server", "thirdParty": false,
      "purposes": ["app functionality"],
      "linked": true, "tracking": false, "optional": false,
      "apple": "User Content / Other User Content", "google": "App activity / Other user-generated content"
    },
    {
      "what": "crash reports", "to": "crash reporting service", "thirdParty": true,
      "purposes": ["analytics"],
      "linked": false, "tracking": false, "optional": false,
      "apple": "Diagnostics / Crash Data", "google": "App info and performance / Crash logs"
    },
    {
      "what": "product events", "to": "planner server", "thirdParty": false,
      "purposes": ["analytics"],
      "linked": false, "tracking": false, "optional": true,
      "apple": "Usage Data / Product Interaction", "google": "App activity / App interactions"
    }
  ]
}
```

## The script

Save this as `privacy.ts`. It reads the inventory and prints what goes in each store's form,
grouped the way each store groups it, and refuses an entry that is missing an answer:

```schooling-example
{"language": "typescript", "file": "privacy.ts", "parts": [{"code": "// privacy.ts: turn the data inventory into the answers each store's privacy form asks for\nimport { readFileSync } from \"node:fs\";\n\ntype Entry = {\n  what: string; to: string; thirdParty: boolean; purposes: string[];\n  linked: boolean; tracking: boolean; optional: boolean; apple: string; google: string;\n};\nconst file = process.argv[2] ?? \"inventory.json\";\nconst inv = JSON.parse(readFileSync(file, \"utf8\")) as { app: string; encryptedInTransit: boolean; deletionOnRequest: boolean; data: Entry[] };", "note": "One type for an entry of the inventory, and the file to read, `inventory.json` unless another is named."}, {"code": "const fields = [\"what\", \"to\", \"thirdParty\", \"purposes\", \"linked\", \"tracking\", \"optional\", \"apple\", \"google\"];\nfor (const e of inv.data) {\n  const missing = fields.filter((f) => !(f in e) || (f === \"purposes\" && e.purposes.length === 0));\n  if (missing.length) {\n    console.error(`${e.what ?? \"an entry\"}: no answer for ${missing.join(\", \")}`);\n    process.exit(1);\n  }\n}", "note": "An entry with a question left unanswered stops the script. A form filled with a guess is worse than one not filled."}, {"code": "const row = (label: string, rest: string) => console.log(`    ${label.padEnd(44)} ${rest}`);\nconsole.log(`Apple, privacy details for ${inv.app}`);\nfor (const [box, pick] of [\n  [\"Data Used to Track You\", (e: Entry) => e.tracking],\n  [\"Data Linked to You\", (e: Entry) => !e.tracking && e.linked],\n  [\"Data Not Linked to You\", (e: Entry) => !e.tracking && !e.linked],\n] as const) {\n  const hits = inv.data.filter(pick);\n  console.log(`  ${box}:${hits.length ? \"\" : \" none\"}`);\n  for (const e of hits) row(e.apple, e.purposes.join(\", \"));\n}", "note": "Apple's three boxes. Tracking wins over everything; otherwise an entry is linked to the person or it is not."}, {"code": "console.log(`Google Play, Data safety for ${inv.app}`);\nfor (const e of inv.data) {\n  const how = [\"collected\", e.thirdParty ? \"shared\" : \"\", e.optional ? \"optional\" : \"\"].filter(Boolean).join(\", \");\n  row(e.google, `${how}; ${e.purposes.join(\", \")}`);\n}\nconsole.log(`  encrypted in transit: ${inv.encryptedInTransit ? \"yes\" : \"no\"}`);\nconsole.log(`  people can ask for their data to be deleted: ${inv.deletionOnRequest ? \"yes\" : \"no\"}`);", "note": "Google's form, one line per kind of data: collected, shared with a third party, optional, and why. Then the two questions about the app as a whole."}]}
```

```
ana@dev:~/planner$ node privacy.ts
Apple, privacy details for Study Planner
  Data Used to Track You: none
  Data Linked to You:
    Contact Info / Email Address                 app functionality, account management
    User Content / Other User Content            app functionality
  Data Not Linked to You:
    Diagnostics / Crash Data                     analytics
    Usage Data / Product Interaction             analytics
Google Play, Data safety for Study Planner
    Personal info / Email address                collected; app functionality, account management
    App activity / Other user-generated content  collected; app functionality
    App info and performance / Crash logs        collected, shared; analytics
    App activity / App interactions              collected, optional; analytics
  encrypted in transit: yes
  people can ask for their data to be deleted: yes
```

Read the Apple half against the three boxes of the last section. The e-mail and the sessions are
tied to the account, so they are **linked to you**; the crash reports and the product events carry
no account and a random install identifier, so they are **not linked**. Nothing is used to track,
because the planner shares nothing with an advertiser. On Google's side, the crash reports are
**shared**, because they go to a crash reporting company and not only to the planner's own server.

And the refusal: here the script reads `broken.json`, a copy of the inventory whose crash reports
have lost their purposes.

```
ana@dev:~/planner$ node privacy.ts broken.json; echo "exit status $?"
crash reports: no answer for purposes
exit status 1
```

## Where the file lives

Next to the code that sends the data, in the same repository, and part of the review of any pull
request that adds a library or a new request. **The inventory is only as true as the last pull
request that forgot it**, so one line in the review checklist, "does this send anything new off the
phone?", is what keeps it honest.
