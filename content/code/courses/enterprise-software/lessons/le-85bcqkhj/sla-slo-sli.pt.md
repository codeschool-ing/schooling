---
title: Uma medida, uma meta e um contrato
version: 1
---

Na fintech, a equipe de Joana chamava toda meta de confiabilidade de SLA. "A API de pagamentos tem
um SLA de 200 milissegundos" queria dizer que alguém tinha escrito 200 numa página da wiki. Ninguém
fora da equipe tinha concordado com aquilo e nada acontecia quando não era cumprido. **Usar uma
palavra para três coisas esconde a pergunta que mais importa: o que acontece quando o número não é
cumprido?**

O vocabulário que separa as três vem do livro do Google *Site Reliability Engineering* (Beyer,
Jones, Petoff e Murphy, orgs., 2016), cujo quarto capítulo define todas elas, e hoje ele é comum no
ofício.

| termo | o que é | na Serra Alta, para o Portal B2B |
|---|---|---|
| SLI, indicador de nível de serviço | uma medida de algum aspecto do serviço, em geral uma razão | a parcela dos envios de pedido que receberam confirmação em até 5 segundos |
| SLO, objetivo de nível de serviço | uma meta para um SLI ao longo de uma janela declarada | 99,5% dos envios, em 30 dias corridos móveis |
| SLA, acordo de nível de serviço | um contrato com os usuários que diz o que acontece se os objetivos não forem cumpridos | nenhum: as padarias não têm contrato que lhes pague por um pedido que falhou |

O livro oferece um teste que resolve a maioria das discussões: pergunte o que acontece se o objetivo
não for cumprido. Se a resposta é uma consequência que alguém pode cobrar, um crédito, uma multa, o
direito de encerrar o contrato, é um SLA. Se a resposta é que a equipe vai investigar, é um SLO, e
chamá-lo de SLA só o faz parecer exigível.

## O indicador: o que é contado, e onde

Um SLI fica mais fácil de raciocinar escrito como razão: eventos bons divididos por eventos válidos.
As duas metades precisam de definição, e as duas escondem decisões.

*Bom* tem de ser o que o usuário chamaria de bom. Um envio que o portal aceitou depois de 40
segundos não é bom para o dono da padaria parado no balcão às 05:30, então o indicador de Joana conta
um envio como bom só se a confirmação veio em até 5 segundos.

*Válido* exclui o que nunca coube ao sistema acertar. Uma padaria acima do limite de crédito cujo
pedido é recusado recebeu uma resposta correta, e contar isso como falha puniria o portal por aplicar
uma regra. Um pedido de teste do monitoramento da própria equipe do portal não é padaria nenhuma.

Depois vem a pergunta de onde a contagem acontece. **Um serviço medido só pelos próprios logs não
enxerga as requisições que nunca chegaram até ele.** Se o endereço do portal não resolve, ou se o
balanceador de carga na frente dele está recusando conexões, o log do portal mostra uma noite calma e
um SLI perfeito. O indicador de Joana sai do log do balanceador, que é o mais perto das padarias que
o equipamento da própria Serra Alta chega, e uma sonda fora da rede da Serra Alta faz um pedido de
teste a cada cinco minutos para pegar o que nem o balanceador consegue ver.

## O objetivo, e por que não é 100%

Um objetivo de 100% nunca é cumprido, e uma meta que nunca é cumprida deixa de ser lida. Também é a
meta errada: os celulares, as redes e os navegadores das próprias padarias falham mais do que isso, e
o dinheiro gasto além do que o usuário consegue perceber é dinheiro tirado de algo que ele
perceberia.

**Um objetivo tem de ser alcançável pela arquitetura.** A seção anterior pôs a consulta de estoque em
98,41% ao longo de um ano. Um objetivo de 99,9% para envios que dependem dessa consulta é um desejo,
e ou o objetivo desce ou o projeto muda para que o envio não espere mais pelo SAP. Joana escolheu
99,5% e a mudança no projeto, as duas coisas, e escreveu o motivo ao lado do número.

## O orçamento de erro

A parte da janela que o objetivo deixa sobrar é o **orçamento de erro**. Com 99,5%, ele é 0,5% dos
envios válidos. O portal recebe cerca de 24.000 envios de pedido em 30 dias, então o orçamento é
0,005 × 24.000 = 120 envios com falha a cada 30 dias corridos.

O orçamento transforma a confiabilidade de uma opinião numa quantidade que se gasta. Incidentes
gastam. Versões arriscadas gastam. Manutenção planejada que o usuário enxerga gasta. O argumento do
livro de SRE é que isso dá a quem quer lançar funcionalidades e a quem quer estabilidade um número
sobre o qual discutir, em vez de dois temperamentos. **Quando o orçamento acaba, a mudança que o
gastou para**: a política de Joana para o portal diz que, com menos de 20% do orçamento sobrando, as
versões param, exceto correções de confiabilidade, até a janela móvel se recuperar.

