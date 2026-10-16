---
title: O teste de aceitação vem primeiro
version: 1
---

**O desenvolvimento guiado por testes de aceitação, ATDD, é o TDD um nível acima: antes de uma história ser
construída, o time combina os testes que vão decidir se ela é aceita, e a história fica pronta quando eles passam.**
Onde os testes do TDD são escritos por quem desenvolve sobre uma função, os do ATDD são escritos pelo time sobre uma
história, em exemplos com que a dona do produto concorda.

As ideias chegaram com vários nomes no fim dos anos 2000, e se sobrepõem tanto que os nomes muitas vezes são usados
para a mesma coisa: *acceptance test-driven development*, do livro de Ken Pugh de 2011; *specification by example*
(especificação por exemplos), do livro de Gojko Adzic do mesmo ano; e o BDD, da aula 16. Um jeito útil de
separá-los é pelo que cada um enfatiza.

| nome | o que enfatiza |
|---|---|
| TDD | um teste de quem desenvolve antes do código de quem desenvolve, uma unidade de cada vez |
| BDD | uma linguagem compartilhada para o comportamento, e a conversa que acha os exemplos |
| ATDD | os testes de aceitação de uma história combinados pelo time antes de a história começar |
| especificação por exemplos | os exemplos *são* a especificação; não há documento separado para se afastar deles |

Na prática, um time que faz ATDD em geral escreve os testes de aceitação em Gherkin e os roda com uma ferramenta de
BDD, então a diferença é de ênfase. O que o ATDD acrescenta à aula 16 é uma regra sobre **momento e acordo**: os
testes existem, e a dona do produto disse sim a eles, antes de alguém começar a construir.

## Dois laços

ATDD e TDD se encaixam como dois laços, um dentro do outro. O laço de fora começa com um teste de aceitação da
história, que falha. Dentro dele, quem desenvolve roda quantos ciclos de TDD forem necessários para construir as
partes. O teste de fora passa quando a história faz o que foi combinado, e só então ela está pronta.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 660 220\" role=\"img\" data-fig=\"l17-loops\" aria-label=\"Dois laços. O laço de fora é a história: começa com um teste de aceitação que o time combinou e que falha, e termina quando o teste de aceitação passa e a história fica pronta. Dentro dele, o laço de dentro é o TDD, vermelho, verde, refatorar, rodado muitas vezes para construir as partes.\"><defs><marker id=\"qa-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10.0\" y=\"10.0\" width=\"640.0\" height=\"200.0\" rx=\"10\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"24.0\" y=\"28.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">laço de fora: a história</text><rect x=\"24.0\" y=\"80.0\" width=\"130.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"89.0\" y=\"98.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">teste de aceitação</text><text x=\"89.0\" y=\"111.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">combinado, falha</text><rect x=\"506.0\" y=\"80.0\" width=\"130.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"571.0\" y=\"98.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">teste de aceitação</text><text x=\"571.0\" y=\"111.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">passa: pronto</text><rect x=\"180.0\" y=\"48.0\" width=\"300.0\" height=\"140.0\" rx=\"10\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"330.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--phosphor)\">laço de dentro: TDD, muitas vezes</text><rect x=\"196.0\" y=\"110.0\" width=\"80.0\" height=\"32.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"236.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">vermelho</text><path d=\"M277.0 126.0 L289.0 126.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"290.0\" y=\"110.0\" width=\"80.0\" height=\"32.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"330.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">verde</text><path d=\"M371.0 126.0 L383.0 126.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"384.0\" y=\"110.0\" width=\"80.0\" height=\"32.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"424.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">refatorar</text><path d=\"M440 144 C 440 175, 236 175, 236 146\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><path d=\"M156.0 105.0 L178.0 105.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><path d=\"M482.0 105.0 L504.0 105.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path></svg>", "caption": "ATDD em volta do TDD. O teste de fora é combinado com a dona do produto; os de dentro são de quem desenvolve."}
```

O teste de fora muda o que *pronto* quer dizer. Na aula 12, a definição de pronto do Cine Aurora exigia que "cada
critério de aceitação tem um teste, e os testes passam". O ATDD é como essa linha é cumprida sem correria no fim
da sprint: os testes foram escritos no primeiro dia, a partir dos critérios, e o trabalho é deixá-los verdes.

## Por que isso importa a quem testa

Os testes de aceitação são onde as perguntas de quem testa passam a valer. Na aula 12 as perguntas melhoravam os
critérios; na aula 16 viravam cenários. No ATDD elas viram **a definição da história**, combinada antes do código,
rodando todo dia, e impossível de largar quieto no fim da sprint porque está vermelha.

Também muda quando quem testa trabalha. Num time em que o teste acontece depois da construção, o dia mais cheio de
quem testa é o último. Num time de ATDD, é o primeiro: os exemplos são escritos antes de quem desenvolve começar, e
o trabalho de quem testa durante a sprint passa a ser a exploração, a coisa que os testes combinados não fazem.
