---
title: Quanto custa, e o que chega até você
version: 1
---

**Há dois tipos de custo, e só o primeiro é pequeno: a taxa da conta e a parte de cada venda que a
loja fica.** O preço que você define não é o que você recebe, e vale fazer a conta antes de
escolher o preço.

## As contas

| | Google Play | Apple |
|---|---|---|
| a conta | uma taxa de registro única de 25 dólares americanos | 99 dólares americanos por ano de assinatura, ou o preço local |
| renovação | nenhuma | todo ano; uma assinatura vencida tira os apps da loja |
| isenções | nenhuma | para organizações sem fins lucrativos, escolas credenciadas e órgãos de governo que se qualificam |

*O valor da Apple é da página de inscrição dela, outubro de 2026. O do Google é o que a central de
ajuda dele dava em 2025, que a máquina de gravação não conseguiu abrir; o console mostra o preço
antes de cobrar.*

## A parte de cada venda

As duas lojas ficam com uma **comissão** sobre os bens digitais que vendem por você: o preço do
app, uma compra dentro do app, uma assinatura. A da Apple é de 30%, e de 15% para desenvolvedores
no Small Business Program dela, aberto a quem teve um repasse de até um milhão de dólares no ano
civil anterior, e para assinaturas depois do primeiro ano. A taxa de serviço do Google é de 15% no
primeiro milhão de dólares de ganhos de cada ano e nas assinaturas. O **repasse** é o que sobra: o
preço, menos o imposto que a loja recolhe no país do comprador, menos a comissão.

Nenhuma das lojas fica com parte de um app gratuito, e nenhuma fica com parte de bens físicos ou de
um serviço usado fora do app, como uma corrida de táxi reservada nele.

## A conta, como script

Dinheiro é contado em **centavos inteiros**, nunca como fração de dólar: `0.1 + 0.2` não é `0.3`
em ponto flutuante, e o relatório de uma loja é em centavos. Salve isto como `proceeds.ts`:

```schooling-example
{"language": "typescript", "file": "proceeds.ts", "parts": [{"code": "// proceeds.ts: what a price leaves after the store's commission, and how many sales pay for the accounts\nconst priceCents = Number(process.argv[2] ?? 1999);\nconst accountsCents = 99_00 + 25_00;", "note": "O preço chega em centavos: `1999` é 19,99. As contas são o primeiro ano da Apple mais a taxa única do Google, também em centavos."}, {"code": "function money(cents: number): string {\n  return (cents / 100).toFixed(2);\n}", "note": "Os centavos viram um valor impresso só no fim, para uma pessoa ler."}, {"code": "console.log(`price ${money(priceCents)}, accounts in the first year ${money(accountsCents)}`);\nfor (const rate of [15, 30]) {\n  const commission = Math.round((priceCents * rate) / 100);\n  const proceeds = priceCents - commission;", "note": "A comissão é arredondada para o centavo mais próximo, e o repasse é o que sobra. Os impostos ficam de fora de propósito."}, {"code": "  const needed = Math.ceil(accountsCents / proceeds);\n  console.log(`${rate}%  commission ${money(commission)}  proceeds ${money(proceeds)}  sales to cover the accounts ${needed}`);\n}", "note": "Arredondado para cima, porque sete vendas e um terço são oito vendas."}]}
```

```
ana@dev:~/planner$ node proceeds.ts 1999
price 19.99, accounts in the first year 124.00
15%  commission 3.00  proceeds 16.99  sales to cover the accounts 8
30%  commission 6.00  proceeds 13.99  sales to cover the accounts 9
ana@dev:~/planner$ node proceeds.ts 499
price 4.99, accounts in the first year 124.00
15%  commission 0.75  proceeds 4.24  sales to cover the accounts 30
30%  commission 1.50  proceeds 3.49  sales to cover the accounts 36
```

Uma assinatura do planner a 19,99 por ano deixa 16,99 a 15% e 13,99 a 30%, e as duas contas custam
124 dólares no primeiro ano. **Oito assinantes pagam o primeiro ano na taxa reduzida; nove na
padrão.** A 4,99 são precisos 30 e 36. O script deixa de fora o imposto, que as lojas retêm por país
antes da comissão, então um relatório de verdade no Brasil ou na União Europeia mostra menos do que
essas linhas.

## As outras duas plataformas

Nada disso muda com a linguagem em que o app é escrito. Um app React Native paga as mesmas duas
taxas e as mesmas comissões que um em Kotlin ou em Swift, porque o que as lojas vendem é o app, e
não o código dele.
