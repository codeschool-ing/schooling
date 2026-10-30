"""Lesson 20: contract.ts."""
P = [
    ('// contract.ts: every supported version\'s contract, checked against what the server would send\nimport { readdirSync, readFileSync } from "node:fs";\n\nconst { sessions } = await import(`./${process.argv[2]}`);\nconst body: Record<string, unknown>[] = sessions();',
     "The module named on the command line builds the response. The test calls it directly, so no server has to run.",
     "O módulo dado na linha de comando monta a resposta. O teste o chama diretamente, então nenhum servidor precisa rodar."),
    ('function problems(item: Record<string, unknown>, fields: Record<string, string | string[]>): string[] {\n  const found: string[] = [];\n  for (const [field, want] of Object.entries(fields)) {\n    const value = item[field];\n    if (value === undefined) found.push(`${field} is missing`);\n    else if (Array.isArray(want)) { if (!want.includes(value as string)) found.push(`${field} "${value}" is not one of ${want.join(", ")}`); }\n    else if (typeof value !== want) found.push(`${field} is a ${typeof value}, not a ${want}`);\n  }\n  return found;\n}',
     "Three ways to break a promise: the field is gone, it holds a value the version cannot draw, or it changed type. A field the file does not list is never checked, which is what lets the server add one.",
     "Três jeitos de quebrar uma promessa: o campo sumiu, guarda um valor que a versão não sabe desenhar, ou mudou de tipo. Um campo que o arquivo não lista nunca é conferido, e é isso que deixa o servidor acrescentar um."),
    ('let failed = 0;\nfor (const file of readdirSync("contracts").sort()) {\n  const version = file.replace(/\\.json$/, "");\n  const fields = JSON.parse(readFileSync(`contracts/${file}`, "utf8"))["GET /sessions"];\n  const broken = body.flatMap((item) => problems(item, fields).map((p) => `${item.id}: ${p}`));\n  console.log(`${version}  GET /sessions  ${broken.length ? "BROKEN" : "ok"}`);\n  for (const b of broken) console.log(`  ${b}`);\n  failed += broken.length;\n}\nprocess.exitCode = failed ? 1 : 0;',
     "One line per version, every broken promise under it, and an exit status the pipeline can stop on.",
     "Uma linha por versão, cada promessa quebrada embaixo dela, e um status de saída em que o pipeline pode parar."),
]
EXAMPLES = {"a-contract-test": [{"language": "typescript", "file": "contract.ts", "parts": P}]}
