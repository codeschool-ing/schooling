---
title: Uma ontologia, não um método
version: 1
---

**O framework de Zachman diz que tipos de descrição existem e como se relacionam; não diz nada sobre
a ordem em que produzi-las nem sobre como tomar decisões.** O próprio Zachman insiste na palavra
**ontologia**: uma classificação estruturada do que existe, como a tabela periódica, que classifica
os elementos e não diz a um químico o que misturar.

## O que decorre disso

- **Não há célula de partida.** Um time pode começar pelo *por quê* do executivo ou pelo *o quê* do
  engenheiro. Para a grade tanto faz; para um método, não.
- **Ele se combina com qualquer método.** O ADM do TOGAF, da aula 8, pode ser rodado pondo cada um
  de seus entregáveis numa célula de Zachman. Muitos times de arquitetura corporativa fazem
  exatamente isso: o TOGAF para o processo, Zachman como sistema de arquivamento.
- **Ele acha lacunas, não as preenche.** Pôr os documentos de uma organização na grade mostra quais
  células estão vazias. Se uma célula vazia importa é um julgamento que a grade não faz.

## Duas regras da grade

Zachman enuncia várias regras para o framework; duas servem a qualquer pessoa que o use:

1. **Cada célula é primitiva.** Um modelo numa célula responde a uma pergunta para um público. Um
   diagrama que mistura *o quê* e *como*, entidades e os processos que agem sobre elas, é uma
   **composta**: útil, muitas vezes necessária, mas ocupa várias células, e saber quais diz o que
   ela está misturando.
2. **As colunas não têm ordem.** *O quê* não é mais importante que *por quê*. Um framework que trata
   os dados como o principal, como o trabalho de sistemas de informação dos anos 1980 fazia muitas
   vezes, faz uma escolha que a grade não faz por você.

## Compostas são normais

A maioria dos diagramas reais é composta, e tudo bem. O diagrama de containers da aula 3 mostra
aplicações (*como*, enquanto processamento), stores de dados (*o quê*) e onde ficam na tecnologia
(*onde*), na linha do engenheiro. O diagrama de atividades com raias da aula 4 mistura *como* e
*quem*. O valor da grade não é proibi-los, e sim **dar nome ao que eles combinam**, para que, quando
uma composta ficar difícil de ler, você saiba qual primitiva separar.

## A crítica, e a resposta

A crítica comum é que o framework de Zachman é **abstrato demais para usar**: trinta e seis células
e nenhuma instrução. É verdade, e é essa a ideia. Uma ontologia usada como método fracassa, porque
não tem passos; usada como lista de verificação de **quais perguntas foram respondidas para quem**,
é um dos jeitos mais rápidos de descobrir o que falta numa descrição de arquitetura. A próxima seção
faz isso com este curso.
