"""Lesson 6: the pre-submission gate."""
P = [
    ("// preflight.ts: everything checkable on this computer before a release is submitted\nimport { spawnSync } from \"node:child_process\";\nimport { existsSync, readFileSync } from \"node:fs\";\n\nlet stops = 0;\nconst check = (what: string, ok: boolean) => {\n  if (!ok) stops++;\n  console.log(`${ok ? \"go  \" : \"STOP\"}  ${what}`);\n};",
     "Each check prints go or STOP, and every STOP is counted.",
     "Cada checagem imprime go ou STOP, e todo STOP é contado."),
    ("for (const [what, script, ...args] of [\n  [\"store listing within limits\", \"listing.ts\"],\n  [\"privacy inventory complete\", \"privacy.ts\"],\n  [\"no certificate expiring within 30 days\", \"expiry.ts\", \"certs\"],\n]) {\n  const run = spawnSync(\"node\", [script, ...args], { stdio: \"ignore\" });\n  check(what, run.status === 0);\n}",
     "The three scripts of the earlier lessons, run as they are. Their output is thrown away; their exit status is the answer.",
     "Os três scripts das lições anteriores, rodados como estão. A saída deles é jogada fora; o status de saída é a resposta."),
    ("const release = JSON.parse(readFileSync(\"release.json\", \"utf8\"));\ncheck(`api ${release.apiBase} is production`, !/staging|localhost|127\\.0\\.0\\.1/.test(release.apiBase));\ncheck(\"debug menu is off\", release.debugMenu === false);",
     "The two settings that must not ship in their development values.",
     "As duas configurações que não podem ir com os valores de desenvolvimento."),
    ("const notes = existsSync(release.reviewNotes) ? readFileSync(release.reviewNotes, \"utf8\") : \"\";\ncheck(\"review notes carry a demo account\", /^demo account: \\S+/im.test(notes));\n\nconsole.log(stops ? `${stops} reason(s) to stop before submitting ${release.version} (${release.build})` : `ready to submit ${release.version} (${release.build})`);\nprocess.exitCode = stops ? 1 : 0;",
     "The reviewer needs a way in. Then one line a person reads, and an exit status a pipeline reads.",
     "O revisor precisa de um jeito de entrar. Depois, uma linha que uma pessoa lê, e um status de saída que um pipeline lê."),
]
EXAMPLES = {"a-gate-before-submitting": [{"language": "typescript", "file": "preflight.ts", "parts": P}]}
