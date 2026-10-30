---
title: Dois números em toda versão
version: 1
---

**Todo build leva dois números: um que as pessoas leem, e um que a loja compara.** O erro comum é
achar que existe um número de versão. São dois em cada plataforma, eles fazem trabalhos diferentes,
e só um deles pode fazer outra coisa além de crescer.

| | o número que as pessoas leem | o número que a loja compara |
|---|---|---|
| Android | `versionName`, um texto como `1.10.0` | `versionCode`, um inteiro positivo |
| iOS | `CFBundleShortVersionString`, como `1.10.0` | `CFBundleVersion`, o número de build |

**O `versionCode` do Android é o rigoroso.** A documentação do Android sobre versionamento, lida em 30
de outubro de 2026, o chama de "um inteiro positivo usado como número de versão interno" e diz que "números maiores" indicam "versões mais recentes". O sistema o usa "para proteger contra
rebaixamentos, impedindo que usuários instalem um APK com versionCode menor do que o da versão
instalada". O Play acrescenta duas regras: "você não pode enviar à Play Store um APK com um
versionCode que já usou", e "o maior valor que o Google Play aceita para versionCode é 2100000000". A
prática comum que ela descreve é começar em 1 e somar um a cada versão, menor ou maior, e é por isso
que o código "não necessariamente se parece com a versão que o usuário vê". O `versionName` é "o único
valor mostrado aos usuários", e o Android não o compara de jeito nenhum.

**As duas chaves do iOS são feitas de números e pontos.** A documentação da Apple descreve o
`CFBundleShortVersionString` como "um texto visível ao usuário" cujo "formato exigido são três
inteiros separados por pontos, como 10.14.1", e o `CFBundleVersion` como "um texto legível por
máquina, composto de um a três inteiros separados por pontos", em que uma parte que falta vale zero:
"10.5 especifica 10.5.0". A página da Apple sobre o `CFBundleVersion` diz que a App Store o exige.

## Por que "1.10.0" não é menor que "1.9.2"

**Comparados como texto, números de versão ficam na ordem errada, e é um bug fácil de publicar.** Como
texto, `"1.10.0"` vem antes de `"1.9.2"`, porque o caractere `1` vem antes do `9`. Como versões, 1.10 é
a décima versão menor e 1.9 a nona. Um script de publicação que compara os dois como texto decide que
a versão nova é mais velha, ou, pior, que uma mais velha é mais nova. A correção é separar nos pontos
e comparar cada parte como número, que é o que a verificação abaixo faz.

## Uma verificação de versão para o planner

Este programa recebe um candidato a versão e a versão que a loja já tem, e lista cada motivo pelo qual
o candidato não pode sair: um número de build que não cresce, um fora do que o Play aceita, ou um nome
de versão que volta para trás. A regra do build é das lojas; a do nome é do próprio planner, porque o
nome é o que um aluno lê na loja e uma versão que conta para trás parece um engano. Salve-o como
`version.ts` em `~/planner`:

