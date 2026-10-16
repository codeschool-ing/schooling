---
title: Um trace, e por que métricas e logs não bastam
version: 1
---

A lição 8 mediu a latência da API e a lição 9 leu os logs dela. Os dois descrevem **um serviço**. Um
checkout atravessa três: a API, o serviço de pagamentos, e a rede de cartões por trás dele, cada um com
métricas próprias e grupo de logs próprio. Quando o checkout está lento, o painel de cada equipe pode
estar verde: cada serviço é rápido no que faz, e o tempo vai para algum lugar entre eles. **Um trace
segue uma requisição por cada serviço que ela toca**, e diz para onde foi o tempo dela.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Uma cascata de um trace de checkout. O segmento da API, shop-api, vai de 0 a 512 milissegundos. Dentro dele, um subsegmento de orders-db leva 27 milissegundos e uma chamada a payments leva 470. O segmento do próprio serviço de pagamentos começa 6 milissegundos depois da chamada e leva 457, e dentro dele um subsegmento da rede de cartões leva 420 milissegundos.\"><defs><marker id=\"wf-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"39\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop-api</text><text x=\"120\" y=\"39\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">segmento da API</text><rect x=\"230.0\" y=\"28\" width=\"450.6\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"238.0\" y=\"39\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">512 ms</text><text x=\"20\" y=\"75\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">orders-db</text><text x=\"120\" y=\"75\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">subsegmento</text><rect x=\"233.5\" y=\"64\" width=\"23.8\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"263.3\" y=\"75\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">27 ms</text><text x=\"20\" y=\"111\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">payments</text><text x=\"120\" y=\"111\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">chamada, na API</text><rect x=\"260.8\" y=\"100\" width=\"413.6\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"268.8\" y=\"111\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">470 ms</text><text x=\"20\" y=\"147\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">payments</text><text x=\"120\" y=\"147\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">segmento de pagamentos</text><rect x=\"266.1\" y=\"136\" width=\"402.2\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"674.2\" y=\"147\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">457 ms</text><text x=\"20\" y=\"183\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">card-network</text><text x=\"120\" y=\"183\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">subsegmento</text><rect x=\"274.0\" y=\"172\" width=\"369.6\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"649.6\" y=\"183\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">420 ms</text><path d=\"M230 214 L680.56 214\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"230\" y=\"228\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0 ms</text><text x=\"680.56\" y=\"228\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">512 ms</text></svg>", "caption": "Os números são os segmentos que esta lição escreve. A maior parte da requisição é gasta dois serviços adiante."}
```

O vocabulário é pequeno:

- um **trace** é a jornada inteira de uma requisição, com um id de trace compartilhado por todas as
  partes;
- um **segmento** é a parte que um serviço tratou, do momento em que a requisição chegou ao momento em
  que ele respondeu;
- um **subsegmento** é um pedaço de um segmento: uma consulta ao banco, uma chamada a outro serviço, um
  bloco de código que vale cronometrar;
- um **parent id** liga o segmento de um serviço ao subsegmento do chamador que fez a chamada.

Os ids viajam com a requisição. Na AWS o portador é um cabeçalho HTTP, `X-Amzn-Trace-Id`, com o id do
trace, o id do pai e uma decisão de amostragem:
`Root=1-6ad25543-8f4d3e27dda1494c73cf256d;Parent=53995c3f42cd8ad8;Sampled=1`. Um balanceador acrescenta
o cabeçalho se ele faltar, cada serviço instrumentado o repassa, e um serviço que o perde parte o trace
em dois.

## Métricas, logs e traces

Os três respondem a perguntas diferentes, e um incidente os usa nesta ordem:

| | responde | exemplo |
|---|---|---|
| métricas | há algo errado, e desde quando | o p99 do checkout subiu de 400 ms para 1,4 s às 14:02 |
| traces | onde na cadeia está o tempo ou o erro | 420 de 512 ms esperando a rede de cartões |
| logs | o que exatamente aconteceu lá | a rede de cartões respondeu `timeout` para o cliente c-1027 |

Um id de trace escrito em cada linha de log junta os dois últimos: de um trace lento, ache as linhas de
log dele; de uma linha de erro, ache o trace. **Escreva o id do trace em cada linha de log
estruturada**, que é um campo a mais no JSON da lição 9.
