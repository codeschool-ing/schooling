---
title: A Carcará uma vez pelo ciclo
version: 1
---

**Uma volta pelo ADM fica mais fácil de entender com uma mudança só.** A diretoria da Carcará
decidiu: *até o fim de 2027, todo passageiro embarca com passagem digital, e as rodoviárias param de
imprimir.* Tainá conduziu o trabalho de arquitetura, com Joana como analista. Isto é o que cada fase
produziu, no tamanho que uma empresa do porte da Carcará consegue pagar.

## Preliminar

A Carcará nunca tinha feito arquitetura corporativa de propósito. A fase Preliminar levou duas
semanas e produziu três coisas: **quem faz** (Tainá, com metade do tempo dela, mais Joana e uma
pessoa de cada time de sobreaviso), **oito princípios de arquitetura** (a antepenúltima seção mostra
dois) e **a adaptação**: quais entregáveis eles iam produzir, em qual ferramenta, e quais iam pular.

## A. Visão de Arquitetura

Uma **Declaração de Trabalho de Arquitetura** de duas páginas: escopo, stakeholders, a visão em um
parágrafo, as restrições (*o Frota fica*, *a LGPD*) e a medida de sucesso: *todo embarque nas 26
rodoviárias usa passagem digital; a impressão de passagens nas rodoviárias acaba; o tempo do
atendente por venda cai de quatro minutos para dois*. A diretoria aprovou numa reunião só.

## B. Arquitetura de Negócio

A linha de base: atendentes vendem passagens de papel em dinheiro e cartão; alguns passageiros,
sobretudo os mais velhos e os de rodoviárias do interior, não têm smartphone. O alvo: atendentes
vendem **passagens digitais**, enviadas por SMS ou impressas uma vez como QR code num recibo, e o
recibo é a passagem. A lacuna achou a parte incômoda: **um passageiro sem celular e sem e-mail**. A
resposta de negócio, um recibo com QR que o motorista escaneia, saiu desta fase, e não de algum
engenheiro.

## C. Arquiteturas de Sistemas de Informação

Dados: a passagem ganha um **canal de entrega**, e um passageiro pode não ter conta. Aplicações: o
back office das rodoviárias é **aposentado**; os atendentes usam um novo modo balcão do app web do
passageiro, que já conversa com o ticketing. O app de embarque precisa aceitar QR code impresso além
do QR no celular. Cada mudança virou um item de trabalho e, quando era difícil de reverter, um
registro de decisão.

## D. Arquitetura de Tecnologia

As impressoras de recibo das 26 rodoviárias ficam, agora imprimindo recibos com QR; os PCs são
trocados por tablets em 2026. **Os links de internet das rodoviárias viraram a dependência
crítica**: um balcão que não alcança o ticketing não vende. O requisito foi para o centro, e a fase
B foi revisitada: os atendentes ganham um modo de venda off-line para até cinquenta passagens,
conciliadas depois. Esse laço é o ADM funcionando como foi desenhado.

## E e F. Oportunidades, soluções e migração

As lacunas foram agrupadas em quatro pacotes de trabalho e três **arquiteturas de transição**, uma
por trimestre, porque 26 rodoviárias não conseguem virar no mesmo dia: piloto em duas rodoviárias,
depois as linhas do litoral, depois o resto. O roteiro e o plano foram uma planilha e um diagrama.

## G e H. Governança e mudança

Durante a implementação, o desenho de cada time foi conferido contra o alvo numa **revisão de
conformidade** de 30 minutos antes de ir para produção. No quinto mês, a empresa de pagamentos
anunciou o novo formato de liquidação da aula 7, e a fase H o registrou como mudança: pequena o
bastante para caber no trabalho em curso, então nenhum ciclo novo foi aberto.