```schooling-example
{"language": "typescript", "file": "version.ts", "parts": [{"code": "// version.ts: is this release candidate newer than what the store already has?\ntype Release = { name: string; build: number }; // versionName + versionCode, or the two iOS keys\n", "note": "Uma forma para as duas plataformas: `name` é o `versionName` ou o `CFBundleShortVersionString`, `build` é o `versionCode` ou o `CFBundleVersion`. Aqui o build é um inteiro simples, como o do Android."}, {"code": "// \"1.10.0\" -> [1, 10, 0]; a missing part counts as 0, so \"1.10\" equals \"1.10.0\".\nfunction parts(name: string): number[] {\n  if (!/^\\d+(\\.\\d+){0,2}$/.test(name)) throw new Error(`not a version: ${name}`);\n  const p = name.split(\".\").map(Number);\n  while (p.length < 3) p.push(0);\n  return p;\n}\n", "note": "Uma versão é até três números separados por pontos, e qualquer outra coisa é recusada com erro. Completar com zeros é a regra da Apple para o `CFBundleVersion`: \"10.5 especifica 10.5.0\"."}, {"code": "// Negative if a is older, 0 if the same, positive if a is newer: part by part, as numbers.\nexport function compare(a: string, b: string): number {\n  const [x, y] = [parts(a), parts(b)];\n  for (let i = 0; i < 3; i++) if (x[i] !== y[i]) return x[i] - y[i];\n  return 0;\n}\n", "note": "A comparação que o texto não consegue fazer: 10 contra 9 como números, parte por parte, parando na primeira diferença."}, {"code": "// Why the candidate must not ship; an empty list means it may. The build rule is the stores';\n// the name rule is ours, because the name is the number people read.\nexport function problems(candidate: Release, published: Release): string[] {\n  const out: string[] = [];\n  if (!Number.isInteger(candidate.build) || candidate.build < 1 || candidate.build > 2100000000) { // Play's ceiling\n    out.push(`build ${candidate.build} is not an integer from 1 to 2100000000`);\n  } else if (candidate.build <= published.build) {\n    out.push(`build ${candidate.build} is not higher than the published ${published.build}`);\n  }\n  if (compare(candidate.name, published.name) < 0) {\n    out.push(`version ${candidate.name} goes back from the published ${published.name}`);\n  }\n  return out;\n}\n", "note": "Todos os motivos de uma vez, não só o primeiro, para que uma execução diga tudo o que está errado num candidato. O teto de 2100000000 é do Play; o comentário diz de quem é cada regra."}, {"code": "const published: Release = { name: \"1.9.2\", build: 41 };\nconsole.log(`as text, \"1.10.0\" > \"1.9.2\" is ${\"1.10.0\" > \"1.9.2\"}`);\nconsole.log(`as versions, compare(\"1.10.0\", \"1.9.2\") is ${compare(\"1.10.0\", \"1.9.2\")}`);\nfor (const c of [\n  { name: \"1.10.0\", build: 42 },\n  { name: \"1.10.0\", build: 41 },\n  { name: \"1.9.1\", build: 43 },\n  { name: \"1.9.2\", build: 43 },\n]) {\n  const p = problems(c, published);\n  console.log(`${c.name} (${c.build}): ${p.length === 0 ? \"ok\" : \"REFUSED, \" + p.join(\"; \")}`);\n}", "note": "A versão publicada, a comparação de texto que dá errado, e quatro candidatos: um certo, um que reusa o número de build, um que conta para trás e uma recompilação."}]}
```

```
ana@dev:~/planner$ node version.ts
as text, "1.10.0" > "1.9.2" is false
as versions, compare("1.10.0", "1.9.2") is 1
1.10.0 (42): ok
1.10.0 (41): REFUSED, build 41 is not higher than the published 41
1.9.1 (43): REFUSED, version 1.9.1 goes back from the published 1.9.2
1.9.2 (43): ok
```

**A primeira linha é o bug, pego.** Como texto, `"1.10.0" > "1.9.2"` é `false`; como versões,
`compare` diz que a primeira é mais nova. Depois, quatro candidatos contra uma 1.9.2 publicada, build
41. `1.10.0` com o build 42 pode sair. O mesmo nome com o build 41 é recusado, porque o 41 já foi
usado, e no Play esse envio falharia. `1.9.1` com o build 43 tem um número de build certo e um nome
que conta para trás. E `1.9.2` com o build 43 pode sair, que é o caso de uma recompilação: a mesma
versão, corrigida e enviada de novo, com um número de build novo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l20-numbers\" aria-label=\"Números de versão ao longo de três versões do planner, numa linha do tempo. A versão 1.9.2, build 41, publicada. Depois 1.10.0, build 42, recusada na revisão e nunca publicada, desenhada tracejada. Depois 1.10.0 de novo, build 43, publicada. Depois 1.10.1, build 44, publicada. O nome que as pessoas leem se repete quando um build é refeito; o número de build nunca se repete e só cresce.\"><defs><marker id=\"l20-numbers-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l20-numbers-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"20\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">o nome que as pessoas leem</text><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">o número que a loja compara</text><path d=\"M190 196 L700 196\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-numbers-ah-wire)\"></path><rect x=\"200\" y=\"60\" width=\"100\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"250.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1.9.2</text><rect x=\"200\" y=\"130\" width=\"100\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"250.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">41</text><text x=\"250\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper)\">publicado</text><path d=\"M300 150 L325 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-numbers-ah-paper-dim)\"></path><rect x=\"325\" y=\"60\" width=\"100\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"375.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1.10.0</text><rect x=\"325\" y=\"130\" width=\"100\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"375.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">42</text><text x=\"375\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">recusado na revisão</text><path d=\"M425 150 L450 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-numbers-ah-paper-dim)\"></path><rect x=\"450\" y=\"60\" width=\"100\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"500.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1.10.0</text><rect x=\"450\" y=\"130\" width=\"100\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"500.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">43</text><text x=\"500\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper)\">publicado</text><path d=\"M550 150 L575 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-numbers-ah-paper-dim)\"></path><rect x=\"575\" y=\"60\" width=\"100\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"625.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1.10.1</text><rect x=\"575\" y=\"130\" width=\"100\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"625.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">44</text><text x=\"625\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper)\">publicado</text></svg>", "caption": "Três versões e quatro builds. O nome 1.10.0 aparece duas vezes, porque o build recusado foi corrigido e enviado de novo; o número de build seguiu em frente e o 42 se foi para sempre."}
```

**O número de build conta todo build que chegou à loja, não toda versão.** Na figura, a 1.10.0 subiu
duas vezes: o build 42 foi recusado na revisão, e a correção subiu como build 43 com o mesmo nome.
Ninguém fora da equipe viu o 42, e ele gastou o número dele para sempre. É por isso que uma equipe
deixa o pipeline de build atribuir o número de build em vez de uma pessoa, e é por isso que a aula 9
do `mobile-delivery` dedica uma aula inteira à semântica que as pessoas leem no outro número.
