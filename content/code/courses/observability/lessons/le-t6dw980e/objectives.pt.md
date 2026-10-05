---
title: Objetivos, e por que não cem por cento
version: 1
---

Um SLI é uma medição. Um **SLO**, um *service level objective*, objetivo de nível de serviço, é uma
meta para ela numa janela: **99,5% dos checkouts dão certo, numa janela móvel de 28 dias.** Há três
escolhas dentro dessa frase, e cada uma é uma decisão que alguém deveria saber defender.

**O número.** Cem por cento é a resposta que todo mundo dá primeiro, e está errada por dois motivos
que não têm nada a ver com ambição. O cliente não distingue 100% de 99,99%, porque o celular, a rede
e o meio de pagamento dele falham mais vezes que isso. E uma meta de 100% torna toda mudança uma
ameaça, já que qualquer versão pode falhar: o único sistema seguro é um que nunca muda, e uma loja
que nunca muda perde para uma que muda. O número deve ficar onde os clientes começam a perceber e a
reclamar, o que se aprende pelo que eles dizem e pelo histórico do próprio SLI. Ele também deve ser
um pouco mais rígido do que o serviço já entrega num bom mês, para significar alguma coisa.

**A janela.** Vinte e oito dias é comum porque sempre contém quatro de cada dia da semana, então a
correria de uma segunda-feira nunca conta duas vezes contra um mês com uma a menos. Uma janela móvel
esquece um incidente 28 dias depois. Uma janela de calendário zera no dia primeiro, o que é mais
fácil de relatar e dá aos últimos dias de um mês ruim uma liberdade perversa.

**Cada nove é um fator de dez.** A tabela é a mesma aritmética das tabelas de custo da aula 6, e é a
que se mostra a quem pede mais um nove:

| objetivo | falhas permitidas por milhão | queda total permitida em 28 dias |
|---|---|---|
| 99% | 10 000 | 6 h 43 min |
| 99,5% | 5 000 | 3 h 22 min |
| 99,9% | 1 000 | 40 min |
| 99,99% | 100 | 4 min |

Quatro minutos em 28 dias é menos tempo do que leva perceber um alerta, lê-lo e abrir um notebook.
**Um objetivo mais rígido do que a equipe consegue responder é uma promessa que ninguém cumpre**, e é o
jeito mais comum de os SLOs deixarem de ser levados a sério.

Um SLO é interno. Um **SLA**, um acordo, é a versão escrita num contrato, com reembolso ou multa
quando é descumprido. Ele é sempre mais frouxo que o SLO, para a equipe saber de um problema pelo
próprio objetivo muito antes de o contrato saber.