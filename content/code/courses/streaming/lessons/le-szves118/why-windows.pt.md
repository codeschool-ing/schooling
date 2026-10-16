---
title: Por que um stream precisa de janelas
version: 1
---

**Um stream não tem total, então todo agregado sobre ele é um agregado sobre uma fatia, e uma janela
é a regra que diz qual fatia.** A lição 1 citou isso como a primeira coisa que muda quando o período
nunca fecha. Esta lição torna isso concreto o bastante para calcular à mão.

A resposta tentadora é um total corrente: ir somando e imprimir a soma quando alguém pedir. Funciona,
e para algumas perguntas é o certo; o estoque por livro da lição 2 é exatamente isso, um fold sobre
todas as vendas de sempre. Falha em toda pergunta que tenha um período dentro. "Vendas desta manhã",
"vendas dos últimos dez minutos" e "quanto tempo aquele cliente ficou olhando" nomeiam um trecho de
tempo, e um total corrente esqueceu onde qualquer trecho começou. Subtrair um total corrente de um
anterior funciona até chegar uma venda atrasada que pertence ao lado de antes.

Uma janela é uma regra que, dado o horário de um evento, diz a quais fatias ele pertence. **Toda
janela desta lição é definida sobre o tempo do evento**, o `at` dentro da venda, pelos motivos a que
a lição 9 se dedicou inteira: a fatia "09:05 às 09:10" quer dizer vendas que aconteceram nesse
intervalo, não vendas que chegaram nele. O `per_minute.py` da lição 9 já usava janelas sem esse nome:
os baldes dele eram janelas de um minuto, ou de sessenta.

## Quatro formatos

Os quatro tipos diferem em duas coisas: se a fatia tem tamanho fixo e se as fatias se sobrepõem.

| janela | tamanho fixo | sobreposição | um evento pertence a | pergunta típica |
|---|---|---|---|---|
| tumbling | sim | não | exatamente uma janela | vendas a cada cinco minutos |
| hopping | sim | sim | tamanho ÷ avanço janelas | vendas dos últimos dez minutos, a cada cinco |
| sliding | sim | sim | toda janela que o contém | o máximo de vendas em quaisquer cinco minutos |
| sessão | não | não | uma janela por surto de atividade | quanto durou cada visita |

A lição percorre os quatro nessa ordem, com um programa e uma lista fixa de dez vendas, para que
cada número possa ser conferido com lápis. Depois acrescenta chaves, porque a Ponto Final faz a
maioria dessas perguntas por loja, e termina com a pergunta que o programa não consegue responder
sozinho: **quando o resultado de uma janela é final?**

## As dez vendas

As mesmas dez vendas alimentam todas as seções. Elas estão na ordem em que chegaram, e isso importa
em exatamente um lugar:

| nº | aconteceu | loja | centavos |
|---|---|---|---|
| 1 | 09:00:40 | recife | 3990 |
| 2 | 09:02:10 | natal | 5490 |
| 3 | 09:03:55 | olinda | 2990 |
| 4 | 09:05:00 | recife | 7900 |
| 5 | 09:06:20 | natal | 4490 |
| 6 | 09:12:30 | caruaru | 6200 |
| 7 | 09:13:05 | recife | 3500 |
| 8 | 09:08:50 | natal | 8990 |
| 9 | 09:14:10 | olinda | 2990 |
| 10 | 09:21:00 | recife | 5490 |

A venda 8 aconteceu às 09:08:50 e chegou depois da venda 7, que aconteceu às 09:13:05: uma versão
pequena da manhã de Natal da lição 9. A venda 4 cai exatamente às 09:05:00, que é a borda de uma
janela de cinco minutos e vai mostrar para onde vão as bordas. O resto é comum.
