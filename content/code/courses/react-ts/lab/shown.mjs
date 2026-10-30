// shown.mjs LESSON_DIR FILE...: fail unless every FILE is shown in the lesson.
//
// A captures.sh puts the files ana "wrote" into ~/planner and keeps a copy of
// each one; this checks that each copy is in the lesson's prose, byte for byte,
// as the body of a fence or as the parts of a schooling-example joined the way
// the copy button joins them. So the program a lesson shows and the program
// behind its transcripts cannot drift apart.
import fs from "node:fs";
import path from "node:path";

const [dir, ...files] = process.argv.slice(2);
const bodies = new Set();
for (const f of fs.readdirSync(dir)) {
  if (!f.endsWith(".md") || f.endsWith(".pt.md")) continue;
  const text = fs.readFileSync(path.join(dir, f), "utf8");
  for (const m of text.matchAll(/^```([a-z-]*)\n([\s\S]*?)^```$/gm)) {
    const [, label, body] = m;
    if (label === "schooling-example") {
      const ex = JSON.parse(body);
      bodies.add(ex.parts.map((p) => p.code).join("\n").replace(/\n$/, ""));
    } else bodies.add(body.replace(/\n$/, ""));
  }
}
let bad = 0;
for (const f of files) {
  const want = fs.readFileSync(f, "utf8").replace(/\n$/, "");
  if (!bodies.has(want)) {
    console.error(`shown: ${path.basename(f)} is put by captures.sh and not shown whole in ${dir}`);
    bad++;
  }
}
process.exit(bad ? 1 : 0);
