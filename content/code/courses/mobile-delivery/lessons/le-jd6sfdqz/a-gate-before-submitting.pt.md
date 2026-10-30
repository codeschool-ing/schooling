---
title: Uma barreira antes do envio
version: 1
---

**A revisão mais barata é a que o seu próprio computador faz primeiro.** A maior parte do que uma
loja recusa dá para conferir sem uma pessoa: uma ficha acima dos limites, uma resposta de
privacidade em branco, um certificado prestes a vencer, um build apontando para o servidor de
homologação. As lições até aqui escreveram, cada uma, uma checagem; esta as põe atrás de um único
comando que diz siga ou pare.

## O que o release diz de si mesmo

Um build de release leva algumas configurações que nunca podem chegar a uma loja com os valores de
desenvolvimento. Num app de verdade elas moram na configuração de build: um build type do Gradle,
um scheme do Xcode, um perfil do Expo no `eas.json`. Aqui elas são um arquivo pequeno em
`~/planner`. Salve isto como `release.json`:

```json
{
  "version": "1.4.0",
  "build": 42,
  "apiBase": "https://staging.planner.example",
  "debugMenu": true,
  "reviewNotes": "review-notes.txt"
}
```

E as notas para o revisor, com a conta de demonstração que a diretriz 2.1 da Apple pede. Salve isto
como `review-notes.txt`:

```
Demo account: review@planner.example / password: Review-2026
The account has three courses and six sessions, so every screen shows data.
Reminders: switch them on in Settings to see the notification permission request.
```

## A barreira

Salve isto como `preflight.ts`. Ele roda os três scripts das lições 2, 4 e 5 e lê só o status de
saída deles, depois confere o próprio arquivo de release:

```schooling-example
{"language": "typescript", "file": "preflight.ts", "parts": [{"code": "// preflight.ts: everything checkable on this computer before a release is submitted\nimport { spawnSync } from \"node:child_process\";\nimport { existsSync, readFileSync } from \"node:fs\";\n\nlet stops = 0;\nconst check = (what: string, ok: boolean) => {\n  if (!ok) stops++;\n  console.log(`${ok ? \"go  \" : \"STOP\"}  ${what}`);\n};", "note": "Cada checagem imprime go ou STOP, e todo STOP é contado."}, {"code": "for (const [what, script, ...args] of [\n  [\"store listing within limits\", \"listing.ts\"],\n  [\"privacy inventory complete\", \"privacy.ts\"],\n  [\"no certificate expiring within 30 days\", \"expiry.ts\", \"certs\"],\n]) {\n  const run = spawnSync(\"node\", [script, ...args], { stdio: \"ignore\" });\n  check(what, run.status === 0);\n}", "note": "Os três scripts das lições anteriores, rodados como estão. A saída deles é jogada fora; o status de saída é a resposta."}, {"code": "const release = JSON.parse(readFileSync(\"release.json\", \"utf8\"));\ncheck(`api ${release.apiBase} is production`, !/staging|localhost|127\\.0\\.0\\.1/.test(release.apiBase));\ncheck(\"debug menu is off\", release.debugMenu === false);", "note": "As duas configurações que não podem ir com os valores de desenvolvimento."}, {"code": "const notes = existsSync(release.reviewNotes) ? readFileSync(release.reviewNotes, \"utf8\") : \"\";\ncheck(\"review notes carry a demo account\", /^demo account: \\S+/im.test(notes));\n\nconsole.log(stops ? `${stops} reason(s) to stop before submitting ${release.version} (${release.build})` : `ready to submit ${release.version} (${release.build})`);\nprocess.exitCode = stops ? 1 : 0;", "note": "O revisor precisa de um jeito de entrar. Depois, uma linha que uma pessoa lê, e um status de saída que um pipeline lê."}]}
```

```
ana@dev:~/planner$ node preflight.ts; echo "exit status $?"
STOP  store listing within limits
go    privacy inventory complete
STOP  no certificate expiring within 30 days
STOP  api https://staging.planner.example is production
STOP  debug menu is off
go    review notes carry a demo account
4 reason(s) to stop before submitting 1.4.0 (42)
exit status 1
```

**Quatro motivos para parar, cada um uma recusa ou um release quebrado que não aconteceu.** A ficha
e o certificado vencendo são as lições 4 e 2 ainda esperando correção. O endereço de homologação
teria publicado um app falando com um servidor desligado aos domingos, a recusa 2.1 clássica; o
menu de debug teria entregado a todo usuário os botões feitos para a equipe.

## Fazendo passar, e mantendo no ciclo

Aponte o `apiBase` para produção, desligue o `debugMenu`, e as duas linhas do arquivo de release
ficam verdes:

```
ana@dev:~/planner$ node preflight.ts
STOP  store listing within limits
go    privacy inventory complete
STOP  no certificate expiring within 30 days
go    api https://api.planner.example is production
go    debug menu is off
go    review notes carry a demo account
2 reason(s) to stop before submitting 1.4.0 (42)
```

As outras duas ficam vermelhas até as correções das lições delas serem feitas, e isso é a barreira
fazendo o trabalho dela. A lição 10 roda `node preflight.ts` como um passo do pipeline de release,
então **nada é enviado enquanto ela disser pare**, e a lição 11 a torna a primeira ação da lane de
release do Fastlane.

## O que a barreira não enxerga

Ela não abre o app. Se a conta de demonstração ainda entra, se o build quebra num celular mais
antigo, se as capturas mostram o que esta versão faz: isso precisa de uma pessoa ou de um aparelho,
e pertence ao checklist que alguém lê antes de apertar enviar. Uma barreira que diz siga quer dizer
"nada que sabemos conferir está errado", o que não é o mesmo que "pronto".
