---
title: Deriving the code from the name
version: 1
---

**A version code typed by hand is a version code somebody will one day type wrong.** The common cure
is a rule: the code is computed from the version name and a build counter, so the name decides the
code and nobody chooses it. The planner uses the simplest rule that keeps the order:

```localised
versionCode = MAJOR × 1,000,000 + MINOR × 10,000 + PATCH × 100 + BUILD

1.5.0, build 3   →   1 × 1,000,000 + 5 × 10,000 + 0 × 100 + 3   =   1050003
```

Two digits each for minor, patch and build: up to 99 of each, which is plenty for an app, and the
largest code the rule can make for major 2099 stays under Google's 2,100,000,000. The same integer is
used as the iOS build number, so one number names the build on both platforms.

## What has shipped

The rule alone cannot know what is already in the stores. The planner keeps that in a file, the
codes uploaded so far, in order. Save this as `history.json`:

```json
{ "uploaded": [1040001, 1040002, 1050001, 1050002] }
```

## The script

Save this as `version.ts`. It takes a version name and a build number, computes the code, and refuses
a part that is out of range, a code already used, or a code lower than the highest one uploaded:

```schooling-example
{"language": "typescript", "file": "version.ts", "parts": [{"code": "// version.ts: from a version name and a build number to the code both stores compare\nimport { readFileSync } from \"node:fs\";\n\nconst [name, buildArg] = [process.argv[2], process.argv[3]];\nconst build = Number(buildArg);\nconst parts = name.split(\".\").map(Number);", "note": "The name as people read it, and the build counter, which the pipeline will supply in lesson 10."}, {"code": "function refuse(why: string): never {\n  console.log(`${name} build ${build}: refused, ${why}`);\n  process.exit(1);\n}\nif (parts.length !== 3 || parts.some((p) => !Number.isInteger(p) || p < 0)) refuse(\"the name must be MAJOR.MINOR.PATCH\");\nconst [major, minor, patch] = parts;\nfor (const [part, value] of [[\"minor\", minor], [\"patch\", patch], [\"build\", build]] as const) {\n  if (!Number.isInteger(value) || value < 0 || value > 99) refuse(`${part} ${value} does not fit in two digits`);\n}", "note": "A part that does not fit its two digits would spill into the next part and make a code that collides with another version."}, {"code": "const code = major * 1_000_000 + minor * 10_000 + patch * 100 + build;\nif (code > 2_100_000_000) refuse(`${code} is over Google Play's limit`);", "note": "The rule, and Google Play's largest allowed value."}, {"code": "const { uploaded } = JSON.parse(readFileSync(\"history.json\", \"utf8\")) as { uploaded: number[] };\nif (uploaded.includes(code)) refuse(`${code} was uploaded already`);\nconst highest = Math.max(...uploaded);\nif (code < highest) refuse(`${code} is lower than ${highest}, already in the stores`);\nconsole.log(`${name} build ${build}: versionName ${name}, versionCode ${code}; iOS ${name} (${code})`);", "note": "The two store rules: never twice, never lower. Then the two numbers, as each platform wants them."}]}
```

```
ana@dev:~/planner$ node version.ts 1.5.0 3
1.5.0 build 3: versionName 1.5.0, versionCode 1050003; iOS 1.5.0 (1050003)
ana@dev:~/planner$ node version.ts 1.4.1 1
1.4.1 build 1: refused, 1040101 is lower than 1050002, already in the stores
ana@dev:~/planner$ node version.ts 1.5.0 2
1.5.0 build 2: refused, 1050002 was uploaded already
ana@dev:~/planner$ node version.ts 1.5.100 1
1.5.100 build 1: refused, patch 100 does not fit in two digits
```

**The 1.4.1 is the failure of the last section**, caught before anything was uploaded. Its code,
1040101, is a perfectly valid number and lower than the 1050002 already in the stores. The 1.5.0 build
2 is refused for the other reason: that exact build was uploaded already. And a patch of 100 does not
fit the rule's two digits, so the script says so rather than producing a code that collides with
1.6.0.

## In a real build

The same arithmetic goes where each platform reads its numbers: a few lines in `build.gradle.kts`
computing `versionCode` from `versionName` and an environment variable the pipeline sets; a build
phase in Xcode, or Fastlane's `increment_build_number`; a step in EAS or in `app.config.js` for
Expo. **The build counter comes from the pipeline**, lesson 10, where every run already has a number
of its own, and the history check runs against what the stores report rather than a file. *Those
three were not built for this course.*
