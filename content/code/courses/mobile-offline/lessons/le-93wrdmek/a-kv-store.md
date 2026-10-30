---
title: A key-value store of your own
version: 1
---

**A key-value store is a dictionary that outlives the program, and the hard part is the one line
that writes it.** Reading is trivial: parse a file. Writing has to survive the app being killed in
the middle, and the next section shows what happens when it does not. This one builds the store
the planner uses for the rest of the course.

Make the lesson's folder, `~/planner/prefs`, and save this in it as `kv.ts`:

```typescript
// kv.ts: a key-value store in one JSON file, the shape SharedPreferences and UserDefaults have.
import { closeSync, existsSync, fsyncSync, openSync, readFileSync, renameSync, writeSync } from "node:fs";

export type Prefs = Record<string, string | number | boolean>;

// Read the whole file. A missing file is an empty store; a damaged one is an error, not {}.
export function load(path: string): Prefs {
  if (!existsSync(path)) return {};
  return JSON.parse(readFileSync(path, "utf8")) as Prefs;
}

// Write the new contents beside the file, push them to the disk, then rename over the old one.
// A rename replaces the file in one step, so a reader finds the old version or the new one.
export function save(path: string, prefs: Prefs): number {
  const text = JSON.stringify(prefs, null, 2) + "\n";
  const tmp = `${path}.tmp`;
  const fd = openSync(tmp, "w");
  writeSync(fd, text);
  fsyncSync(fd);
  closeSync(fd);
  renameSync(tmp, path);
  return Buffer.byteLength(text);
}
```

Two decisions in it are worth reading twice.

**A missing file and a damaged file are different answers.** A missing file means the app has never
saved a setting, and an empty store is the truth. A file that does not parse means something went
wrong, and returning `{}` would quietly reset the person's settings to the defaults with no record
of why. So `load` lets the parser's error reach the caller, which decides. Android's DataStore makes
the same distinction: a file it cannot read raises `CorruptionException`, and an app that wants to
start over says so with a `ReplaceFileCorruptionHandler`.

**`save` never writes the file it is replacing.** It writes `settings.json.tmp`, asks the operating
system to push those bytes to the disk with `fsyncSync`, and only then renames the temporary file
over the real one. Without the `fsync`, the rename can reach the disk before the data does, and a
power cut leaves a new name on an empty file.

Now a program that uses it. Save this as `settings.ts`:

```typescript
// settings.ts: the planner's settings, read and written through kv.ts.
import { load, save } from "./kv.ts";

const path = "settings.json";
const [command, key, value] = process.argv.slice(2);
const prefs = load(path);

if (command === "set") {
  prefs[key] = value === "true" ? true : value === "false" ? false : isNaN(Number(value)) ? value : Number(value);
  console.log(`saved ${save(path, prefs)} bytes`);
} else if (command === "get") {
  console.log(key in prefs ? prefs[key] : `(no ${key})`);
} else {
  console.log(prefs);
}
```

`set` turns `true`, `false` and anything numeric into the right type, so `dailyGoal` comes back as
the number 45 and not the string `"45"`:

```
ana@dev:~/planner/prefs$ node settings.ts set theme dark
saved 22 bytes
ana@dev:~/planner/prefs$ node settings.ts set dailyGoal 45
saved 41 bytes
ana@dev:~/planner/prefs$ node settings.ts get theme
dark
ana@dev:~/planner/prefs$ node settings.ts get dailyGoal
45
ana@dev:~/planner/prefs$ node settings.ts
{ theme: 'dark', dailyGoal: 45 }
ana@dev:~/planner/prefs$ cat settings.json
{
  "theme": "dark",
  "dailyGoal": 45
}
```

The file is ordinary JSON, and that is a feature: during development you can open it and read it.
On a phone the equivalent is `shared_prefs/settings.xml` or the property list in
`Library/Preferences/`, which Android Studio's device explorer and Xcode's container download let
you open the same way.
