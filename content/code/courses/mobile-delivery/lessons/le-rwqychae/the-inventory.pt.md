---
title: O inventário, e as respostas feitas a partir dele
version: 1
---

**Os formulários são preenchidos de memória na maioria das equipes, e a memória é a fonte
errada.** Um formulário preenchido no dia do lançamento e nunca mais aberto descreve um app que já
não existe no terceiro release. A solução é guardar a resposta onde o código está: um arquivo que
lista todo tipo de dado que o app manda para qualquer lugar, revisado sempre que o código que o
manda muda.

## Os dados do planner

O planner faz login com um endereço de e-mail, guarda os cursos e as sessões no servidor para que
sincronizem entre aparelhos, manda relatórios de crash por um coletor de crashes, que é a lição 12,
e registra alguns eventos de produto, que é a lição 16. Cada entrada abaixo diz o que é, quem
recebe, para que serve e como cada loja a chama. Salve isto em `~/planner` como `inventory.json`:

```json
{
  "app": "Study Planner",
  "encryptedInTransit": true,
  "deletionOnRequest": true,
  "data": [
    {
      "what": "e-mail address", "to": "planner server", "thirdParty": false,
      "purposes": ["app functionality", "account management"],
      "linked": true, "tracking": false, "optional": false,
      "apple": "Contact Info / Email Address", "google": "Personal info / Email address"
    },
    {
      "what": "courses and sessions", "to": "planner server", "thirdParty": false,
      "purposes": ["app functionality"],
      "linked": true, "tracking": false, "optional": false,
      "apple": "User Content / Other User Content", "google": "App activity / Other user-generated content"
    },
    {
      "what": "crash reports", "to": "crash reporting service", "thirdParty": true,
      "purposes": ["analytics"],
      "linked": false, "tracking": false, "optional": false,
      "apple": "Diagnostics / Crash Data", "google": "App info and performance / Crash logs"
    },
    {
      "what": "product events", "to": "planner server", "thirdParty": false,
      "purposes": ["analytics"],
      "linked": false, "tracking": false, "optional": true,
      "apple": "Usage Data / Product Interaction", "google": "App activity / App interactions"
    }
  ]
}
```

## O script

Salve isto como `privacy.ts`. Ele lê o inventário e imprime o que vai no formulário de cada loja,
agrupado do jeito que cada loja agrupa, e recusa uma entrada a que falte uma resposta:

```schooling-example
{"language": "typescript", "file": "privacy.ts", "parts": [{"code": "// privacy.ts: turn the data inventory into the answers each store's privacy form asks for\nimport { readFileSync } from \"node:fs\";\n\ntype Entry = {\n  what: string; to: string; thirdParty: boolean; purposes: string[];\n  linked: boolean; tracking: boolean; optional: boolean; apple: string; google: string;\n};\nconst file = process.argv[2] ?? \"inventory.json\";\nconst inv = JSON.parse(readFileSync(file, \"utf8\")) as { app: string; encryptedInTransit: boolean; deletionOnRequest: boolean; data: Entry[] };", "note": "Um tipo para uma entrada do inventário, e o arquivo a ler, `inventory.json` se nenhum outro for nomeado."}, {"code": "const fields = [\"what\", \"to\", \"thirdParty\", \"purposes\", \"linked\", \"tracking\", \"optional\", \"apple\", \"google\"];\nfor (const e of inv.data) {\n  const missing = fields.filter((f) => !(f in e) || (f === \"purposes\" && e.purposes.length === 0));\n  if (missing.length) {\n    console.error(`${e.what ?? \"an entry\"}: no answer for ${missing.join(\", \")}`);\n    process.exit(1);\n  }\n}", "note": "Uma entrada com uma pergunta sem resposta para o script. Um formulário preenchido com um palpite é pior do que um não preenchido."}, {"code": "const row = (label: string, rest: string) => console.log(`    ${label.padEnd(44)} ${rest}`);\nconsole.log(`Apple, privacy details for ${inv.app}`);\nfor (const [box, pick] of [\n  [\"Data Used to Track You\", (e: Entry) => e.tracking],\n  [\"Data Linked to You\", (e: Entry) => !e.tracking && e.linked],\n  [\"Data Not Linked to You\", (e: Entry) => !e.tracking && !e.linked],\n] as const) {\n  const hits = inv.data.filter(pick);\n  console.log(`  ${box}:${hits.length ? \"\" : \" none\"}`);\n  for (const e of hits) row(e.apple, e.purposes.join(\", \"));\n}", "note": "As três caixas da Apple. Rastreamento vence tudo; fora isso, uma entrada está ligada à pessoa ou não está."}, {"code": "console.log(`Google Play, Data safety for ${inv.app}`);\nfor (const e of inv.data) {\n  const how = [\"collected\", e.thirdParty ? \"shared\" : \"\", e.optional ? \"optional\" : \"\"].filter(Boolean).join(\", \");\n  row(e.google, `${how}; ${e.purposes.join(\", \")}`);\n}\nconsole.log(`  encrypted in transit: ${inv.encryptedInTransit ? \"yes\" : \"no\"}`);\nconsole.log(`  people can ask for their data to be deleted: ${inv.deletionOnRequest ? \"yes\" : \"no\"}`);", "note": "O formulário do Google, uma linha por tipo de dado: coletado, compartilhado com terceiros, opcional, e por quê. Depois as duas perguntas sobre o app inteiro."}]}
```

```
ana@dev:~/planner$ node privacy.ts
Apple, privacy details for Study Planner
  Data Used to Track You: none
  Data Linked to You:
    Contact Info / Email Address                 app functionality, account management
    User Content / Other User Content            app functionality
  Data Not Linked to You:
    Diagnostics / Crash Data                     analytics
    Usage Data / Product Interaction             analytics
Google Play, Data safety for Study Planner
    Personal info / Email address                collected; app functionality, account management
    App activity / Other user-generated content  collected; app functionality
    App info and performance / Crash logs        collected, shared; analytics
    App activity / App interactions              collected, optional; analytics
  encrypted in transit: yes
  people can ask for their data to be deleted: yes
```

Leia a metade da Apple contra as três caixas da seção anterior. O e-mail e as sessões estão
ligados à conta, então são **linked to you**; os relatórios de crash e os eventos de produto não
levam conta nenhuma, só um identificador de instalação aleatório, então são **not linked**. Nada é
usado para rastrear, porque o planner não compartilha nada com anunciante. Do lado do Google, os
relatórios de crash são **compartilhados**, porque vão para uma empresa de relatórios de crash e
não só para o servidor do próprio planner.

E a recusa: aqui o script lê `broken.json`, uma cópia do inventário em que os relatórios de crash
perderam as finalidades.

```
ana@dev:~/planner$ node privacy.ts broken.json; echo "exit status $?"
crash reports: no answer for purposes
exit status 1
```

## Onde o arquivo mora

Junto do código que manda os dados, no mesmo repositório, e como parte da revisão de todo pull
request que acrescenta uma biblioteca ou uma requisição nova. **O inventário só é tão verdadeiro
quanto o último pull request que se esqueceu dele**, então uma linha no checklist de revisão, "isto
manda alguma coisa nova para fora do celular?", é o que o mantém honesto.
