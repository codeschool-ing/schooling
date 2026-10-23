---
title: O que mantém um documento vivo, e o que esta aula acrescenta
version: 1
---

**A aula 8 de `architecture-role` apresentou os hábitos que mantêm a documentação verdadeira:
guardá-la no repositório como texto puro, mudá-la no mesmo pull request que o código, dar a cada
página um dono e uma data, conferir o que pode ser conferido e apagar o que ninguém vai manter.**
Esta aula parte desses hábitos e segue para as perguntas que eles deixam em aberto.

## Quatro perguntas que os hábitos não respondem

1. **O que um documento de arquitetura deve conter?** Donos e datas mantêm as páginas verdadeiras;
   não dizem quais páginas deveriam existir. Um template diz, e o arc42 é o que a maioria dos times usa.
2. **Que tipo de página é esta?** Um tutorial para um engenheiro novo e a página de referência que
   lista todos os endpoints envelhecem de jeitos diferentes e pedem manutenção diferente. Uma
   classificação pequena, o Diátaxis, separa os dois.
3. **Como sabemos que a arquitetura ainda bate com os documentos?** Conferir à mão não escala. As
   **funções de aptidão (fitness functions)**, verificações automáticas de propriedades
   arquiteturais, fazem isso a cada mudança.
4. **Quão saudável está a documentação como um todo?** Cada dono, sozinho, não enxerga isso. Um
   punhado de números enxerga.

E uma quinta, que a aula 8 de `architecture-role` começou e esta aula termina: **como uma página
morre bem?**

## O ponto de partida da Carcará

Tainá contou o repositório de arquitetura depois do programa de embarque digital da aula 8: **140
páginas, 31 editadas nos últimos doze meses**, 23 registros de decisão, 14 diagramas, três dos quais
mostravam o back office das rodoviárias, que já tinha sido aposentado. Ninguém sabia dizer quais das
outras 109 páginas ainda eram verdadeiras, então na prática ninguém confiava em nenhuma, e os
engenheiros perguntavam à Tainá. Esse último fato é o custo real da documentação morta: **o
conhecimento volta para a cabeça de uma pessoa só**, que é exatamente o que escrever tudo devia
evitar.

O resto desta aula acompanha o que a Carcará fez a respeito, em umas duas semanas de trabalho
espalhadas por um trimestre.
