---
title: What the backup takes, measured
version: 1
---

**A phone's backup does not take the whole sandbox, and on Android it can take nothing at all.**
Both platforms leave out the folders that hold what can be fetched again, and Android puts a limit
on the rest. The rules are short enough to write as a program, so this section writes one and runs
it against a planner that has made the classic mistake.

## The rules, from the documentation

**Android's Auto Backup** (Android 6 and later) copies an app's private storage to the person's
Google Drive, about once a day, when the phone is idle, charging and on Wi-Fi. It leaves out
`cache/`, `code_cache/` and `no_backup/`. Its quota is **25 MB per app**, and Google's
documentation says what happens past it: the backup is not made. Not the first 25 MB; none of it.
An app chooses what to leave out with a rules file named in its manifest, `dataExtractionRules`
from Android 12 and `fullBackupContent` before it.

**iOS** backs up the container to iCloud, or to a computer, and leaves out `Library/Caches/` and
`tmp/`. There is no per-app quota; the person's iCloud storage is the limit, and the free tier is
5 GB for everything they own. A single file is left out by setting `isExcludedFromBackup` on its
URL.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 310\" role=\"img\" data-fig=\"l01-backup\" aria-label=\"Two sandboxes side by side. Android, under /data/data/&lt;package&gt;/: files, databases and shared_prefs are backed up; cache and no_backup are left out; past 25 MB nothing is backed up. iOS, the app's container: Documents, Library/Application Support and Library/Preferences are backed up; Library/Caches and tmp are left out; there is no quota per app, only the person's iCloud storage.\"><rect x=\"20\" y=\"20\" width=\"330\" height=\"270\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"36\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">Android</text><text x=\"36\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">/data/data/&lt;package&gt;/</text><rect x=\"36\" y=\"76\" width=\"200\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"46\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">files/</text><text x=\"248\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">backed up</text><rect x=\"36\" y=\"112\" width=\"200\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"46\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">databases/</text><text x=\"248\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">backed up</text><rect x=\"36\" y=\"148\" width=\"200\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"46\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shared_prefs/</text><text x=\"248\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">backed up</text><rect x=\"36\" y=\"184\" width=\"200\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"46\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cache/</text><text x=\"248\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">left out</text><rect x=\"36\" y=\"220\" width=\"200\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"46\" y=\"234\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no_backup/</text><text x=\"248\" y=\"234\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">left out</text><text x=\"36\" y=\"272\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">past 25 MB, none of it is backed up</text><rect x=\"370\" y=\"20\" width=\"330\" height=\"270\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"386\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">iOS</text><text x=\"386\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the app's container</text><rect x=\"386\" y=\"76\" width=\"200\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"396\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Documents/</text><text x=\"598\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">backed up</text><rect x=\"386\" y=\"112\" width=\"200\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"396\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Library/Application Support/</text><text x=\"598\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">backed up</text><rect x=\"386\" y=\"148\" width=\"200\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"396\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Library/Preferences/</text><text x=\"598\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">backed up</text><rect x=\"386\" y=\"184\" width=\"200\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"396\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Library/Caches/</text><text x=\"598\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">left out</text><rect x=\"386\" y=\"220\" width=\"200\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"396\" y=\"234\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tmp/</text><text x=\"598\" y=\"234\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">left out</text><text x=\"386\" y=\"272\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">no quota per app: the person's iCloud storage</text></svg>", "caption": "Where a file goes decides whether the backup takes it. The folders left out are the ones that hold what can be fetched again."}
```

## A planner that keeps a 24 MB attachment

The program below lays out a sandbox the way each platform does, with a database, a settings file,
a PDF of notes the person downloaded for the Statistics course, a cached cover picture, and one
file each platform keeps out of backup. Then it walks the folder and applies the rules. Save it as
`sandbox.ts` in `~/planner`:

```typescript
// sandbox.ts: build a planner's sandbox as each platform lays it out, and say
// what the phone's backup would take from it.
import { mkdirSync, writeFileSync, readdirSync, statSync, rmSync } from "node:fs";
import { dirname, join } from "node:path";

const MB = 1024 * 1024;
type Layout = Record<string, number>; // path inside the sandbox -> size in MB

