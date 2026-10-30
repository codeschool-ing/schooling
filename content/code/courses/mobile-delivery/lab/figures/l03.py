"""Lesson 3: the proceeds script."""
P = [
    ("// proceeds.ts: what a price leaves after the store's commission, and how many sales pay for the accounts\nconst priceCents = Number(process.argv[2] ?? 1999);\nconst accountsCents = 99_00 + 25_00;",
     "The price comes in as cents: `1999` is 19.99. The accounts are Apple's first year plus Google's one-off fee, in cents too.",
     "O preço chega em centavos: `1999` é 19,99. As contas são o primeiro ano da Apple mais a taxa única do Google, também em centavos."),
    ("function money(cents: number): string {\n  return (cents / 100).toFixed(2);\n}",
     "Cents become a printed amount only at the very end, for a person to read.",
     "Os centavos viram um valor impresso só no fim, para uma pessoa ler."),
    ("console.log(`price ${money(priceCents)}, accounts in the first year ${money(accountsCents)}`);\nfor (const rate of [15, 30]) {\n  const commission = Math.round((priceCents * rate) / 100);\n  const proceeds = priceCents - commission;",
     "The commission is rounded to the nearest cent, and the proceeds are what is left. Taxes are left out on purpose.",
     "A comissão é arredondada para o centavo mais próximo, e o repasse é o que sobra. Os impostos ficam de fora de propósito."),
    ("  const needed = Math.ceil(accountsCents / proceeds);\n  console.log(`${rate}%  commission ${money(commission)}  proceeds ${money(proceeds)}  sales to cover the accounts ${needed}`);\n}",
     "Rounded up, because seven and a third sales are eight sales.",
     "Arredondado para cima, porque sete vendas e um terço são oito vendas."),
]
EXAMPLES = {"what-it-costs": [{"language": "typescript", "file": "proceeds.ts", "parts": P}]}
