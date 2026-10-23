---
title: Escolher um framework, ou escolher não ter um
version: 1
---

**Um framework vale a adoção quando resolve um problema que a organização tem de fato, e esses
problemas são poucos e reconhecíveis.** A pergunta não é *qual framework é o melhor?*, e sim *o que
está dando errado que um método ou um vocabulário em comum resolveria?*

## Problemas, e o que os resolve

| o problema | um sintoma | o que ajuda |
| --- | --- | --- |
| **mudanças que atravessam times vivem deixando peças para trás** | um programa entra no ar e os reembolsos em dinheiro não têm para onde ir | um método com linha de base, alvo e lacuna: as fases B a D do TOGAF |
| **ninguém sabe dizer por que um sistema foi comprado** | as escolhas de produto não têm motivos acima delas | níveis que vão do motivo ao produto: a grade do IAF, ou a rastreabilidade da aula 6 |
| **cada time desenha de um jeito** | três diagramas de containers, três notações | uma notação e uma página de *como desenhamos*: C4 para sistemas, ArchiMate para a empresa |
| **muitos fornecedores precisam descrever um sistema** | o integrador não consegue combinar as descrições | um framework contratual: DoDAF, NAF |
| **os documentos existem e ninguém os lê** | uma wiki de 200 páginas, editada pela última vez dois anos atrás | menos documentos, com dono e data: aula 11 |

Nenhum desses problemas é *não temos um framework*. Se uma empresa não consegue dar nome ao seu
problema, um framework vai lhe dar um monte de documentos e o mesmo problema.

## A resposta da Carcará

A Carcará usa **C4 para todo sistema, ArchiMate para uma visão corporativa mantida por Tainá, um
recorte adaptado do TOGAF para mudanças que atravessam vários times, e os quatro níveis do IAF como
hábito de pensamento** ao escrever a parte de sistemas de informação de um programa. Isso está
escrito, numa página, no repositório de arquitetura, como a decisão da fase Preliminar na aula 8. Um
arquiteto novo lê em cinco minutos o que é usado, o que não é, e por quê.

## Quando um cliente ou um empregador exige um

Às vezes a escolha não é sua: uma licitação pública exige entregáveis do TOGAF, ou um contrato de
defesa exige visões do NAF. Aí a habilidade é **produzir o que é exigido mantendo as decisões onde
elas pertencem**, nos registros de decisão, nos cenários e nos modelos que o time de fato usa, e
mapeá-los para o formato exigido em vez de manter duas descrições que vão se afastar uma da outra. A
aula 12 mostra um jeito: um único modelo, renderizado em várias visões.
