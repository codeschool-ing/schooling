---
title: Sexta de manhã, e a decisão de entrega
version: 1
---

**Na sexta de manhã a Lia relata os critérios de saída um a um, cumprido ou não cumprido, e a Joana decide se entrega.**
Essa divisão é todo o ponto do exercício: quem testa fornece a evidência, a pessoa que responde pelo produto decide.

## O relato contra os critérios

| critério | situação |
|---|---|
| toda área recebeu as horas planejadas, ou a falta está escrita | **cumprido**, com falta: depois da suspensão de quinta, o mapa de assentos teve 20 minutos em vez de 2 horas e o relatório 30 minutos em vez de 1 hora |
| todo teste de aceitação combinado passa | **cumprido**: dez cenários, todos verdes, a execução da aula 17 |
| nenhum defeito aberto alto ou crítico em preços, pedidos ou reembolsos | **não cumprido**: a sessão das 9:30 é cobrada pelo preço da noite |
| todo defeito aberto tem dono e decisão | **cumprido**, menos o defeito das 9:30, que espera esta reunião |
| o resumo lista o que foi testado de leve e o que não foi | **cumprido**: o resumo em quatro partes da aula 20, atualizado |

Um critério não está cumprido, e o relato diz isso com todas as letras. A Lia não o suaviza, e não o arredonda para
cima porque os outros quatro estão verdes.

## A decisão

O defeito das 9:30 esperava uma pergunta desde os três amigos da aula 17: o programa deve aceitar *9:30*, ou a
programação deve dizer sempre *09:30*? A resposta da Célia chegou na quinta: o sistema da programação deixa digitar o
horário dos dois jeitos, e ela digitou *9:30* uma vez, para a primeira sessão da manhã. Daqui em diante ela pode
digitar *09:30*.

A decisão da Joana, escrita no resumo ao lado do critério:

> **Entregar na sexta.** O defeito das 9:30 é aceito nesta entrega, com um contorno: sessões da manhã são digitadas com
> zero à esquerda, e a Célia conferiu a programação atual. O Rafael corrige a comparação na próxima sprint, com a
> verificação de relações da aula 19 entrando nas verificações automatizadas para o defeito não poder voltar sem
> ninguém perceber.

É um resultado legítimo. Um critério de saída não cumprido não quer dizer automaticamente *não entregue*. Quer dizer
*quem decide precisa decidir sabendo*, e registrar por quê. O que não seria legítimo é entregar com o critério marcado
como cumprido em silêncio, ou o defeito das 9:30 rebaixado para *médio* em silêncio para a tabela ficar verde.

## O que é de quem testa, e o que não é

A Lia é dona da verdade do relato: que cada situação está correta, que a evidência existe, que as lacunas estão ditas.
Ela não é dona da entrega. Se a Joana tivesse decidido entregar com um defeito que a Lia achasse perigoso, a parte da
Lia seria dizer isso com clareza, por escrito, com os motivos, e então aceitar a decisão de quem responde por ela. É o
argumento da aula 5 de novo: quem testa não é o guardião do *não pode entregar*, mas a pessoa que garante que ninguém
entrega sem saber o que está entregando.

O próximo ciclo começa na segunda, com seus próprios critérios de entrada. Um deles é novo: *a verificação de relações
passa*, o que só vai acontecer quando a correção do Rafael estiver no build.
