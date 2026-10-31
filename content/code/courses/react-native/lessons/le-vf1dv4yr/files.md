---
title: Keeping the photo in the app's own files
version: 1
---

**Every app has folders of its own, which no other app can read**, and `expo-file-system` names the two
that matter as `Paths.cache` and `Paths.document`. The cache is where the picker leaves its copy, and the
system may empty it whenever the phone needs space. The documents folder is kept until the app is
uninstalled, and on iOS it goes into the phone's backup. A photo the person chose to keep belongs there.

Save `src/keepPhoto.ts`:

```ts
// src/keepPhoto.ts: copy a picked photo out of the cache, into the app's own documents, where the
// system does not clear it. One photo per course: a new one replaces the old.
import { Directory, File, Paths } from "expo-file-system";

export function keepPhoto(uri: string, course: string): string {
  const notes = new Directory(Paths.document, "notes");
  if (!notes.exists) notes.create();
  const kept = new File(notes, `${course}.jpg`);
  if (kept.exists) kept.delete();
  new File(uri).copy(kept);
  return kept.uri;
}
```

`Directory` and `File` are references to paths, and creating one touches nothing on disk. `exists`,
`create`, `delete` and `copy` do the work, and they are synchronous: a copy of one photo is fast enough to
happen inside the press that caused it. The file is named after the course, so a second photo replaces the
first rather than piling up.

## And on the web

A browser has no documents folder for a page to write into, and `expo-file-system` does not run there.
The picker on the web returns a `blob:` address, which points at the file in the browser's memory for as
long as the page is open. Lesson 6's platform files settle it: beside `keepPhoto.ts`, save
`src/keepPhoto.web.ts`, which Metro takes instead when it builds for the web:

```ts
// src/keepPhoto.web.ts: a browser has no documents folder to copy into. The picked photo is a
// blob: address that lasts as long as the page, and that is what the web build keeps.
export function keepPhoto(uri: string, _course: string): string {
  return uri;
}
```

**So the web build keeps nothing past a reload**, which is honest about what a browser can do. *The
phone's version was checked by the TypeScript compiler, against the types `expo-file-system` 58 publishes,
and was not run: there is no phone in this course's recordings.* What a test can check is what the screen
does with the address it gets back, and that is the next section.
