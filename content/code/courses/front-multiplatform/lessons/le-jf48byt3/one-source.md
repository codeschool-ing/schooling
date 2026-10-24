---
title: One version, written once
version: 1
---

**The version lives in `package.json`, and everything else is copied from it.** `npm version` already knows how
to move it: `npm version minor` turns `0.1.0` into `0.2.0`, commits the change, and tags the commit `v0.2.0`.
What it does not know is that two native projects carry a copy. So the copy is made by a script that npm runs
at the right moment.

Tauri needs no script: its `version` may name a file instead of a number, and `"../package.json"` makes it read
the version from there at every build. The phones need one, and here it is, in `scripts/version.mjs`:

```javascript
// scripts/version.mjs: copy the version in package.json into the Android and iOS projects.
import fs from "node:fs";

const { version } = JSON.parse(fs.readFileSync("package.json", "utf8"));
const match = /^(\d+)\.(\d+)\.(\d+)$/.exec(version);
if (!match) throw new Error(`not a version this script understands: ${version}`);
const [major, minor, patch] = match.slice(1).map(Number);
if (minor > 99 || patch > 99) throw new Error(`${version}: minor and patch must stay below 100`);
// The number for the system grows with the version: 1.2.3 becomes 10203.
const build = major * 10000 + minor * 100 + patch;

function edit(file, changes) {
  let text = fs.readFileSync(file, "utf8");
  for (const [pattern, replacement] of changes) {
    if (!text.match(pattern)) throw new Error(`${file}: nothing matches ${pattern}`);
    text = text.replace(pattern, replacement);
  }
  fs.writeFileSync(file, text);
}

edit("android/app/build.gradle", [
  [/versionCode \d+/, `versionCode ${build}`],
  [/versionName "[^"]*"/, `versionName "${version}"`],
]);
edit("ios/App/App.xcodeproj/project.pbxproj", [
  [/MARKETING_VERSION = [^;]+;/g, `MARKETING_VERSION = ${version};`],
  [/CURRENT_PROJECT_VERSION = [^;]+;/g, `CURRENT_PROJECT_VERSION = ${build};`],
]);
console.log(`version ${version}, build ${build}`);
```

**The build number is worked out from the version**, so it grows whenever the version does and never has to be
remembered: `0.2.0` is 200, `1.0.0` is 10000, `1.2.3` is 10203. The price is the second check at the top: a minor
or a patch of 100 would collide with the next major, so the script refuses one rather than produce a number that
goes backwards. **Every edit refuses to match nothing**, too: a template that changes its spelling would otherwise
leave the old number in place, silently.

`npm version` runs a script called `version` after it has changed `package.json` and before it commits, and
whatever that script stages goes into the same commit. So two lines wire it in, and the tree is committed first,
because `npm version` refuses to run with uncommitted changes:

```
ana@dev:~/planner$ sed -i 's|"version": "0.1.0"|"version": "../package.json"|' src-tauri/tauri.conf.json
ana@dev:~/planner$ npm pkg set scripts.version="node scripts/version.mjs && git add android ios"
ana@dev:~/planner$ git add . && git commit -q -m "One version, in package.json" && git log --oneline -1
b876c9c One version, in package.json
```

Then a release is one command:

```
ana@dev:~/planner$ npm version minor

> version
> node scripts/version.mjs && git add android ios

version 0.2.0, build 200
v0.2.0
ana@dev:~/planner$ grep -n "versionCode\|versionName" android/app/build.gradle
10:        versionCode 200
11:        versionName "0.2.0"
ana@dev:~/planner$ grep -c "MARKETING_VERSION = 0.2.0;" ios/App/App.xcodeproj/project.pbxproj
2
ana@dev:~/planner$ git log --oneline -2 && git tag
7519a04 0.2.0
b876c9c One version, in package.json
v0.2.0
```

**One command moved four files and made a tag.** `v0.2.0` is the name lesson 16's release is built from, and the
build number 200 is higher than the template's 1, so a store that had seen the old one would take it. The
Tauri app reads the same `0.2.0` from `package.json` the next time it is built.
