---
title: Watching the expiry, with a script that runs anywhere
version: 1
---

**An expiry nobody is watching is found by the build that fails, so the fix is to have something
watch it.** The App Store Connect pages show each certificate's date, and nobody opens them on an
ordinary Tuesday. A short program that reads certificates and complains a month ahead can run
every night in the pipeline, and it needs no Mac: a certificate is a standard X.509 file, and Node
reads one with nothing installed.

## Certificates to read

Apple's certificates are exported from the Mac's Keychain as `.cer` files, and one line of
`openssl x509 -inform der -in file.cer -out file.pem` turns each into the text format the script
reads. *That step needs your real certificates and was not run for this course.* To have something
to read here, make three certificates of your own with OpenSSL, each named after a kind Apple
issues and each expiring on a different day. **They are stand-ins, signed by nobody but
themselves, and Apple would accept none of them**; only their dates matter:

```
ana@dev:~/planner/certs$ openssl req -x509 -newkey rsa:2048 -nodes -keyout dev.key -out apple-development.pem -days 200 -subj "/CN=Apple Development: Ana Souza (stand-in)" 2>/dev/null
ana@dev:~/planner/certs$ openssl req -x509 -newkey rsa:2048 -nodes -keyout dist.key -out apple-distribution.pem -days 21 -subj "/CN=Apple Distribution: Study Planner (stand-in)" 2>/dev/null
ana@dev:~/planner/certs$ openssl req -x509 -newkey rsa:2048 -nodes -keyout push.key -out apple-push.pem -days 380 -subj "/CN=Apple Push Services: com.example.planner (stand-in)" 2>/dev/null
ana@dev:~/planner/certs$ ls
apple-development.pem
apple-distribution.pem
apple-push.pem
dev.key
dist.key
push.key
```

## The script

Save this as `expiry.ts` in `~/planner`:

```schooling-example
{"language": "typescript", "file": "expiry.ts", "parts": [{"code": "// expiry.ts: which certificates in a folder expire within a month of a date?\nimport { X509Certificate } from \"node:crypto\";\nimport { readdirSync, readFileSync } from \"node:fs\";\nimport { join } from \"node:path\";", "note": "Node's own `crypto` module reads X.509 certificates; nothing is installed."}, {"code": "const folder = process.argv[2] ?? \"certs\";\nconst on = process.argv[3] ? new Date(`${process.argv[3]}T12:00:00Z`) : new Date();\nconst warnDays = 30;\nconst day = 24 * 60 * 60 * 1000;\nlet trouble = 0;", "note": "The folder, and the day to ask about. With no date it asks about now. Noon UTC keeps a date from sliding to the day before in any time zone."}, {"code": "for (const name of readdirSync(folder).filter((f) => f.endsWith(\".pem\")).sort()) {\n  const cert = new X509Certificate(readFileSync(join(folder, name)));\n  const cn = cert.subject.split(\"\\n\").find((l) => l.startsWith(\"CN=\"))?.slice(3) ?? name;", "note": "Every `.pem` file, in name order so the output is the same on every run. The subject's `CN=` line is the name Apple writes, such as *Apple Distribution: Study Planner*."}, {"code": "  const left = Math.floor((cert.validToDate.getTime() - on.getTime()) / day);\n  const state = left < 0 ? \"EXPIRED\" : left < warnDays ? \"RENEW\" : \"ok\";\n  if (state !== \"ok\") trouble++;\n  console.log(`${state.padEnd(7)} ${String(left).padStart(5)} days  ${cert.validToDate.toISOString().slice(0, 10)}  ${cn}`);\n}", "note": "Whole days left, rounded down. Under 30 is time to renew; below 0 it has already gone."}, {"code": "process.exitCode = trouble ? 1 : 0;", "note": "The exit status is the part a pipeline reads: 1 when anything needs attention."}]}
```

The date is an argument for the same reason the planner's week is in other lessons of this track:
a program that reads the clock answers differently every day, and the question "what expires
before the launch in June?" needs a date that is not today. Without one, it asks about now, and the second run asks about the first of June 2027:

```
ana@dev:~/planner$ node expiry.ts certs; echo "exit status $?"
ok        199 days  2027-05-18  Apple Development: Ana Souza (stand-in)
RENEW      20 days  2026-11-20  Apple Distribution: Study Planner (stand-in)
ok        379 days  2027-11-14  Apple Push Services: com.example.planner (stand-in)
exit status 1
ana@dev:~/planner$ node expiry.ts certs 2027-06-01
EXPIRED   -14 days  2027-05-18  Apple Development: Ana Souza (stand-in)
EXPIRED  -193 days  2026-11-20  Apple Distribution: Study Planner (stand-in)
ok        166 days  2027-11-14  Apple Push Services: com.example.planner (stand-in)
```

The `echo` after the first run prints the exit status. **The 1 is the useful part**: a pipeline step fails when a
command exits with anything but 0, so a nightly job running `node expiry.ts certs` goes red a month
before the release build would, which is the whole point. Lesson 10 adds it to the pipeline.

## What the script does not see

- **Provisioning profiles.** A profile is a signed property list, not a certificate, and its date
  is inside it as `ExpirationDate`. On a Mac, `security cms -D -i profile.mobileprovision` prints
  it as text. *Not run for this course.*
- **The membership.** It lapses on its own date, a year after enrolment, and takes the apps out of
  the store; Apple sends reminders to the account holder, which is one more reason lesson 3 says
  who that should be.
- **Keys that do not expire.** The `.p8` key App Store Connect issues for its API, and the one for
  push notifications, have no expiry date at all. They are revoked, not renewed.
