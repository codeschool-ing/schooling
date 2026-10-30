---
title: Caching, and the key that decides it
version: 1
---

**A mobile build downloads a great deal before it compiles anything**: Gradle's dependencies and its
own distribution, the npm packages of a React Native project, CocoaPods or Swift packages for iOS.
On a fresh runner every run downloads all of it again. A cache saves those folders at the end of a
run and restores them at the start of the next, and **the whole design of a cache is the key** under
which it is saved.

## What a key must do

- **Change when what was downloaded would change.** That is when a lockfile changes:
  `package-lock.json`, `gradle/libs.versions.toml` and the wrapper's properties, `Podfile.lock`,
  `Package.resolved`.
- **Not change for anything else.** Editing a source file must not throw away a perfectly good cache
  of dependencies.
- **Say which system it is for**: a cache of native modules built on Linux restored on a Mac is
  worse than none.

So the usual key is the operating system plus a hash of the lockfiles. GitHub Actions writes it as
`${{ runner.os }}-npm-${{ hashFiles('**/package-lock.json') }}`, and the next script computes the
same kind of key, on your computer, to show when it changes.

## A cache key, computed

Save this as `cachekey.ts` in `~/planner`:

```typescript
// cachekey.ts: the cache key a pipeline would use, from the operating system and the lockfiles
import { createHash } from "node:crypto";
import { readFileSync } from "node:fs";
import { platform } from "node:os";

const files = process.argv.slice(2);
const hash = createHash("sha256");
for (const f of files.sort()) hash.update(readFileSync(f));
console.log(`${platform()}-deps-${hash.digest("hex").slice(0, 12)}`);
```

Then ask for the key, change a source file, ask again, add a dependency, ask again, and remove it:

```
ana@dev:~/planner$ node cachekey.ts package-lock.json
linux-deps-9ce97dd3ef27
ana@dev:~/planner$ echo "// a source change" >> check.ts && node cachekey.ts package-lock.json
linux-deps-9ce97dd3ef27
ana@dev:~/planner$ npm install -E dayjs@1.11.13 --silent && node cachekey.ts package-lock.json
linux-deps-00ced0936e82
ana@dev:~/planner$ npm uninstall dayjs --silent && node cachekey.ts package-lock.json
linux-deps-9ce97dd3ef27
```

**The key moved only when the lockfile did**, and came back to the first value when the lockfile
did. That last line is the property that makes a cache trustworthy: the key is a function of the
lockfile's contents, not of time or of which run produced it.

## What not to cache

- **Build outputs between unrelated commits.** Gradle's build cache can be shared safely because it
  keys every task by its inputs; a folder of compiled classes saved by hand cannot.
- **Anything holding a secret.** A cache is readable by later runs, including runs from pull requests
  in some configurations; a keystore restored from a cache is a keystore published.
- **The signed artefact.** It is uploaded as a build artefact or straight to the store, where its
  retention is decided on purpose.
