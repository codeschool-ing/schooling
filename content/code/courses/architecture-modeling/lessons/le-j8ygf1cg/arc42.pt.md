---
title: arc42, um template para a arquitetura inteira
version: 1
---

**O arc42 é um template gratuito para documentar uma arquitetura de software, em doze partes, criado
por Gernot Starke e Peter Hruschka.** Ele não diz como projetar; diz o que um leitor vai procurar num
documento de arquitetura, e dá a cada coisa um lugar. A força dele é que quem já viu um documento
arc42 se orienta em qualquer outro.

## As doze partes

| | parte | o que entra nela | onde neste curso |
| --- | --- | --- | --- |
| 1 | **introdução e objetivos** | o propósito, os principais objetivos de qualidade, os stakeholders | aulas 6 e 7 |
| 2 | **restrições** | o que outros decidiram: leis, plataformas, convenções | aula 6 |
| 3 | **contexto e escopo** | o sistema e o seu entorno, de negócio e técnico | o contexto de sistema da aula 3 |
| 4 | **estratégia de solução** | as poucas decisões fundamentais e os motivos | os registros mais importantes da aula 5 |
| 5 | **visão de blocos de construção** | a estrutura estática, nível a nível | os containers e componentes da aula 3 |
| 6 | **visão de execução** | como os blocos se comportam em cenários importantes | as sequências da aula 2, os fluxos da aula 4 |
| 7 | **visão de implantação** | a infraestrutura e como os blocos se distribuem nela | a implantação da aula 2 |
| 8 | **conceitos transversais** | regras aplicadas em toda parte: segurança, logs, tratamento de erros, o modelo de domínio | aulas 2 e 4 |
| 9 | **decisões de arquitetura** | o registro de decisões, ou links para ele | aula 5 |
| 10 | **requisitos de qualidade** | a árvore de qualidade e os cenários | a árvore de utilidade da aula 6 |
| 11 | **riscos e dívida técnica** | problemas conhecidos, em ordem de prioridade | aula 13 |
| 12 | **glossário** | os termos, cada um com um só significado | a linguagem ubíqua da aula 11 de `design-patterns` |

A coluna da direita é o motivo de mostrar a tabela aqui: **o arc42 é um recipiente para os
artefatos que este curso já ensinou você a fazer**. Ele acrescenta muito pouco de seu, além de uma
ordem e de um conjunto de títulos vazios, e os títulos vazios são a parte útil.

## Usar sem preencher

O próprio template aconselha manter as partes curtas e **deixar de fora o que ninguém precisa**. Uma
parte pode ser uma frase e um link. O documento de venda de passagens da Carcará tem onze páginas: a
parte 8 é a mais longa, porque as regras transversais sobre embarque sem rede e idempotência são o
que os engenheiros novos mais quebram; a parte 2 tem três linhas.

O que o template faz bem é tornar as ausências visíveis. O primeiro rascunho da Carcará não tinha
nada na parte 11. Escrever *nenhum conhecido* sob *riscos e dívida técnica* pareceu errado para todo
mundo na sala, e em dez minutos havia seis itens, a começar pela exportação noturna da Frota, que não
tem nova tentativa.

## C4, arc42 e registros de decisão juntos

Os três se combinam sem atrito, e é por isso que muitos times usam exatamente esse conjunto:

- os **diagramas C4** vão nas partes 3, 5 e 7;
- os **registros de decisão** ficam na sua própria pasta, e a parte 9 aponta para o índice;
- o **arc42** dá os títulos que amarram tudo, e os objetivos de qualidade da parte 1 apontam para os
  cenários da parte 10.
