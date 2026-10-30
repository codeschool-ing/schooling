// extract.mjs MD NAME: print the program a lesson shows under NAME.
//
// The programs the student is given (page.mjs, serve.mjs, api.mjs,
// devtools.mjs, the registry's packages) are shown whole in a lesson, in a
// fence whose first line is "// NAME: ..." or "# NAME: ...". The lab runs
// exactly that text, so the program in the lesson and the program behind
// the transcripts cannot drift apart. A name found zero times, or twice, is
// an error.
import fs from "node:fs";

const [md, name] = process.argv.slice(2);
const text = fs.readFileSync(md, "utf8");
const found = [];
for (const m of text.matchAll(/^```[a-z]*\n([\s\S]*?)^```$/gm)) {
  const first = m[1].split("\n", 1)[0];
  if (first.startsWith(`// ${name}:`) || first.startsWith(`# ${name}:`)) found.push(m[1]);
}
if (found.length !== 1) {
  console.error(`extract: ${name} is shown ${found.length} times in ${md}, and must be shown once`);
  process.exit(1);
}
process.stdout.write(found[0]);
