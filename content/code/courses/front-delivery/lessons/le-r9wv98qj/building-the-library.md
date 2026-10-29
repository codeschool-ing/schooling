---
title: Building the library
version: 1
---

**A library is built for another build to read**, which changes what the build should produce. An app's
build makes the smallest files a browser can run. A library's makes JavaScript a consumer's bundler can
take apart, type declarations its editor and `tsc` can read, and the stylesheet as a file of its own.

Vite does the first, in **library mode**: given an entry point, it bundles the library into a single ES
module rather than an app with an `index.html`:

```typescript
// vite.config.ts
import { defineConfig } from "vite";

export default defineConfig({
  build: {
    lib: { entry: "src/index.ts", formats: ["es"], fileName: "index" },
  },
});
```

`tsc` does the second. This configuration emits only declarations, `.d.ts` files, since Vite has already
written the JavaScript:

```json
// tsconfig.json
{
  "compilerOptions": {
    "target": "es2023",
    "module": "esnext",
    "moduleResolution": "bundler",
    "lib": ["ES2023", "DOM"],
    "strict": true,
    "skipLibCheck": true,
    "declaration": true,
    "emitDeclarationOnly": true,
    "outDir": "dist",
    "rootDir": "src"
  },
  "include": ["src"]
}
```

`tsc` reads comments in its own configuration, which is why the file can carry its name on the first line
like the others. Then install the two tools, at the versions the planner uses, and build:

```
ana@dev:~/planner-ui$ npm install --save-dev --save-exact vite@8.3.5 typescript@6.0.3 2>&1 | tail -1
found 0 vulnerabilities
ana@dev:~/planner-ui$ npm run build > /dev/null && find dist -type f | sort
dist/components.d.ts
dist/format.d.ts
dist/index.d.ts
dist/index.js
dist/tokens.css
dist/types.d.ts
```

**`dist/` is what a consumer gets**: one JavaScript file of under a kilobyte, a declaration file per source
file, and the stylesheet. The build order matters, and the script says it once: Vite empties `dist/` before
it writes, so the declarations and the stylesheet go in after it.

## Look before you publish

`npm pack` builds the exact archive `npm publish` would upload. With `--dry-run` it only lists it, which is
the cheapest way to catch a file that should not be there, or one that should and is not:

```
ana@dev:~/planner-ui$ npm pack --dry-run 2>&1 | grep -E 'notice [0-9.]+k?B|total files'
npm notice 576B dist/components.d.ts
npm notice 59B dist/format.d.ts
npm notice 147B dist/index.d.ts
npm notice 834B dist/index.js
npm notice 1.4kB dist/tokens.css
npm notice 123B dist/types.d.ts
npm notice 528B package.json
npm notice total files: 7
```

Seven files, nothing else: no `src`, no `tokens.json`, no `node_modules`, because `files` names only
`dist`, and npm always adds `package.json`, a README and a licence when there are any. A library that
shipped its `.env` file or its test fixtures did so because nobody looked at this list.

Commit it, with a `.gitignore` for what is built:

```
ana@dev:~/planner-ui$ printf 'node_modules\ndist\n*.tgz\n' > .gitignore
```
