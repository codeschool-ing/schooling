---
title: O package.json de uma biblioteca
version: 1
---

**O `package.json` de um app descreve como rodá-lo; o de uma biblioteca descreve o que ela é para outro
código: o nome, a versão, os pontos de entrada e quais arquivos ela leva.** O do planner diz
`"private": true`, o que impede que ele seja publicado por acidente. O da biblioteca foi feito para ser
publicado, então leva os campos que um registry e quem consome leem:

```schooling-example
{"language": "json", "file": "package.json", "parts": [
 {"code": "{\n  \"name\": \"@planner/ui\",\n  \"version\": \"0.1.0\",\n  \"description\": \"The study planner's design tokens and components.\",\n  \"type\": \"module\",", "note": "Um nome com **escopo**: `@planner` é o escopo, e um escopo pode apontar para um registry próprio, o que a seção sobre publicação usa. `0.1.0` é uma primeira versão que promete pouco, como explica a seção sobre versões. `type: module` diz que o JavaScript é de módulos ES."},
 {"code": "  \"exports\": {\n    \".\": {\n      \"types\": \"./dist/index.d.ts\",\n      \"default\": \"./dist/index.js\"\n    },\n    \"./tokens.css\": \"./dist/tokens.css\"\n  },", "note": "Os pontos de entrada, e só eles. `import { sessionRow } from \"@planner/ui\"` chega a `dist/index.js`, com os tipos vindos de `index.d.ts`; `@import \"@planner/ui/tokens.css\"` chega à folha de estilo. Qualquer outro caminho dentro do pacote é recusado a quem consome, o que mantém privados os arquivos privados."},
 {"code": "  \"files\": [\"dist\"],\n  \"sideEffects\": [\"*.css\"],", "note": "`files` é o que vai no pacote publicado: a pasta construída, e nada do código-fonte, dos scripts ou dos testes. `sideEffects` diz a um bundler que importar um arquivo CSS faz algo mesmo quando nada dele é usado, e que o JavaScript não faz, então componentes não usados podem sair do pacote de quem consome."},
 {"code": "  \"scripts\": {\n    \"build\": \"node tokens.mjs && vite build && tsc && cp src/tokens.css dist/\"\n  }\n}", "note": "Um build, em quatro passos: os tokens como CSS, os componentes empacotados pelo Vite, as declarações de tipo pelo `tsc`, e a folha de estilo copiada ao lado delas."}
]}
```

## Por que exports, e não main

Pacotes mais velhos dizem `"main": "index.js"` e deixam quem consome importar qualquer arquivo de dentro
deles pelo caminho. Isso faz de **todo arquivo uma interface pública**: quem importou
`@planner/ui/dist/components.js` quebra no dia em que o arquivo é renomeado, e quem fez a biblioteca não
tinha como saber que alguém fazia isso. O `exports` inverte essa lógica. O que ele lista é público; todo o
resto é um erro de importar. Uma biblioteca com um mapa `exports` pode reorganizar os arquivos à vontade,
porque ninguém tinha como depender deles.

## Um escopo é um nome, e um endereço

`@planner/ui` se lê como uma organização e um pacote, e no registry público do npm é isso que um escopo é:
um espaço de nomes que alguém tem. Para um pacote interno ele também importa por um motivo prático: dá para
dizer ao npm que um escopo mora num registry e todo outro pacote em outro. A seção sobre publicação usa
exatamente isso, para o planner buscar `@planner/ui` num registry privado e todo o resto no npm, sem nenhum
dos dois saber do outro.
