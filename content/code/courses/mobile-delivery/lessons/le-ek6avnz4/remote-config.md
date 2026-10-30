---
title: Remote configuration, and the day the server is down
version: 1
---

**Remote configuration is a set of values the app reads from a server instead of from its own code,
so they can change without a release.** The minimum version of the last section is one; the planner's
others are the share of installs that see a new screen and a switch to turn it off. The design
question is not how to fetch them. **It is what the app does when it cannot.**

## Three sources, in order

1. **The server**, with a short timeout, so a slow network does not hold up the app's start, lesson 15.
2. **The last copy that worked**, cached on the device, so an app opened on a plane behaves as it did
   yesterday.
3. **Defaults compiled into the app**, for the first launch with no network, and chosen to be **safe**:
   no forced update, every new feature off.

## The planner's configuration, and a server for it

Save this in `~/planner` as `config.json`:

```json
{
  "minimumVersion": "1.5.1",
  "latestVersion": "1.6.0",
  "flags": {
    "statistics": { "rollout": 20, "killed": false }
  }
}
```

The server reads the file again at every request, so editing it is how the value changes. Save this
as `config-server.ts`, and start it in a second terminal with `node config-server.ts`:

```typescript
// config-server.ts: serves config.json as it is on disk at each request, so editing the file changes what apps get
import { createServer } from "node:http";
import { readFileSync } from "node:fs";

createServer((req, res) => {
  if (req.url !== "/config") return res.writeHead(404).end();
  res.writeHead(200, { "content-type": "application/json" }).end(readFileSync("config.json"));
}).listen(4319, "127.0.0.1");
```

## The client

Save this as `client.ts`. It is what the planner would do at start-up: load the configuration from
the three sources, decide about updating, and decide about the one feature flag, for the version and
installation given on the command line:

```schooling-example
{"language": "typescript", "file": "client.ts", "parts": [{"code": "// client.ts: what the planner does with remote config at start-up\nimport { createHash } from \"node:crypto\";\nimport { existsSync, readFileSync, writeFileSync } from \"node:fs\";\n\ntype Config = { minimumVersion: string; latestVersion: string; flags: Record<string, { rollout: number; killed: boolean }> };\nconst DEFAULTS: Config = { minimumVersion: \"0.0.0\", latestVersion: \"0.0.0\", flags: {} };\nconst [version, install] = [process.argv[2], process.argv[3] ?? \"i042\"];", "note": "The defaults are compiled in and safe: no version is too old, and no flag exists, so every new feature is off."}, {"code": "async function load(): Promise<[Config, string]> {\n  try {\n    const res = await fetch(\"http://127.0.0.1:4319/config\", { signal: AbortSignal.timeout(1500) });\n    const fresh = (await res.json()) as Config;\n    writeFileSync(\"config-cache.json\", JSON.stringify(fresh));\n    return [fresh, \"server\"];\n  } catch {\n    if (existsSync(\"config-cache.json\")) return [JSON.parse(readFileSync(\"config-cache.json\", \"utf8\")), \"cache\"];\n    return [DEFAULTS, \"defaults\"];\n  }\n}", "note": "The three sources in order: the server, with a timeout of a second and a half; the last copy that worked; the defaults. It says which one it used."}, {"code": "const older = (a: string, b: string) => {\n  const [x, y] = [a.split(\".\").map(Number), b.split(\".\").map(Number)];\n  for (let i = 0; i < 3; i++) if (x[i] !== y[i]) return x[i] < y[i];\n  return false;\n};", "note": "Versions are compared as numbers, part by part, so 1.10.0 is newer than 1.9.0."}, {"code": "export function flagOn(c: Config, flag: string, id: string): boolean {\n  const f = c.flags[flag];\n  if (!f || f.killed) return false;\n  const bucket = createHash(\"sha256\").update(`${flag}:${id}`).digest().readUInt32BE(0) % 100;\n  return bucket < f.rollout;\n}", "note": "A flag is off if it is unknown or killed; otherwise the installation's bucket, from a hash of the flag and its id, decides."}, {"code": "if (version) {\n  const [config, from] = await load();\n  const update = older(version, config.minimumVersion) ? \"must update\" : older(version, config.latestVersion) ? \"may update\" : \"up to date\";\n  console.log(`${version} (config from ${from}): ${update}; statistics ${flagOn(config, \"statistics\", install) ? \"on\" : \"off\"} for ${install}`);\n}", "note": "The decision for the version and the installation given. Without a version it only exports `flagOn`, for the next section's script."}]}
```

Run it for three versions with the server up, then stop the server, the way a server is down, and
launch twice more, the second time with no cache left:

```
ana@dev:~/planner$ node client.ts 1.5.0; node client.ts 1.5.2; node client.ts 1.6.0
1.5.0 (config from server): must update; statistics off for i042
1.5.2 (config from server): may update; statistics off for i042
1.6.0 (config from server): up to date; statistics off for i042
ana@dev:~/planner$ node client.ts 1.5.0
1.5.0 (config from cache): must update; statistics off for i042
ana@dev:~/planner$ rm config-cache.json; node client.ts 1.5.0
1.5.0 (config from defaults): up to date; statistics off for i042
```

**1.5.0 is below the minimum and must update; 1.5.2 may; 1.6.0 is up to date.** The last two lines
are the day the server is down: the first launch after it still had yesterday's configuration from
the cache, and a first launch ever, with no cache, fell back to the defaults, under which 1.5.0 is
allowed to run. That is the price of safe defaults, and it is the right price: a server outage should
never lock everybody out of the app.

## What does not belong in remote configuration

- **Secrets.** Anything the app downloads, the person can read.
- **Who may access what.** A paid feature switched on by a configuration value is switched on by
  anybody who edits their cache. Access is the server's decision, made on the server.
- **Values the code cannot survive.** A configuration that can set a timeout to 0 will one day set it
  to 0; the app validates every value against a range and falls back to its default.
