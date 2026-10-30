---
title: The torn write, and the rename that prevents it
version: 1
---

**A phone kills apps without asking, and a file being written when that happens is left half
written.** The person swipes the app away, the system needs memory for the camera, the battery
dies. The app gets no chance to finish. Whatever the file held at that instant is what the next
launch reads.

It is tempting to think the window is too short to matter. A settings file is written in well under
a millisecond. But apps save often, phones are killed often, and a few million installs multiply a
small chance into a steady stream of people who open the app to find their settings gone, or the
app crashing on start because the file no longer parses.

## Measured, by stopping on purpose

Nobody can time a kill to land mid-write, so this program stops itself instead: it writes half of
the new settings, exactly where each approach would have been writing at that moment, and then
does what the next launch does. Save it as `torn.ts` in `~/planner/prefs`:

```typescript
// torn.ts: save new settings and stop halfway through, as a process killed mid-write would.
import { closeSync, openSync, writeFileSync, writeSync } from "node:fs";
import { load } from "./kv.ts";

const mode = process.argv[2]; // "in-place" or "rename"
const path = "torn.json";
writeFileSync(path, JSON.stringify({ theme: "light", reminders: true }, null, 2) + "\n");

const next = JSON.stringify({ theme: "dark", reminders: true, dailyGoal: 45 }, null, 2) + "\n";
const half = next.slice(0, Math.floor(next.length / 2));
const target = mode === "rename" ? `${path}.tmp` : path;
const fd = openSync(target, "w"); // "w" empties the file before a byte is written
writeSync(fd, half);
closeSync(fd);
console.log(`wrote ${half.length} of ${next.length} bytes to ${target}, then stopped`);

// The next launch reads the store.
try {
  console.log("next launch reads", load(path));
} catch (e) {
  console.log("next launch fails:", (e as Error).message);
}
```

The comment on `openSync` is the whole problem. Opening a file with `"w"` **empties it first**, so
from that instant until the last byte lands, the only copy of the settings on the disk is
incomplete:

```
ana@dev:~/planner/prefs$ node torn.ts in-place
wrote 31 of 62 bytes to torn.json, then stopped
next launch fails: Unterminated string in JSON at position 31 (line 3 column 11)
ana@dev:~/planner/prefs$ node torn.ts rename
wrote 31 of 62 bytes to torn.json.tmp, then stopped
next launch reads { theme: 'light', reminders: true }
ana@dev:~/planner/prefs$ ls
grow.ts
kv.ts
settings.json
settings.ts
torn.json
torn.json.tmp
torn.ts
```

Written in place, the next launch finds 31 bytes of a 62-byte file and the parser stops at
position 31. Written beside it, the half-finished file is `torn.json.tmp`, which nothing reads, and
the real file still holds the old settings, whole. The person loses the one change they were
making, and nothing else. The next save overwrites the leftover `.tmp`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l02-torn\" aria-label=\"Two ways to save settings, each in three moments. Written in place: before, torn.json holds the old settings; the process is killed halfway, and torn.json holds 31 of 62 bytes; the next launch cannot parse it. Written beside it and renamed: before, torn.json holds the old settings; killed halfway, torn.json.tmp holds 31 bytes and torn.json is untouched; the next launch reads the old settings, whole.\"><defs><marker id=\"l02-torn-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"250\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">before the save</text><text x=\"430\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">killed halfway</text><text x=\"610\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">the next launch</text><text x=\"20\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">in place</text><rect x=\"170\" y=\"52\" width=\"160\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"250.0\" y=\"75.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">torn.json</text><text x=\"250.0\" y=\"88.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">old settings, whole</text><rect x=\"350\" y=\"52\" width=\"160\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"430.0\" y=\"75.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">torn.json</text><text x=\"430.0\" y=\"88.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">31 of 62 bytes</text><rect x=\"530\" y=\"52\" width=\"160\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"610.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">cannot be parsed</text><text x=\"20\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">beside it, then renamed</text><rect x=\"170\" y=\"162\" width=\"160\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"250.0\" y=\"185.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">torn.json</text><text x=\"250.0\" y=\"198.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">old settings, whole</text><rect x=\"350\" y=\"146\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"430.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">torn.json.tmp</text><text x=\"430.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">31 of 62 bytes</text><rect x=\"350\" y=\"196\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"430.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">torn.json</text><text x=\"430.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">old settings, untouched</text><rect x=\"530\" y=\"162\" width=\"160\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"610.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">reads the old settings</text><path d=\"M330 82 L350 82\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-torn-ah-paper-dim)\"></path><path d=\"M510 82 L530 82\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-torn-ah-paper-dim)\"></path><path d=\"M330 192 L350 192\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-torn-ah-paper-dim)\"></path><path d=\"M510 192 L530 192\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-torn-ah-paper-dim)\"></path></svg>", "caption": "Opening a file for writing empties it. Written in place, a kill leaves the only copy half written; written beside it, a kill leaves a file nothing reads."}
```

## What makes the rename safe

On Linux, Android, macOS and iOS, renaming a file over another on the same disk is **atomic**:
there is no moment at which a reader finds neither, or half of one. That is why the temporary file
goes in the same folder as the real one. A rename across two disks is a copy and a delete, and
loses the guarantee.

The platform stores already do this, which is a good reason to use them rather than writing your
own JSON file. DataStore writes to a temporary file and renames it; `SharedPreferences` keeps a
backup copy while it writes and restores it if the write did not finish. The rule still matters
for every file the app writes itself, the attachment, the export, the downloaded picture of
lesson 18: **never write over the only copy.**
