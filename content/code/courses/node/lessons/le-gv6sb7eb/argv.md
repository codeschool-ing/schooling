---
title: Command-line arguments
version: 1
---

**A server reads the environment; a tool someone runs by hand reads its command line.** `process.argv`
is the list of words typed, starting with the path to `node` and the path to the script, and
`util.parseArgs` from `node:util` turns the rest into named options, with no package needed.

A small tool for whoever runs the links service counts the links in a data file:

```schooling-example
{"language": "javascript", "file": "count.js", "parts": [
 {"code": "// count.js: how many links a data file holds, and how many visits they had.\nimport { readFile } from \"node:fs/promises\";\nimport { parseArgs } from \"node:util\";\n\nconst { values } = parseArgs({\n  options: {\n    file: { type: \"string\", short: \"f\", default: process.env.DATA_FILE ?? \"data/links.json\" },\n    min: { type: \"string\", default: \"0\" },\n    help: { type: \"boolean\", short: \"h\" },\n  },\n  strict: true,\n});", "note": "**Declare the options**: their types, short letters and defaults. `strict` makes an unknown option an error instead of something silently ignored."},
 {"code": "if (values.help) {\n  console.log(\"usage: node count.js [--file FILE] [--min VISITS]\");\n  process.exit(0);\n}", "note": "`--help` answers and stops, as every tool should."},
 {"code": "const links = JSON.parse(await readFile(values.file, \"utf8\"));\nconst min = Number(values.min);\nconst chosen = links.filter((l) => l.visits >= min);\nconsole.log(`${chosen.length} of ${links.length} links with at least ${min} visits in ${values.file}`);", "note": "**Flags win over the environment, which wins over the default**: `--file` if given, otherwise `DATA_FILE`, otherwise `data/links.json`."}
]}
```

```
ana@dev:~/server/links$ node count.js --help
usage: node count.js [--file FILE] [--min VISITS]
ana@dev:~/server/links$ node count.js
3 of 3 links with at least 0 visits in data/links.json
ana@dev:~/server/links$ node count.js --min 1
1 of 3 links with at least 1 visits in data/links.json
ana@dev:~/server/links$ node count.js --file test/tmp/links.json
3 of 3 links with at least 0 visits in test/tmp/links.json
ana@dev:~/server/links$ node count.js --minimum 1 2>&1 | grep TypeError
TypeError [ERR_PARSE_ARGS_UNKNOWN_OPTION]: Unknown option '--minimum'
```

**An option that does not exist is refused with its name**, which a tool that only scanned
`process.argv` by hand would have ignored, running with defaults the user did not choose. The order of
precedence — flag, then environment, then default — is the usual one for tools, and it is the same
order `--env-file` follows: whoever is closest to the command decides.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Four places a setting can come from, from farthest to closest to the command: the default in the code, a .env file, the real environment, and a command-line flag. Each one closer to the command overrides the ones before it.\"><rect x=\"20\" y=\"50\" width=\"160\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the default in the code</text><text x=\"100\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">?? \"data/links.json\"</text><line x1=\"180\" y1=\"90\" x2=\"190\" y2=\"90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"190.0,90.0 182.6,93.1 182.6,86.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"192\" y=\"50\" width=\"160\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"272\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a .env file</text><text x=\"272\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">--env-file=.env</text><line x1=\"352\" y1=\"90\" x2=\"362\" y2=\"90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"362.0,90.0 354.6,93.1 354.6,86.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"364\" y=\"50\" width=\"160\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"444\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the real environment</text><text x=\"444\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">DATA_FILE=… node</text><line x1=\"524\" y1=\"90\" x2=\"534\" y2=\"90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"534.0,90.0 526.6,93.1 526.6,86.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"536\" y=\"50\" width=\"160\" height=\"80\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"616\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">a flag on the command line</text><text x=\"616\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">--file …</text><line x1=\"20\" y1=\"160\" x2=\"700\" y2=\"160\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"700.0,160.0 692.6,163.1 692.6,156.9\" fill=\"var(--amber)\"></polygon><text x=\"700\" y=\"178\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">closer to the command: it wins</text><text x=\"20\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">farther: used only if nothing else says</text></svg>", "caption": "Whoever is closest to the command decides; a default is only the last resort."}
```
