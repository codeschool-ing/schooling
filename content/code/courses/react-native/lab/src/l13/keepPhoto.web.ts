// src/keepPhoto.web.ts: a browser has no documents folder to copy into. The picked photo is a
// blob: address that lasts as long as the page, and that is what the web build keeps.
export function keepPhoto(uri: string, _course: string): string {
  return uri;
}
