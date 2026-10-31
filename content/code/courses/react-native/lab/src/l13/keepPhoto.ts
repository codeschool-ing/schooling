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
