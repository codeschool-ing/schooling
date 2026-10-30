// packages.mjs: add up source-map-explorer's bytes per file into bytes per package, and print the ten
// largest, with the planner's own code as one line of its own.
//
//   npx -y source-map-explorer@2.5.3 BUNDLE BUNDLE.map --no-border-checks --json | node packages.mjs
import { text } from "node:stream/consumers";

const { results } = JSON.parse(await text(process.stdin));
const [{ files, totalBytes }] = results;
const sizes = new Map();
for (const [file, { size }] of Object.entries(files)) {
  const pkg = file.match(/node_modules\/((?:@[^/]+\/)?[^/]+)\/(?!.*node_modules\/)/)?.[1]
    ?? (file.startsWith("/src/") || file.startsWith("/App") ? "(the planner)" : "(other)");
  sizes.set(pkg, (sizes.get(pkg) ?? 0) + size);
}
console.log(`${(totalBytes / 1024).toFixed(0)} KB in all`);
for (const [pkg, size] of [...sizes].sort((a, b) => b[1] - a[1]).slice(0, 10)) {
  console.log(`${(size / 1024).toFixed(0).padStart(5)} KB  ${((100 * size) / totalBytes).toFixed(1).padStart(4)}%  ${pkg}`);
}
