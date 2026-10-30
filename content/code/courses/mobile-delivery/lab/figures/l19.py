"""Lesson 19: client.ts."""
P = [
    ("// client.ts: what the planner does with remote config at start-up\nimport { createHash } from \"node:crypto\";\nimport { existsSync, readFileSync, writeFileSync } from \"node:fs\";\n\ntype Config = { minimumVersion: string; latestVersion: string; flags: Record<string, { rollout: number; killed: boolean }> };\nconst DEFAULTS: Config = { minimumVersion: \"0.0.0\", latestVersion: \"0.0.0\", flags: {} };\nconst [version, install] = [process.argv[2], process.argv[3] ?? \"i042\"];",
     "The defaults are compiled in and safe: no version is too old, and no flag exists, so every new feature is off.",
     "Os padrões vêm compilados e são seguros: nenhuma versão é velha demais, e nenhuma flag existe, então todo recurso novo fica desligado."),
    ("async function load(): Promise<[Config, string]> {\n  try {\n    const res = await fetch(\"http://127.0.0.1:4319/config\", { signal: AbortSignal.timeout(1500) });\n    const fresh = (await res.json()) as Config;\n    writeFileSync(\"config-cache.json\", JSON.stringify(fresh));\n    return [fresh, \"server\"];\n  } catch {\n    if (existsSync(\"config-cache.json\")) return [JSON.parse(readFileSync(\"config-cache.json\", \"utf8\")), \"cache\"];\n    return [DEFAULTS, \"defaults\"];\n  }\n}",
     "The three sources in order: the server, with a timeout of a second and a half; the last copy that worked; the defaults. It says which one it used.",
     "As três fontes em ordem: o servidor, com um tempo limite de um segundo e meio; a última cópia que funcionou; os padrões. Ele diz qual usou."),
    ("const older = (a: string, b: string) => {\n  const [x, y] = [a.split(\".\").map(Number), b.split(\".\").map(Number)];\n  for (let i = 0; i < 3; i++) if (x[i] !== y[i]) return x[i] < y[i];\n  return false;\n};",
     "Versions are compared as numbers, part by part, so 1.10.0 is newer than 1.9.0.",
     "As versões são comparadas como números, parte por parte, então 1.10.0 é mais nova que 1.9.0."),
    ("export function flagOn(c: Config, flag: string, id: string): boolean {\n  const f = c.flags[flag];\n  if (!f || f.killed) return false;\n  const bucket = createHash(\"sha256\").update(`${flag}:${id}`).digest().readUInt32BE(0) % 100;\n  return bucket < f.rollout;\n}",
     "A flag is off if it is unknown or killed; otherwise the installation's bucket, from a hash of the flag and its id, decides.",
     "Uma flag fica desligada se for desconhecida ou morta; fora isso, o balde da instalação, de um hash da flag e do id dela, decide."),
    ("if (version) {\n  const [config, from] = await load();\n  const update = older(version, config.minimumVersion) ? \"must update\" : older(version, config.latestVersion) ? \"may update\" : \"up to date\";\n  console.log(`${version} (config from ${from}): ${update}; statistics ${flagOn(config, \"statistics\", install) ? \"on\" : \"off\"} for ${install}`);\n}",
     "The decision for the version and the installation given. Without a version it only exports `flagOn`, for the next section's script.",
     "A decisão para a versão e a instalação dadas. Sem versão, ele só exporta o `flagOn`, para o script da próxima seção."),
]
EXAMPLES = {"remote-config": [{"language": "typescript", "file": "client.ts", "parts": P}]}
