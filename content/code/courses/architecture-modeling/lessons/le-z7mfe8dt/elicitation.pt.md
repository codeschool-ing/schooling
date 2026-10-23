---
title: "Elicitação: perguntar, observar e confirmar"
version: 1
---

**Elicitação é tirar informação dos stakeholders e de outras fontes**, e o BABOK escolheu a palavra
de propósito: requisitos não estão jogados por aí esperando para ser *coletados*. As pessoas os
guardam em parte, de forma inconsistente e muitas vezes sem saber que os guardam. Tirá-los de lá
exige técnica, e a técnica tem de servir à pessoa e à pergunta.

## As técnicas, e para que cada uma serve

O BABOK descreve cinquenta técnicas. Um punhado delas faz quase todo o trabalho de elicitação:

| técnica | serve para | seu ponto cego |
| --- | --- | --- |
| **entrevista** | o conhecimento, os objetivos e as preocupações de uma pessoa, em profundidade | as pessoas descrevem o que acham que fazem |
| **observação** | como o trabalho é feito de verdade | é lenta; as pessoas trabalham diferente quando observadas |
| **workshop** | acordo entre vários stakeholders, rápido | a voz mais alta vence, a menos que haja facilitação |
| **análise de documentos** | regras, formatos e histórico de que ninguém se lembra | os documentos estão desatualizados |
| **prototipação** | reações a algo concreto | as pessoas reagem à aparência, e não ao comportamento |
| **questionário** | a opinião de muita gente, gastando pouco | só responde às perguntas que você pensou em fazer |

## A observação achou o que a entrevista não achou

Tainá e Joana começaram por uma entrevista, e Joana descreveu a conciliação com precisão: baixar o
arquivo do gateway, exportar os pagamentos do Carcará, cruzá-los pelo id da transação, investigar o
resto. A entrevista levou uma hora e deixou passar três coisas que uma manhã de **observação**
encontrou:

- Joana confere os **reembolsos** numa passada separada, porque o gateway os informa no dia em que
  são liquidados, não no dia em que são feitos. Um cruzamento só pela data falha em todo reembolso.
- Ela mantém uma **planilha de exceções conhecidas**: transações que nunca vão bater, com uma nota em
  cada uma. Ela tem 214 linhas e é o artefato mais valioso do processo.
- Os reembolsos em dinheiro no balcão aparecem como **divergências que ela explica ligando para a
  rodoviária**. Foi assim que os agentes viraram stakeholders.

Nada disso é segredo. Era invisível para Joana porque ela faz tudo isso todo mês sem pensar. **As
pessoas são más testemunhas da própria rotina**, e é por isso que a técnica importa.

## Confirmar, sempre

O BABOK faz de **confirmar os resultados da elicitação** uma tarefa própria: escrever o que você
entendeu e conferir com a fonte antes que alguém construa em cima. Tainá mandou a Joana um resumo de
uma página da manhã, com as três descobertas e as perguntas que elas levantaram, e fez uma pergunta
no fim: *o que eu entendi errado?* Joana corrigiu uma coisa, o prazo do reembolso, que é liquidado
dois dias depois e não um. Um dia errado no requisito teria transformado todo reembolso numa
divergência.

## Preparar

A elicitação vai melhor quando o analista chega com: a pergunta a responder, o que já se sabe (a
página dos conceitos centrais, de antes nesta aula), as fontes a consultar e um jeito de registrar o
que sair. Dez minutos de preparação são a diferença entre uma entrevista e um bate-papo.
