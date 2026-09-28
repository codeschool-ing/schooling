---
title: CLT contra PJ
version: 1
---

**No Brasil**, o mesmo número mensal significa coisas diferentes num contrato *CLT* e como *PJ*. Um salário
CLT vem com três pagamentos fixados em lei além dos doze meses: o **13º salário**, **um terço a mais no mês
de férias**, e o **FGTS**, depositado pelo empregador a 8% do que paga. Uma nota PJ não vem com nenhum deles.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"Do que é feito um ano CLT, em salários mensais: doze salários mensais; um 13º salário; um terço de salário no mês de férias; e o FGTS a 8 por cento, pouco mais de um salário. Juntos, cerca de 14,4 salários mensais por ano, antes de impostos e benefícios.\"><defs><marker id=\"pa17-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"563.6666666666666\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"28\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">12 salários mensais</text><rect x=\"586.6666666666666\" y=\"40\" width=\"44.22222222222222\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"633.8888888888888\" y=\"40\" width=\"12.74074074074074\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"649.6296296296296\" y=\"40\" width=\"47.37037037037037\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">13º salário · terço de férias · FGTS, 8%</text><text x=\"20\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">≈ 14,4 salários mensais por ano, antes de impostos e benefícios</text></svg>", "caption": "O motivo de uma proposta CLT e uma PJ com o mesmo número mensal não serem a mesma proposta. As partes são fixadas em lei; o valor mensal não está no desenho porque não muda as proporções."}
```

A conta, com um valor mensal escolhido só para ficar fácil de acompanhar:

```schooling-example
{"language": "python", "file": "clt_pj.py", "parts": [{"code": "# What a CLT salary is worth in a year, and the PJ invoice that matches it.\n# The monthly figure is an example, not a market rate. Taxes are left out on\n# purpose: INSS and income tax change with each year's tables.\nmonthly = 3000.00\n", "note": "A entrada é um número, o salário bruto mensal de uma proposta CLT. É um exemplo escolhido para a conta ficar fácil de acompanhar, e não um valor de mercado."}, {"code": "thirteenth = monthly             # 13º salário: one extra month a year\nholiday_third = monthly / 3      # férias: a month paid, plus one third\nfgts = 0.08 * (12 * monthly + thirteenth + holiday_third)\n", "note": "As três coisas que um contrato CLT paga além de doze salários, cada uma fixada em lei: o 13º, o terço a mais no mês de férias, e o FGTS, que o empregador deposita a 8% do que paga."}, {"code": "clt_year = 12 * monthly + thirteenth + holiday_third + fgts\nprint(f\"CLT, a year before tax: R$ {clt_year:10,.2f}\")\nprint(f\"  that is {clt_year / monthly:.2f} monthly salaries\")\n", "note": "Some tudo. A linha que importa é a segunda: quantos salários mensais o ano vale, o que não depende do valor de exemplo."}, {"code": "for months_invoiced in (12, 11):\n    pj = clt_year / months_invoiced\n    print(f\"PJ invoice to match it, {months_invoiced} months billed: R$ {pj:9,.2f}\")\n", "note": "O lado PJ. Quem é PJ e tira um mês de folga fatura onze meses, e não doze, então a nota que empata com o ano CLT é maior que um doze avos dele. Benefícios, impostos e contador vêm por cima disso, e mudam de caso para caso."}]}
```

```
$ python3 clt_pj.py
CLT, a year before tax: R$  43,200.00
  that is 14.40 monthly salaries
PJ invoice to match it, 12 months billed: R$  3,600.00
PJ invoice to match it, 11 months billed: R$  3,927.27
```

A linha que importa é **14.40 monthly salaries**: seja qual for o salário CLT, um ano vale mais ou menos isso
dele antes de impostos. Então uma nota PJ igual ao salário CLT é **um corte de cerca de um sexto** antes de
contar qualquer outra coisa, e maior se você tirar um mês de folga sem receber.

O que o programa deixa de fora, de propósito, são três coisas. **Impostos e contribuições** são diferentes
nos dois casos e mudam com as tabelas de cada ano. Uma empresa PJ paga um contador. E os **benefícios**
(plano de saúde, vale-refeição) costumam vir numa proposta CLT e costumam faltar numa proposta PJ.
Acrescente isso com os valores atuais antes de comparar duas propostas reais; o programa dá a parte que não
muda.

**Fora do Brasil** a mesma pergunta existe como empregado contra prestador de serviço, com outras regras e a
mesma lição: compare o ano, não o mês.
