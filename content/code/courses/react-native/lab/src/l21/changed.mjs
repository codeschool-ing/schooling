// changed.mjs: read fingerprint:diff's answer and print one line per native source that changed.
//
//   npx @expo/fingerprint fingerprint:diff A.json B.json | node changed.mjs
import { text } from "node:stream/consumers";

for (const d of JSON.parse(await text(process.stdin))) {
  const s = d.afterSource ?? d.addedSource ?? d.beforeSource ?? d.removedSource ?? d.source;
  console.log(d.op.padEnd(8), s.type.padEnd(9), s.filePath ?? s.id ?? s.name);
}
