// sync.ts: the phone sends its edit of s3; on a 409 it merges with the server's row and tries again.
import { merge3, type Fields } from "./merge3.ts";

const fields = ["course", "date", "minutes", "done"];
const pick = (row: Fields) => Object.fromEntries(fields.map((k) => [k, row[k]]));

// What the phone last received from the server, and the edit made on top of it, offline.
let base: Fields = { course: "guitar", date: "2026-10-21", minutes: 20, done: false };
let version = 1;
let mine: Fields = { ...base };
for (const arg of process.argv.slice(2)) {
  const [k, v] = arg.split("=");
  mine[k] = k === "minutes" ? Number(v) : v === "true";
}

for (let attempt = 1; attempt <= 3; attempt++) {
  const res = await fetch("http://localhost:8014/sessions/s3", {
    method: "PUT",
    body: JSON.stringify({ ...mine, version }),
  });
  const reply = await res.json();
  console.log(`PUT with version ${version}: ${res.status}`);
  if (res.ok) {
    console.log("saved  ", JSON.stringify(reply));
    break;
  }
  const theirs = pick(reply.current);
  const { merged, conflicts } = merge3(base, mine, theirs);
  if (conflicts.length) {
    console.log(`conflict on ${conflicts.join(", ")}: both versions kept for the person`);
    console.log(`  mine   ${JSON.stringify(pick(mine))}`);
    console.log(`  theirs ${JSON.stringify(theirs)}`);
    break;
  }
  console.log("merged ", JSON.stringify(merged));
  [base, mine, version] = [theirs, merged, reply.current.version];
}