Ela testou a política no passado. Os logs de setembro, reprocessados contra o novo SLI, deram isto:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" data-fig=\"l12-budget\" aria-label=\"Um gráfico de linha de setembro reprocessado contra o novo objetivo: envios de pedido com falha somados ao longo de 30 dias, contra um orçamento de erro de 120. Cerca de um envio por dia falha por motivos comuns. No dia 2, durante o fechamento, a consulta de estoque estoura o tempo e a linha sobe 48. No dia 18 uma versão do portal custa mais 32, e a linha chega a 98, além do limite de congelamento em 96, que é 80% do orçamento. O mês termina em 110, abaixo do orçamento de 120.\"><path d=\"M70.0 270.0 L690.0 270.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M70.0 270.0 L70.0 40.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"270.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"62.0\" y=\"199.2\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">40</text><text x=\"62.0\" y=\"128.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">80</text><text x=\"62.0\" y=\"57.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">120</text><text x=\"90.7\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"173.3\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">5</text><text x=\"276.7\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">10</text><text x=\"380.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">15</text><text x=\"483.3\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">20</text><text x=\"586.7\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">25</text><text x=\"690.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">30</text><text x=\"380.0\" y=\"302.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">dia de setembro</text><text x=\"18.0\" y=\"195.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">falhas</text><path d=\"M70.0 57.7 L690.0 57.7\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"76.0\" y=\"48.7\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">orçamento de erro: 120 envios com falha em 30 dias</text><path d=\"M70.0 100.2 L690.0 100.2\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"76.0\" y=\"110.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">80% gasto: as versões param</text><path d=\"M70.0 270.0 L90.7 268.2 L110.9 266.5 L111.3 181.5 L132.0 179.8 L152.7 178.0 L173.3 176.2 L194.0 174.5 L214.7 172.7 L235.3 170.9 L256.0 169.2 L276.7 167.4 L297.3 165.6 L318.0 163.8 L338.7 162.1 L359.3 160.3 L380.0 158.5 L400.7 156.8 L421.3 155.0 L441.6 153.2 L442.0 96.6 L462.7 94.8 L483.3 93.1 L504.0 91.3 L524.7 89.5 L545.3 87.8 L566.0 86.0 L586.7 84.2 L607.3 82.5 L628.0 80.7 L648.7 78.9 L669.3 77.2 L690.0 75.4\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"442.0\" cy=\"96.6\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"690.0\" cy=\"75.4\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><text x=\"119.3\" y=\"197.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">dia 2: fechamento, a consulta estoura o tempo, +48</text><text x=\"434.0\" y=\"66.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">dia 18: uma versão do portal, +32 → 98</text><text x=\"686.0\" y=\"91.4\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">110 no fim</text></svg>", "caption": "Setembro, reprocessado contra o novo objetivo. Dois incidentes gastaram a maior parte do orçamento, e a partir da noite do dia 18 a política teria parado as versões."}
```

Cerca de um envio por dia falhou por motivos comuns, a conexão que caiu e o navegador que desistiu.
Em 2 de setembro, o segundo dia útil do fechamento de agosto, o SAP ficou lento com o processamento
do fechamento e a consulta de estoque estourou o tempo para 48 padarias. Em 18 de setembro uma versão
do portal quebrou o carrinho numa versão de navegador e custou mais 32. Na noite do dia 18 o mês
tinha gastado 98 dos 120: 82% do orçamento, com doze dias ainda pela frente. Pela nova política, a
equipe do portal teria congelado as versões naquela noite. O mês terminou em 110, dentro do objetivo.
Ninguém tinha notado nada na época, porque ninguém estava contando.

## O SLA que um fornecedor vende

Todo fornecedor de software como serviço publica um compromisso de disponibilidade, e o parque da
Serra Alta está cheio deles: Salesforce, Microsoft 365, o provedor de EDI, o gateway de arquivos do
banco. Eles diferem nos números e concordam no formato, e é o formato que um arquiteto lê:

| o que o contrato diz | o que isso significa para você |
|---|---|
| um percentual mensal | medido pelo fornecedor, na borda do fornecedor, não nos seus usuários |
| exclusões | manutenção planejada, e causas fora do controle do fornecedor, não contam como queda |
| a reparação | um crédito de serviço: um percentual da mensalidade daquele mês, em geral pedido por você dentro de um prazo |
| o limite | o crédito tem teto, e é a única reparação pela queda |

O contrato da Serra Alta com o provedor de EDI é um bom exemplo. Ele promete 99,5% ao mês e, abaixo
disso, um crédito de 10% da mensalidade. A mensalidade é R$ 6.000, então o crédito por um mês ruim é
R$ 600. Num dia útil, pedidos que somam cerca de R$ 4 milhões chegam à Serra Alta por esse provedor,
vindos das redes de supermercado. **O SLA de um fornecedor é uma cláusula de preço, não uma
arquitetura.** Ele diz o que o fornecedor vai devolver quando falhar. Não diz nada sobre o que o
negócio precisa enquanto ele está falhando, e a distância entre as duas coisas é o trabalho de
projeto: uma fila que guarda os pedidos, uma segunda rota para os maiores clientes, uma pessoa que
sabe receber um pedido por e-mail.

Por isso a política de Joana guarda dois números para cada serviço externo: o compromisso que o
fornecedor vende e o objetivo de que a Serra Alta precisa. Onde o segundo é maior que o primeiro, o
registro de contratos (duas seções adiante) tem de dizer o que cobre a diferença.

## Dentro da empresa

Entre as equipes da própria Serra Alta não há dinheiro para mudar de mãos. Quando a equipe de Rui
promete à equipe do portal que o barramento vai responder, não há crédito a pagar se ele não
responder. O ITIL chama uma promessa interna desse tipo de acordo de nível operacional, um OLA, para
separá-la do contrato com os clientes. A política de Joana chama essas promessas de objetivos, que é
o que elas são, e dá a cada uma a consequência que uma promessa interna consegue carregar de verdade:
um orçamento, um congelamento de versões quando ele acaba e uma revisão com as duas equipes na sala.
**Um "SLA" interno sem consequência é um SLO que reivindica uma autoridade que não tem**, e o primeiro
mês descumprido ensina isso a todo mundo.
