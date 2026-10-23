---
title: Dois sistemas de módulos, um runtime
version: 1
---

**O Node tem dois sistemas de módulos, e todo arquivo `.js` que ele carrega é um ou o outro.** A aula
9 do javascript apresentou os dois: o **CommonJS**, o original do Node, com `require` e
`module.exports`, e os **ES modules**, os da própria linguagem, com `import` e `export`. Aquela aula
tratava do que cada um significa. Esta trata do que o Node faz com eles: como decide qual um arquivo
é, onde procura o que você nomeou, e o que acontece quando os dois se encontram.

Dois fatos da aula 9 sustentam esta aula inteira:

| | CommonJS | ES modules |
|---|---|---|
| como um módulo pede | `require("./x")`, uma função chamada enquanto o arquivo roda | `import ... from "./x"`, lido antes de qualquer parte do arquivo rodar |
| o que ele recebe | uma cópia do que o `module.exports` tinha naquele momento | uma visão viva dos nomes exportados |

**A primeira linha é o motivo de os dois não poderem ser trocados com um buscar e substituir.** Um
`require` pode ficar dentro de um `if` e rodar ou não; uma declaração `import` é encontrada e
carregada antes de a primeira linha do arquivo executar. É isso que permite ao Node acusar um
módulo ausente antes de qualquer coisa rodar, e que torna possível o `await` no topo.

## Por que os dois ainda existem

O CommonJS veio primeiro, em 2009, porque o JavaScript não tinha módulo nenhum. Os ES modules
chegaram à linguagem em 2015 e ao Node, sem flag, em 2020. A essa altura a maior parte do npm era
CommonJS, e ainda há muito dele lá; um servidor que você mantém vai importar pacotes escritos dos
dois jeitos. Então a posição prática é:

- **o código novo que você escreve é ES modules**, porque esse é o sistema da própria linguagem e o
  que o navegador, o Deno e o Bun compartilham;
- **o CommonJS é algo que você vai ler e de que vai depender por anos**, então você precisa conhecer
  as regras dele também.

Este curso escreve ES modules a partir da aula 4. Esta aula usa os dois, lado a lado, porque as
diferenças ficam mais fáceis de ver assim.
