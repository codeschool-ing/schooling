---
title: Quatro áreas de aspecto, e as duas que as atravessam
version: 1
---

**As áreas de aspecto do IAF dividem a empresa nas partes que uma arquitetura descreve: negócio,
informação, sistemas de informação e infraestrutura de tecnologia.** Elas lembram os quatro domínios
do TOGAF da aula 8, e na maior parte são isso mesmo, com uma diferença que vale notar.

| área de aspecto | o que ela cobre | o embarque digital da Carcará |
| --- | --- | --- |
| **negócio** | objetivos, serviços, processos, organização, pessoas | a venda no balcão com recibo com QR; o novo papel dos atendentes |
| **informação** | a informação de que o negócio precisa, o significado dela e quem é o dono, sem depender de sistemas | o que é uma *passagem*; quem é dono dos dados de contato de um passageiro |
| **sistemas de informação** | as aplicações que guardam e processam a informação | o ticketing, o app de embarque, o modo balcão |
| **infraestrutura de tecnologia** | as plataformas, os aparelhos e as redes em que os sistemas rodam | a região de nuvem, os celulares dos motoristas, os tablets e os links das rodoviárias |

## A informação vem antes dos sistemas

A diferença em relação ao TOGAF é que **o IAF mantém a informação como uma área própria**, acima dos
sistemas que a guardam. No TOGAF, a arquitetura de dados fica junto com as aplicações na fase C; o
IAF pergunta primeiro pela informação como o negócio a entende, e só depois por onde ela fica
guardada.

Na Carcará, essa separação achou um problema real. Na área de informação, a pergunta *o que é uma
passagem?* tinha duas respostas: para Vendas, um assento numa viagem, pago; para o Financeiro, uma
linha de receita, que podia cobrir vários assentos comprados juntos. Nenhuma estava errada, e as duas
tinham sido embutidas em sistemas sem ninguém perceber que discordavam. É uma fronteira de bounded
context do mapa da aula 4, encontrada por um framework corporativo vindo pelo outro lado.

## Segurança e governança atravessando tudo

As duas áreas transversais do IAF valem para todas as células da grade, em vez de ocupar uma coluna:

- **segurança**: no nível contextual, *por que protegemos isto?* (a LGPD, a fraude na porta do
  ônibus); no conceitual, *o que precisa ser protegido?* (o número do documento de um passageiro, a
  validade de uma passagem); no lógico, *como?* (listas de passagens assinadas, acesso por papel); no
  físico, *com o quê?* (o serviço de gerenciamento de chaves, o armazenamento seguro do celular);
- **governança**: quem decide, em cada nível, e como uma decisão é conferida, que são de novo os
  conselhos e as dispensas da aula 8.

Desenhadas como faixas atravessando a grade, elas afirmam algo que um capítulo de segurança separado
no fim de um documento de arquitetura não afirma: **a segurança é decidida em todos os níveis, e uma
decisão tomada só no nível físico, um produto comprado, é uma decisão sem os seus motivos**.

## Preencher uma linha, não a grade inteira

Dezesseis células vezes duas preocupações transversais é muita arquitetura, e o IAF não pede tudo
isso. Um trabalho típico preenche **as células que a mudança toca, até a profundidade de que a
decisão precisa**. O programa da Carcará preencheu os quatro níveis de sistemas de informação e de
tecnologia, os dois níveis de cima de negócio e de informação, e deixou o resto como referência ao
que já existia.
