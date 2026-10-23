---
title: Para que serve uma revisão de arquitetura
version: 1
---

**Uma revisão de arquitetura confere um design contra as qualidades que ele precisa ter, para achar
os riscos enquanto ainda é barato lidar com eles.** Não é uma revisão de código em escala maior, e
não é um portão de aprovação, embora as organizações muitas vezes a transformem num. A aula 11 de
`architecture-role` mostrou como revisar um documento de design; esta aula trata de avaliar uma
arquitetura inteira, ou uma mudança grande nela, como um exercício deliberado.

## Quando uma revisão compensa

Uma revisão custa o tempo de várias pessoas sêniores, então precisa ser posta onde rende mais:

- **antes de um compromisso difícil de desfazer**: antes de o programa de embarque digital da aula 8
  escolher seu alvo, antes de escolher um banco de dados, antes de um contrato com um fornecedor;
- **antes de um estresse conhecido**: o pico de São João, uma migração, um lançamento numa região
  nova;
- **depois de uma longa deriva**: um sistema que mudou um pull request de cada vez durante um ano já
  não bate com a imagem que ninguém tem dele, e a revisão também é o jeito de redesenhar essa imagem.

A primeira revisão da Carcará veio do segundo tipo. Três semanas antes do São João, Celeste perguntou
se a plataforma ia aguentar, e ninguém conseguiu responder de memória.

## Contra o que se confere

Uma revisão precisa de algo contra o qual conferir o design, e esse algo é o trabalho da aula 6:
**os cenários de qualidade e a árvore de utilidade**. Sem eles, a revisão vira uma conversa sobre
gosto, *eu teria usado Kafka*, que ninguém consegue resolver. Com eles, todo comentário pode ser
posto como uma pergunta sobre um cenário: *o design atende o QS-01, 2.000 compras por minuto, e como
vocês sabem?*

Se um time pede uma revisão e não tem cenários, a primeira hora da revisão é escrevê-los. Só isso
muitas vezes já vale a reunião.

## O que ela produz

O resultado de uma revisão é **uma lista curta de riscos, cada um ligado a um cenário, ordenada, com
um responsável e um próximo passo**, e não um veredito. *Aprovado* e *reprovado* são decisões que
outra pessoa toma com a lista na mão. Uma revisão que termina em *parece bom* sem lista não foi
feita; uma que termina em quarenta comentários sem distinção foi mal feita. O resto desta aula trata
de como ir dos cenários até essa lista.
