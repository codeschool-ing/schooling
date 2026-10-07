---
title: Ao longo do tempo
version: 1
---

Receita por mês, com os pedidos corporativos numa coluna à parte:

```
ana@lab:~/clean$ python -c "from explore import delivered as d; t = d.pivot_table(index='month', columns='corporate', values='total', aggfunc='sum', fill_value=0); t.columns = ['households', 'corporate']; print(t.round(2).to_string())"
         households  corporate
month                         
2025-01   124345.55        0.0
2025-02   125994.10        0.0
2025-03   164724.00        0.0
2025-04   183386.20        0.0
2025-05   206236.00        0.0
2025-06   198896.40        0.0
2025-07   234079.30        0.0
2025-08   217824.80        0.0
2025-09   202106.80        0.0
2025-10   196915.80        0.0
2025-11   225730.60        0.0
2025-12   300498.10   112810.5
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l15-months\" aria-label=\"Um gráfico de barras empilhadas da receita dos pedidos entregues por mês em 2025. A receita das famílias cresce de uns R$ 124 mil em janeiro para R$ 226 mil em novembro e R$ 300 mil em dezembro; os pedidos corporativos, só em dezembro, somam uns R$ 113 mil por cima.\"><rect x=\"87.1\" y=\"177.1\" width=\"36.6\" height=\"52.9\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"138.0\" y=\"176.4\" width=\"36.6\" height=\"53.6\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"188.8\" y=\"159.9\" width=\"36.6\" height=\"70.1\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"239.6\" y=\"151.9\" width=\"36.6\" height=\"78.1\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"290.4\" y=\"142.2\" width=\"36.6\" height=\"87.8\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"341.3\" y=\"145.3\" width=\"36.6\" height=\"84.7\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"392.1\" y=\"130.4\" width=\"36.6\" height=\"99.6\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"442.9\" y=\"137.3\" width=\"36.6\" height=\"92.7\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"493.8\" y=\"144.0\" width=\"36.6\" height=\"86.0\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"544.6\" y=\"146.2\" width=\"36.6\" height=\"83.8\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"595.5\" y=\"133.9\" width=\"36.6\" height=\"96.1\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"646.3\" y=\"102.1\" width=\"36.6\" height=\"127.9\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"646.3\" y=\"54.1\" width=\"36.6\" height=\"48.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><path d=\"M80.0 40.0 L80.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M76.0 230.0 L80.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"230.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0k</text><path d=\"M76.0 187.4 L80.0 187.4\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"187.4\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100k</text><path d=\"M76.0 144.9 L80.0 144.9\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"144.9\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">200k</text><path d=\"M76.0 102.3 L80.0 102.3\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"102.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">300k</text><path d=\"M76.0 59.7 L80.0 59.7\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"59.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">400k</text><text x=\"80.0\" y=\"26.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">receita, R$</text><path d=\"M80.0 230.0 L690.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"105.4\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">jan</text><text x=\"156.2\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fev</text><text x=\"207.1\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">mar</text><text x=\"257.9\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">abr</text><text x=\"308.8\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">mai</text><text x=\"359.6\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">jun</text><text x=\"410.4\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">jul</text><text x=\"461.2\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ago</text><text x=\"512.1\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">set</text><text x=\"562.9\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">out</text><text x=\"613.8\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nov</text><text x=\"664.6\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dez</text><rect x=\"90.0\" y=\"272.0\" width=\"12.0\" height=\"12.0\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"108.0\" y=\"278.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">famílias</text><rect x=\"220.0\" y=\"272.0\" width=\"12.0\" height=\"12.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"238.0\" y=\"278.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">corporativos</text></svg>", "caption": "Dezembro são duas histórias, e a marca da aula 9 é o que as mantém separadas.", "same": ["0k", "100k", "200k", "300k", "400k"]}
```

Três coisas se destacam, e cada uma ainda é uma pergunta, não uma resposta.

- **Crescimento.** A receita das famílias quase dobra ao longo do ano, de R$ 124.345,55 em janeiro
  para R$ 225.730,60 em novembro. Se isso é mais clientes ou cestas maiores é a próxima coisa a
  olhar, e a tabela `per_customer` da aula 12 sabe dizer.
- **Dezembro.** Só as famílias chegam a R$ 300.498,10, um terço acima de novembro, e os dezesseis
  pedidos corporativos somam R$ 112.810,50 por cima. A marca da aula 9 é o que permite separar os
  dois: sem ela, dezembro pareceria um salto de 83% no comércio comum.
- **Julho.** A receita sobe em julho e volta a cair em agosto. Um mês só prova pouco, mas vale uma
  olhada, e um produto explica parte disso.

