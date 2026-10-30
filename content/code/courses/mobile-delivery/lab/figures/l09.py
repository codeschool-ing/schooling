"""Lesson 9: the version script."""
P = [
    ("// version.ts: from a version name and a build number to the code both stores compare\nimport { readFileSync } from \"node:fs\";\n\nconst [name, buildArg] = [process.argv[2], process.argv[3]];\nconst build = Number(buildArg);\nconst parts = name.split(\".\").map(Number);",
     "The name as people read it, and the build counter, which the pipeline will supply in lesson 10.",
     "O nome como as pessoas o leem, e o contador de builds, que o pipeline vai fornecer na lição 10."),
    ("function refuse(why: string): never {\n  console.log(`${name} build ${build}: refused, ${why}`);\n  process.exit(1);\n}\nif (parts.length !== 3 || parts.some((p) => !Number.isInteger(p) || p < 0)) refuse(\"the name must be MAJOR.MINOR.PATCH\");\nconst [major, minor, patch] = parts;\nfor (const [part, value] of [[\"minor\", minor], [\"patch\", patch], [\"build\", build]] as const) {\n  if (!Number.isInteger(value) || value < 0 || value > 99) refuse(`${part} ${value} does not fit in two digits`);\n}",
     "A part that does not fit its two digits would spill into the next part and make a code that collides with another version.",
     "Uma parte que não cabe nos dois dígitos dela transbordaria para a parte seguinte e faria um código que colide com outra versão."),
    ("const code = major * 1_000_000 + minor * 10_000 + patch * 100 + build;\nif (code > 2_100_000_000) refuse(`${code} is over Google Play's limit`);",
     "The rule, and Google Play's largest allowed value.",
     "A regra, e o maior valor que o Google Play permite."),
    ("const { uploaded } = JSON.parse(readFileSync(\"history.json\", \"utf8\")) as { uploaded: number[] };\nif (uploaded.includes(code)) refuse(`${code} was uploaded already`);\nconst highest = Math.max(...uploaded);\nif (code < highest) refuse(`${code} is lower than ${highest}, already in the stores`);\nconsole.log(`${name} build ${build}: versionName ${name}, versionCode ${code}; iOS ${name} (${code})`);",
     "The two store rules: never twice, never lower. Then the two numbers, as each platform wants them.",
     "As duas regras das lojas: nunca duas vezes, nunca menor. Depois os dois números, como cada plataforma os quer."),
]
EXAMPLES = {"deriving-the-code": [{"language": "typescript", "file": "version.ts", "parts": P}]}
