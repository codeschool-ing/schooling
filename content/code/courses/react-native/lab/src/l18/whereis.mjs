// whereis.mjs: turn a place in the minified web bundle, as a stack trace prints it, back into the
// source file, line and name, with the bundle's source map and Node's own reader for them.
//
//   node whereis.mjs DIST index-….js:LINE:COLUMN
import { readFileSync } from "node:fs";
import { SourceMap } from "node:module";

const [dist, at] = process.argv.slice(2);
const [file, line, column] = at.split(":");
const map = new SourceMap(JSON.parse(readFileSync(`${dist}/_expo/static/js/web/${file}.map`, "utf8")));
const origin = map.findOrigin(Number(line), Number(column));
console.log(`${origin.fileName}:${origin.lineNumber}:${origin.columnNumber}`, origin.name ? `(${origin.name})` : "");