const layouts: Record<string, Layout> = {
  android: {
    "databases/planner.db": 3,
    "shared_prefs/settings.xml": 0.01,
    "files/attachments/statistics-notes.pdf": 24,
    "cache/covers/guitar.jpg": 6,
    "no_backup/device-id": 0.01,
  },
  ios: {
    "Library/Application Support/planner.db": 3,
    "Library/Preferences/settings.plist": 0.01,
    "Documents/statistics-notes.pdf": 24,
    "Library/Caches/covers/guitar.jpg": 6,
    "tmp/upload-part-1": 2,
  },
};

// What each platform's backup leaves out by default.
const leftOut: Record<string, RegExp> = {
  android: /^(cache|code_cache|no_backup)\//, // Auto Backup, Android 6 and later
  ios: /^(Library\/Caches|tmp)\//, // iCloud and computer backups
};
const quotaMB: Record<string, number> = { android: 25, ios: Infinity };

function make(root: string, layout: Layout) {
  rmSync(root, { recursive: true, force: true });
  for (const [path, size] of Object.entries(layout)) {
    mkdirSync(dirname(join(root, path)), { recursive: true });
    writeFileSync(join(root, path), Buffer.alloc(Math.round(size * MB)));
  }
}

function walk(root: string, dir = ""): [string, number][] {
  return readdirSync(join(root, dir), { withFileTypes: true }).flatMap((e) => {
    const path = dir ? `${dir}/${e.name}` : e.name;
    return e.isDirectory() ? walk(root, path) : [[path, statSync(join(root, path)).size] as [string, number]];
  });
}

const [platform, ...excluded] = process.argv.slice(2);
const root = `sandbox-${platform}`;
make(root, layouts[platform]);
let total = 0;
for (const [path, bytes] of walk(root).sort()) {
  const skip = leftOut[platform].test(path) || excluded.some((p) => path.startsWith(p));
  if (!skip) total += bytes;
  console.log(`${skip ? "left out " : "backed up"}  ${(bytes / MB).toFixed(2).padStart(6)} MB  ${path}`);
}
const fits = total <= quotaMB[platform] * MB;
console.log(`backup: ${(total / MB).toFixed(2)} MB` + (fits ? "" : `, over the ${quotaMB[platform]} MB quota: nothing is backed up`));
```

The sizes are written out in `layouts`, and the files are filled with zeros, so the folder it makes
is the same on every computer. Run it for Android, then again leaving out the attachments folder,
which is what a rules file would do, then for iOS:

```
ana@dev:~/planner$ node sandbox.ts android
left out     6.00 MB  cache/covers/guitar.jpg
backed up    3.00 MB  databases/planner.db
backed up   24.00 MB  files/attachments/statistics-notes.pdf
left out     0.01 MB  no_backup/device-id
backed up    0.01 MB  shared_prefs/settings.xml
backup: 27.01 MB, over the 25 MB quota: nothing is backed up
ana@dev:~/planner$ node sandbox.ts android files/attachments/
left out     6.00 MB  cache/covers/guitar.jpg
backed up    3.00 MB  databases/planner.db
left out    24.00 MB  files/attachments/statistics-notes.pdf
left out     0.01 MB  no_backup/device-id
backed up    0.01 MB  shared_prefs/settings.xml
backup: 3.01 MB
ana@dev:~/planner$ node sandbox.ts ios
backed up   24.00 MB  Documents/statistics-notes.pdf
backed up    3.00 MB  Library/Application Support/planner.db
left out     6.00 MB  Library/Caches/covers/guitar.jpg
backed up    0.01 MB  Library/Preferences/settings.plist
left out     2.00 MB  tmp/upload-part-1
backup: 27.01 MB
```

**Two megabytes over the line, and the database went with the PDF.** On Android the person who
reinstalls gets an empty planner, every session they typed gone, because a file that could have
been downloaded again sat beside them. Excluding `files/attachments/` brings the backup down to
3.01 MB, and the planner comes back whole.

iOS took everything but the cache and the scratch file, PDF included. Nothing failed, and the
person pays for 24 MB of their iCloud storage to keep a document the planner could download again.
Setting `isExcludedFromBackup` on it, or putting it in `Library/Caches/`, is the fix there.

The same question settles both: **can this file be fetched again?** If it can, it does not belong
in the backup. Lesson 18 comes back to large files, and to what happens when the disk, not the
quota, runs out.
