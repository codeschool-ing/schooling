---
title: A gate before submitting
version: 1
---

**The cheapest review is the one your own computer does first.** Most of what a store rejects is
checkable without a person: a listing over its limits, a privacy answer left blank, a certificate
about to expire, a build pointing at the staging server. The lessons so far each wrote one check;
this one puts them behind a single command that says go or stop.

## What the release says about itself

A release build carries a few settings that must never reach a store in their development values.
In a real app they live in the build configuration: a Gradle build type, an Xcode scheme, an Expo
profile in `eas.json`. Here they are one small file in `~/planner`. Save this as `release.json`:

```json
{
  "version": "1.4.0",
  "build": 42,
  "apiBase": "https://staging.planner.example",
  "debugMenu": true,
  "reviewNotes": "review-notes.txt"
}
```

And the notes for the reviewer, with the demo account Apple's guideline 2.1 asks for. Save this as
`review-notes.txt`:

```
Demo account: review@planner.example / password: Review-2026
The account has three courses and six sessions, so every screen shows data.
Reminders: switch them on in Settings to see the notification permission request.
```

## The gate

Save this as `preflight.ts`. It runs the three scripts of lessons 2, 4 and 5 and reads only their
exit status, then checks the release file itself:

```schooling-example
{"language": "typescript", "file": "preflight.ts", "parts": [{"code": "// preflight.ts: everything checkable on this computer before a release is submitted\nimport { spawnSync } from \"node:child_process\";\nimport { existsSync, readFileSync } from \"node:fs\";\n\nlet stops = 0;\nconst check = (what: string, ok: boolean) => {\n  if (!ok) stops++;\n  console.log(`${ok ? \"go  \" : \"STOP\"}  ${what}`);\n};", "note": "Each check prints go or STOP, and every STOP is counted."}, {"code": "for (const [what, script, ...args] of [\n  [\"store listing within limits\", \"listing.ts\"],\n  [\"privacy inventory complete\", \"privacy.ts\"],\n  [\"no certificate expiring within 30 days\", \"expiry.ts\", \"certs\"],\n]) {\n  const run = spawnSync(\"node\", [script, ...args], { stdio: \"ignore\" });\n  check(what, run.status === 0);\n}", "note": "The three scripts of the earlier lessons, run as they are. Their output is thrown away; their exit status is the answer."}, {"code": "const release = JSON.parse(readFileSync(\"release.json\", \"utf8\"));\ncheck(`api ${release.apiBase} is production`, !/staging|localhost|127\\.0\\.0\\.1/.test(release.apiBase));\ncheck(\"debug menu is off\", release.debugMenu === false);", "note": "The two settings that must not ship in their development values."}, {"code": "const notes = existsSync(release.reviewNotes) ? readFileSync(release.reviewNotes, \"utf8\") : \"\";\ncheck(\"review notes carry a demo account\", /^demo account: \\S+/im.test(notes));\n\nconsole.log(stops ? `${stops} reason(s) to stop before submitting ${release.version} (${release.build})` : `ready to submit ${release.version} (${release.build})`);\nprocess.exitCode = stops ? 1 : 0;", "note": "The reviewer needs a way in. Then one line a person reads, and an exit status a pipeline reads."}]}
```

```
ana@dev:~/planner$ node preflight.ts; echo "exit status $?"
STOP  store listing within limits
go    privacy inventory complete
STOP  no certificate expiring within 30 days
STOP  api https://staging.planner.example is production
STOP  debug menu is off
go    review notes carry a demo account
4 reason(s) to stop before submitting 1.4.0 (42)
exit status 1
```

**Four reasons to stop, each one a rejection or a broken release that did not happen.** The listing
and the expiring certificate are lessons 4 and 2 still waiting to be fixed. The staging address
would have shipped an app talking to a server that is switched off on Sundays, the classic 2.1
rejection; the debug menu would have handed every user the switches meant for the team.

## Making it pass, and keeping it in the loop

Point `apiBase` at production, turn `debugMenu` off, and the release file's two lines go green:

```
ana@dev:~/planner$ node preflight.ts
STOP  store listing within limits
go    privacy inventory complete
STOP  no certificate expiring within 30 days
go    api https://api.planner.example is production
go    debug menu is off
go    review notes carry a demo account
2 reason(s) to stop before submitting 1.4.0 (42)
```

The other two stay red until their lessons' fixes are made, and that is the gate doing its job.
Lesson 10 runs `node preflight.ts` as a step of the release pipeline, so **nothing is submitted
while it says stop**, and lesson 11 makes it the first action of Fastlane's release lane.

## What the gate cannot see

It does not open the app. Whether the demo account still signs in, whether the build crashes on an
older phone, whether the screenshots show what this version does: those need a person or a device,
and they belong on the checklist somebody reads before pressing submit. A gate that says go means
"nothing we know how to check is wrong", which is not the same as "ready".
