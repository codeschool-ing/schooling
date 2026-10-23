---
title: overrides, e engines
version: 1
---

Dois campos do `package.json` de que você vai precisar raramente, e precisar muito quando precisar.

## overrides: uma versão que você escolhe para a dependência de outra pessoa

Às vezes existe uma correção para um pacote lá no fundo da sua árvore, e o pacote que depende dele
ainda não lançou uma versão que a use. **O `overrides` troca a versão que o npm escolheria para um
pacote, onde quer que ele apareça na árvore.** No projeto de rascunho da seção anterior, ponha o
Express de volta na 4.17.1, que fixa o `qs` em exatamente 6.7.0, e force o `qs` para a mais nova:

```
ana@dev:~/server/audited$ npm install --save-exact express@4.17.1

removed 18 packages, changed 23 packages, and audited 51 packages in 536ms

1 package is looking for funding
  run `npm fund` for details

7 vulnerabilities (3 low, 4 high)

To address issues that do not require attention, run:
  npm audit fix

To address all issues, run:
  npm audit fix --force

Run `npm audit` for details.
ana@dev:~/server/audited$ npm pkg set overrides.qs=6.16.1
ana@dev:~/server/audited$ npm install

added 18 packages, changed 1 package, and audited 69 packages in 457ms

12 packages are looking for funding
  run `npm fund` for details

6 vulnerabilities (3 low, 3 high)

To address issues that do not require attention, run:
  npm audit fix

To address all issues, run:
  npm audit fix --force

Run `npm audit` for details.
ana@dev:~/server/audited$ npm ls qs
audited@ /home/ana/server/audited
└─┬ express@4.17.1
  ├─┬ body-parser@1.19.0
  │ └── qs@6.16.1 deduped
  └── qs@6.16.1 overridden

ana@dev:~/server/audited$ npm audit | grep -E '^[a-z-]+  '
body-parser  <=1.20.5
cookie  <0.7.0
path-to-regexp  <=0.1.12
send  <0.19.0
```

O `npm pkg set` escreveu o override no `package.json`:

```json
{
  "overrides": {
    "qs": "6.16.1"
  }
}
```

e depois da instalação, o `npm ls` marca a cópia que ele escolheu, e o `npm audit` não lista mais o
`qs`. **Um override é uma promessa que você faz em nome do autor de outro pacote**: a de que o código
dele funciona com uma versão que ele nunca testou. Rode os testes, anote por que o override está ali,
e remova-o quando o pai alcançar. Deixado no lugar, ele é uma versão que ninguém atualiza de
propósito.

## engines: o Node em que um projeto roda

O projeto `links` diz `"engines": { "node": ">=22" }`. Sozinho isso é uma declaração, e o npm só avisa
quando ela não é cumprida. Com o **`engine-strict`** definido no `.npmrc` do projeto, o npm se recusa a
instalar em qualquer outro Node. Para vê-lo recusar, peça um Node que esta máquina não tem, numa cópia
de rascunho:

```
ana@dev:~/server/strict$ echo '{ "name": "strict", "private": true, "engines": { "node": ">=24" } }' > package.json
ana@dev:~/server/strict$ echo engine-strict=true > .npmrc
ana@dev:~/server/strict$ npm install express@5.3.0
npm error code EBADENGINE
npm error engine Unsupported engine
npm error engine Not compatible with your version of node/npm: undefined
npm error notsup Not compatible with your version of node/npm: undefined
npm error notsup Required: {"node":">=24"}
npm error notsup Actual:   {"npm":"10.9.4","node":"v22.22.0"}
npm error A complete log of this run can be found in: /home/ana/.npm/_logs/2026-10-16T22_55_33_823Z-debug-0.log
```

**O `EBADENGINE` é a recusa**, e ele cita as duas versões. Para um servidor vale a pena ter isso: um
servidor de build com o Node errado falha na instalação, com uma mensagem, em vez de falhar na
primeira requisição que usar algo que o Node antigo não tem. Ponha `engine-strict=true` no `.npmrc` do
`links` também, ao lado do lockfile, e o `>=22` do próprio projeto passa a ser cobrado.