```
ana@lab:~/clean$ python -c "from explore import sold, delivered; s = sold[sold['code'] == '00343'].merge(delivered[['order_id', 'month']], on='order_id'); print(s.groupby('month')['unit_price'].agg(['size', 'min', 'max']).to_string())"
         size    min    max
month                      
2025-01    48   12.9   12.9
2025-02    42   12.9   12.9
2025-03    56   12.9   12.9
2025-04    70   12.9   12.9
2025-05    78   12.9   12.9
2025-06    81   12.9   12.9
2025-07    75  134.9  134.9
2025-08    83  134.9  134.9
2025-09    73  134.9  134.9
2025-10    68  134.9  134.9
2025-11    71  134.9  134.9
2025-12   100  134.9  134.9
```

Todo pacote de açúcar foi vendido a R$ 12,90 até junho e a R$ 134,90 a partir de julho, mais de dez
vezes mais. A aula 9 rastreou isso até o preço digitado no catálogo e a aula 11 o encontrou como
chave repetida. **Aqui ele aparece como um degrau numa série temporal**, que é como alguém do
negócio teria notado: não como chave nem como erro de digitação, e sim como um produto cuja receita
saltou da noite para o dia sem aumento de vendas.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l15-sugar\" aria-label=\"Um gráfico em degrau do preço cobrado por um pacote de açúcar em cada mês de 2025: R$ 12,90 de janeiro a junho, depois R$ 134,90 de julho a dezembro, sem nenhum mês no meio.\"><path d=\"M80.0 186.2 L130.8 186.2 L130.8 186.2 L181.7 186.2 L181.7 186.2 L232.5 186.2 L232.5 186.2 L283.3 186.2 L283.3 186.2 L334.2 186.2 L334.2 186.2 L385.0 186.2 L385.0 56.1 L435.8 56.1 L435.8 56.1 L486.7 56.1 L486.7 56.1 L537.5 56.1 L537.5 56.1 L588.3 56.1 L588.3 56.1 L639.2 56.1 L639.2 56.1 L690.0 56.1\" stroke=\"var(--amber)\" stroke-width=\"2.4\" fill=\"none\"></path><circle cx=\"105.4\" cy=\"186.2\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"156.2\" cy=\"186.2\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"207.1\" cy=\"186.2\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"257.9\" cy=\"186.2\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"308.8\" cy=\"186.2\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"359.6\" cy=\"186.2\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"410.4\" cy=\"56.1\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"461.2\" cy=\"56.1\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"512.1\" cy=\"56.1\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"562.9\" cy=\"56.1\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"613.8\" cy=\"56.1\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"664.6\" cy=\"56.1\" r=\"3.5\" fill=\"var(--amber)\"></circle><path d=\"M80.0 40.0 L80.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M76.0 200.0 L80.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"200.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M80.0 146.7 L690.0 146.7\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 146.7 L80.0 146.7\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"146.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">50</text><path d=\"M80.0 93.3 L690.0 93.3\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 93.3 L80.0 93.3\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"93.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100</text><path d=\"M80.0 40.0 L690.0 40.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 40.0 L80.0 40.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">150</text><text x=\"80.0\" y=\"26.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">preço, R$</text><path d=\"M80.0 200.0 L690.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"105.4\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">jan</text><text x=\"156.2\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fev</text><text x=\"207.1\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">mar</text><text x=\"257.9\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">abr</text><text x=\"308.8\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">mai</text><text x=\"359.6\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">jun</text><text x=\"410.4\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">jul</text><text x=\"461.2\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ago</text><text x=\"512.1\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">set</text><text x=\"562.9\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">out</text><text x=\"613.8\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nov</text><text x=\"664.6\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dez</text><text x=\"232.5\" y=\"172.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">12,90</text><text x=\"537.5\" y=\"72.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">134,90</text></svg>", "caption": "O erro de catálogo da aula 9, como alguém do negócio o encontraria primeiro: um produto cujo preço saltou da noite para o dia."}
```

Gráficos assim são o assunto do próximo curso, `visualization`. Para explorar, um gráfico rápido
salvo num arquivo basta, e o matplotlib, instalado na aula 1, desenha um em poucas linhas:

```python
import matplotlib

matplotlib.use("Agg")  # draw to a file; there is no screen here
import matplotlib.pyplot as plt

from explore import delivered

monthly = delivered.pivot_table(index="month", columns="corporate", values="total",
                                aggfunc="sum", fill_value=0)
fig, ax = plt.subplots(figsize=(8, 4))
monthly.plot.bar(stacked=True, ax=ax, color=["#4a7fd4", "#e0a030"])
ax.set_xlabel("")
ax.set_ylabel("revenue, R$")
ax.legend(["households", "corporate"])
fig.tight_layout()
fig.savefig("months.png", dpi=120)
print("months.png:", monthly.shape[0], "months")
```

```
ana@lab:~/clean$ python plots.py
months.png: 12 months
ana@lab:~/clean$ file months.png
months.png: PNG image data, 960 x 480, 8-bit/color RGBA, non-interlaced
```

`matplotlib.use("Agg")` diz a ele para desenhar num arquivo em vez de numa janela, porque o
laboratório não tem tela. As figuras desta página são desenhadas pelo próprio curso a partir dos
mesmos números, para ficarem iguais nos dois temas; o PNG é o que você anexaria a uma mensagem ou
abriria na sua própria máquina.
