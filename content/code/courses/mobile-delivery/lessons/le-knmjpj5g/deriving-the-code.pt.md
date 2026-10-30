---
title: Derivar o código a partir do nome
version: 1
---

**Um version code digitado à mão é um version code que alguém um dia vai digitar errado.** A cura
comum é uma regra: o código é calculado a partir do nome da versão e de um contador de builds, então
o nome decide o código e ninguém o escolhe. O planner usa a regra mais simples que mantém a ordem:

```localised
versionCode = MAJOR × 1.000.000 + MINOR × 10.000 + PATCH × 100 + BUILD

1.5.0, build 3   →   1 × 1.000.000 + 5 × 10.000 + 0 × 100 + 3   =   1050003
```

Dois dígitos para minor, patch e build: até 99 de cada, o que sobra para um app, e o maior código
que a regra faz para um major 2099 fica abaixo dos 2.100.000.000 do Google. O mesmo inteiro é usado
como número de build no iOS, então um número nomeia o build nas duas plataformas.

## O que já foi publicado

A regra sozinha não sabe o que já está nas lojas. O planner guarda isso num arquivo, os códigos
enviados até agora, em ordem. Salve isto como `history.json`:

```json
{ "uploaded": [1040001, 1040002, 1050001, 1050002] }
```

## O script

Salve isto como `version.ts`. Ele recebe um nome de versão e um número de build, calcula o código e
recusa uma parte fora da faixa, um código já usado, ou um código menor que o maior já enviado:

```schooling-example
{"language": "typescript", "file": "version.ts", "parts": [{"code": "// version.ts: from a version name and a build number to the code both stores compare\nimport { readFileSync } from \"node:fs\";\n\nconst [name, buildArg] = [process.argv[2], process.argv[3]];\nconst build = Number(buildArg);\nconst parts = name.split(\".\").map(Number);", "note": "O nome como as pessoas o leem, e o contador de builds, que o pipeline vai fornecer na lição 10."}, {"code": "function refuse(why: string): never {\n  console.log(`${name} build ${build}: refused, ${why}`);\n  process.exit(1);\n}\nif (parts.length !== 3 || parts.some((p) => !Number.isInteger(p) || p < 0)) refuse(\"the name must be MAJOR.MINOR.PATCH\");\nconst [major, minor, patch] = parts;\nfor (const [part, value] of [[\"minor\", minor], [\"patch\", patch], [\"build\", build]] as const) {\n  if (!Number.isInteger(value) || value < 0 || value > 99) refuse(`${part} ${value} does not fit in two digits`);\n}", "note": "Uma parte que não cabe nos dois dígitos dela transbordaria para a parte seguinte e faria um código que colide com outra versão."}, {"code": "const code = major * 1_000_000 + minor * 10_000 + patch * 100 + build;\nif (code > 2_100_000_000) refuse(`${code} is over Google Play's limit`);", "note": "A regra, e o maior valor que o Google Play permite."}, {"code": "const { uploaded } = JSON.parse(readFileSync(\"history.json\", \"utf8\")) as { uploaded: number[] };\nif (uploaded.includes(code)) refuse(`${code} was uploaded already`);\nconst highest = Math.max(...uploaded);\nif (code < highest) refuse(`${code} is lower than ${highest}, already in the stores`);\nconsole.log(`${name} build ${build}: versionName ${name}, versionCode ${code}; iOS ${name} (${code})`);", "note": "As duas regras das lojas: nunca duas vezes, nunca menor. Depois os dois números, como cada plataforma os quer."}]}
```

```
ana@dev:~/planner$ node version.ts 1.5.0 3
1.5.0 build 3: versionName 1.5.0, versionCode 1050003; iOS 1.5.0 (1050003)
ana@dev:~/planner$ node version.ts 1.4.1 1
1.4.1 build 1: refused, 1040101 is lower than 1050002, already in the stores
ana@dev:~/planner$ node version.ts 1.5.0 2
1.5.0 build 2: refused, 1050002 was uploaded already
ana@dev:~/planner$ node version.ts 1.5.100 1
1.5.100 build 1: refused, patch 100 does not fit in two digits
```

**A 1.4.1 é a falha da seção anterior**, pega antes de qualquer envio. O código dela, 1040101, é um
número perfeitamente válido e menor que o 1050002 que já está nas lojas. O build 2 da 1.5.0 é
recusado pelo outro motivo: aquele build exato já foi enviado. E um patch de 100 não cabe nos dois
dígitos da regra, então o script diz isso em vez de produzir um código que colide com a 1.6.0.

## Num build de verdade

A mesma conta vai para onde cada plataforma lê os números dela: algumas linhas no
`build.gradle.kts` calculando o `versionCode` a partir do `versionName` e de uma variável de ambiente
que o pipeline define; uma build phase no Xcode, ou o `increment_build_number` do Fastlane; um passo
no EAS ou no `app.config.js` para o Expo. **O contador de builds vem do pipeline**, lição 10, onde
cada execução já tem um número próprio, e a checagem do histórico roda contra o que as lojas
informam em vez de um arquivo. *Esses três não foram gerados para este curso.*
