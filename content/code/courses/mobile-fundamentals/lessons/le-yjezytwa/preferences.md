---
title: Preferences, for the few small settings
version: 1
---

**Every platform has a small key-value store for settings, and the mistake is to make it the app's
database.** It is built for a handful of values that the app reads as it starts: the tab that was
open, the theme the student chose, whether they have seen the welcome screen. It is read whole and
written whole, it has no queries, and it is not where a list of sessions that grows every day
belongs. The planner keeps two things there: the selected tab and the theme.

On Android it is **DataStore**, which Android's documentation, as read on 30 October 2026, recommends
in place of the older `SharedPreferences`. On iOS it is **`UserDefaults`**. In React Native it is
**AsyncStorage**, a library whose README describes it as unencrypted, persistent key-value storage.
Saving the theme looks like this in each; the fragments are adapted from those three sources and
**were not compiled or run for this course**:

```kotlin
val Context.settings: DataStore<Preferences> by preferencesDataStore(name = "settings")
val THEME = stringPreferencesKey("theme")

suspend fun saveTheme(context: Context, theme: String) {
    context.settings.edit { it[THEME] = theme }
}
```

```swift
// Read and written through UserDefaults.standard; the view redraws when it changes
@AppStorage("theme") var theme = "system"

Button("Dark") { theme = "dark" }
```

```tsx
import { createAsyncStorage } from "@react-native-async-storage/async-storage";

const settings = createAsyncStorage("settings");
await settings.setItem("theme", "dark");
```

**All three keep their values in a file in the app's sandbox, unencrypted.** Apple's documentation of
`UserDefaults` says so in as many words, and tells you to put personal or sensitive information in
the Keychain instead; the last section of this lesson takes that up.

## A preferences file, written safely

`prefs.ts` does what those three do for the planner, with a JSON file. Its one subtle part is how it
writes. **It never overwrites `prefs.json` in place.** It writes the new settings to `prefs.json.tmp`,
and then renames that file over the old one:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l16-atomic\" aria-label=\"Two ways to save the settings, along a time line, with the process killed at the same moment in both. Writing prefs.json in place: the file is truncated, the new text is half written when the process dies, and the file is left holding half of each, which no longer parses. Writing prefs.json.tmp and then renaming it: the process dies while the temporary file is half written, and prefs.json still holds the old settings, whole.\"><defs><marker id=\"l16-atomic-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">writing prefs.json in place</text><text x=\"20\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">writing prefs.json.tmp, then rename</text><rect x=\"20\" y=\"36\" width=\"210\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"125.0\" y=\"51.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">prefs.json</text><text x=\"125.0\" y=\"64.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">emptied</text><rect x=\"250\" y=\"36\" width=\"210\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"355.0\" y=\"51.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">half of the</text><text x=\"355.0\" y=\"64.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">new text</text><rect x=\"480\" y=\"36\" width=\"210\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"585.0\" y=\"51.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">left half-written:</text><text x=\"585.0\" y=\"64.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">it no longer parses</text><rect x=\"20\" y=\"152\" width=\"210\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"125.0\" y=\"167.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">prefs.json.tmp</text><text x=\"125.0\" y=\"180.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">half-written</text><rect x=\"250\" y=\"152\" width=\"210\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"355.0\" y=\"167.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">prefs.json</text><text x=\"355.0\" y=\"180.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">untouched</text><rect x=\"480\" y=\"152\" width=\"210\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"585.0\" y=\"167.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the old settings,</text><text x=\"585.0\" y=\"180.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">whole</text><path d=\"M230 58 L250 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-atomic-ah-paper-dim)\"></path><path d=\"M460 58 L480 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-atomic-ah-paper-dim)\"></path><path d=\"M230 174 L250 174\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-atomic-ah-paper-dim)\"></path><path d=\"M460 174 L480 174\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-atomic-ah-paper-dim)\"></path><path d=\"M355 98 L355 128\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"355\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">✕ the process is killed here</text><text x=\"360\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">rename: the old file or the new one, never half of each</text></svg>", "caption": "Killed at the same moment, the first file is broken and the second is the old settings. A rename is the one step that is never half-done."}
```

**A rename within one folder is a single step for the file system**: anyone who opens `prefs.json`
gets the old file or the new one, never half of each. Writing in place has a moment when the file
holds part of the new text and none of the old. A phone is exactly the machine where the process can
be killed at that moment, by the system reclaiming memory as lesson 4 described, or by a battery
that dies. A file you write yourself is your responsibility. Save this as `prefs.ts`:

```typescript
// prefs.ts: the planner's small settings, in a file that is never half-written
import { readFileSync, renameSync, writeFileSync } from "node:fs";

type Prefs = { tab: string; theme: string };
const FILE = "prefs.json";
const DEFAULTS: Prefs = { tab: "week", theme: "system" };

export function load(): Prefs {
  try {
    return { ...DEFAULTS, ...JSON.parse(readFileSync(FILE, "utf8")) };
  } catch {
    return DEFAULTS; // no file yet, or one that cannot be read: start from the defaults
  }
}

export function save(prefs: Prefs) {
  writeFileSync(FILE + ".tmp", JSON.stringify(prefs) + "\n");
  renameSync(FILE + ".tmp", FILE); // replaces the old file in one step
}

// `node prefs.ts` prints the settings; `node prefs.ts theme dark` changes one first.
const [key, value] = process.argv.slice(2);
if (key) save({ ...load(), [key]: value });
console.log(load());
```

**The defaults are spread first and the file second**, so a setting added in a later version of the
app, which an old file does not mention, still gets its default instead of `undefined`. Run it with
no file, change two settings, and look at what is on disk:

```
ana@dev:~/planner$ node prefs.ts
{ tab: 'week', theme: 'system' }
ana@dev:~/planner$ node prefs.ts theme dark
{ tab: 'week', theme: 'dark' }
ana@dev:~/planner$ node prefs.ts tab courses
{ tab: 'courses', theme: 'dark' }
ana@dev:~/planner$ cat prefs.json
{"tab":"courses","theme":"dark"}
ana@dev:~/planner$ ls -l prefs*
-rw-r--r-- 1 ana ana  33 Oct 30 03:27 prefs.json
-rw-r--r-- 1 ana ana 867 Oct 30 03:27 prefs.ts
```

The first run found no file and printed the defaults. Each change wrote the whole object again,
because that is the only way a file is written; `prefs.json` holds the two settings in 33 bytes, and
the `.tmp` file is gone, renamed into place. That size is the point: preferences stay small, and
anything that grows lives in the database in the next section.
