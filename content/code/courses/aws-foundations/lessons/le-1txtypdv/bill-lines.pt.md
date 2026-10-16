---
title: As linhas de uma fatura
version: 1
---

**Uma fatura é uma lista de linhas, e toda linha tem um tipo que diz que tipo de dinheiro ela é.** A
imagem comum é uma linha por serviço, EC2 tanto, S3 tanto. Isso é o resumo da primeira página da
fatura. Por baixo, uma hora de uma instância pode ser uma linha, duas ou três, conforme o jeito como
foi paga, e quem soma as erradas conta a mesma hora duas vezes. **O moto não tem fatura**, então nada
aqui foi capturado: os tipos de linha abaixo são os que a AWS documenta para o seu Cost and Usage
Report, e os valores são as tarifas da lista de preços da seção sobre pagar por uma máquina,
aplicadas a uma hora.

## Os tipos

| tipo de linha | o que é |
|---|---|
| `Usage` | uso cobrado pela tarifa sob demanda |
| `DiscountedUsage` | uso coberto por uma Reserved Instance; o custo dela própria é zero, porque a taxa da reserva o carrega |
| `RIFee` | a taxa recorrente da reserva no mês, por toda hora reservada, usada ou não |
| `Fee` | uma cobrança única, como o pagamento adiantado de uma reserva no dia da compra |
| `SavingsPlanCoveredUsage` | uso coberto por um Savings Plan, mostrado pelo custo sob demanda |
| `SavingsPlanNegation` | o mesmo valor com sinal de menos, que anula a linha acima |
| `SavingsPlanRecurringFee` | o compromisso do plano naquela hora, cobrado tenha o uso o preenchido ou não |
| `SavingsPlanUpfrontFee` | o pagamento adiantado de um plano, no dia da compra |
| `Tax` | imposto sobre as cobranças do mês, pelas regras de onde a conta é faturada |
| `Credit` | uma linha negativa, créditos aplicados às cobranças |
| `Refund` | uma linha negativa, dinheiro que a AWS devolveu |

## Uma hora, três jeitos

Pegue uma hora do `m7i.large` da loja em São Paulo, paga de cada um dos três jeitos:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l14-lines\" aria-label=\"Uma hora de um m7i.large em sa-east-1 na fatura, paga de três jeitos, pelas tarifas das listas de preços de 25 de setembro de 2026. Sob demanda: uma linha, Usage, 0,16065. Sob uma Reserved Instance padrão: duas linhas, DiscountedUsage a 0,00000 e a parte desta hora do RIFee, 0,09956; pago 0,09956. Sob um Compute Savings Plan: três linhas, SavingsPlanCoveredUsage a 0,16065, SavingsPlanNegation a menos 0,16065, e SavingsPlanRecurringFee a 0,10915; pago 0,10915.\"><text x=\"125.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">sob demanda</text><rect x=\"20.0\" y=\"46.0\" width=\"210.0\" height=\"196.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"30.0\" y=\"62.0\" width=\"190.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"40.0\" y=\"75.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Usage</text><text x=\"210.0\" y=\"91.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.16065</text><path d=\"M30.0 222.0 L220.0 222.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"40.0\" y=\"232.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">pago pela hora</text><text x=\"210.0\" y=\"232.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">0.16065</text><text x=\"360.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">reserva padrão</text><rect x=\"255.0\" y=\"46.0\" width=\"210.0\" height=\"196.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"265.0\" y=\"62.0\" width=\"190.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"275.0\" y=\"75.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">DiscountedUsage</text><text x=\"445.0\" y=\"91.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.00000</text><rect x=\"265.0\" y=\"114.0\" width=\"190.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"275.0\" y=\"127.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">RIFee</text><text x=\"275.0\" y=\"143.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">a parte desta hora</text><text x=\"445.0\" y=\"143.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.09956</text><path d=\"M265.0 222.0 L455.0 222.0\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"275.0\" y=\"232.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">pago pela hora</text><text x=\"445.0\" y=\"232.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">0.09956</text><text x=\"595.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">Compute Savings Plan</text><rect x=\"490.0\" y=\"46.0\" width=\"210.0\" height=\"196.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"500.0\" y=\"62.0\" width=\"190.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"510.0\" y=\"75.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">SavingsPlanCoveredUsage</text><text x=\"680.0\" y=\"91.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.16065</text><rect x=\"500.0\" y=\"114.0\" width=\"190.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"510.0\" y=\"127.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">SavingsPlanNegation</text><text x=\"680.0\" y=\"143.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">-0.16065</text><rect x=\"500.0\" y=\"166.0\" width=\"190.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"510.0\" y=\"179.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">SavingsPlanRecurringFee</text><text x=\"680.0\" y=\"195.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.10915</text><path d=\"M500.0 222.0 L690.0 222.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"510.0\" y=\"232.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pago pela hora</text><text x=\"680.0\" y=\"232.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">0.10915</text><text x=\"360.0\" y=\"272.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">tipos de linha documentados, com preços da lista; não é uma fatura capturada</text></svg>", "caption": "A mesma hora é uma linha, duas ou três. O que foi pago está no pé de cada coluna.", "same": ["Compute Savings Plan"]}
```

Sob demanda ela é **uma linha**, `Usage`, a 0,16065. Coberta por uma reserva padrão ela é **duas**:
uma linha `DiscountedUsage` que registra a hora e sozinha não custa nada, e a parte desta hora da
linha `RIFee` do mês, 0,09956. Coberta por um Compute Savings Plan ela é **três**: a linha
`SavingsPlanCoveredUsage` pelos 0,16065 sob demanda, uma `SavingsPlanNegation` de menos 0,16065 que a
anula, e a `SavingsPlanRecurringFee` de 0,10915 que é o que foi pago de verdade.

**A negação existe para que o valor sob demanda fique na fatura.** Somar o uso coberto diz quanto a hora teria custado sem o plano, e somar a
taxa recorrente diz quanto ela custou. A diferença, 0,05150, é a economia da hora, e pode ser
calculada só com a fatura. A mesma ideia no Cost Report é uma
coluna, o custo efetivo do plano em cada linha coberta, que a lição 15 consulta.

**Um compromisso sem nada para cobrir ainda tem a sua linha de taxa.** Um mês em que a instância
reservada ficou parada dez dias tem um `RIFee` para cada hora do mês e `DiscountedUsage` só para as
horas em que rodou. Uma hora de Savings Plan sem uso elegível tem uma `SavingsPlanRecurringFee` e nada
ao lado. Essas taxas sem par são o compromisso desperdiçado, e é onde um leitor olha primeiro depois
de uma compra.

## As linhas que não são uso

`Tax` é calculado sobre as cobranças do mês onde a conta é faturada, por isso um orçamento o inclui
por padrão, como o `IncludeTax: true` da lição 13 mostrou. `Credit` e `Refund` são negativos e chegam
como linhas próprias em vez de mudanças nas linhas que compensam, então o uso continua visível pelo
seu preço. **Créditos são o motivo de uma fatura poder mostrar zero com uso real**, e o motivo de a
lição 13 aconselhar um orçamento que os deixe de fora.

Numa fatura consolidada (lição 3) cada uma dessas linhas também traz a conta que usou e a conta que
paga, então uma reserva comprada numa conta aparece como `RIFee` lá e como `DiscountedUsage` na conta
cuja instância ela cobriu.
