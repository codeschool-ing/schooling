---
title: Rótulos que não terminaram
version: 1
---

O rótulo é calculado pelo `features.py`: *nenhuma compra nos 90 dias depois do corte*. Para um corte
a menos de 90 dias do último dia do banco, parte desses 90 dias não aconteceu, e **um membro que só
não teve tempo de voltar é rotulado como afastado.** Nenhum erro, nenhum aviso, só um rótulo errado
numa direção.

O quanto errado está a um programa de distância. Salve-o como `maturity.py`:

```python
"""maturity.py: the share of members labelled lapsed, cutoff by cutoff."""
import features

for cutoff in ["2025-10-31", "2025-11-15", "2025-11-30", "2025-12-15", "2025-12-31",
               "2026-01-15", "2026-01-31", "2026-02-15"]:
    rows = features.build(cutoff)
    print(f"{cutoff}  {len(rows):5} active  {rows['lapsed'].mean():6.1%} lapsed")
```

```
ana@dev:~/ml$ python maturity.py
2025-10-31   3038 active   17.1% lapsed
2025-11-15   3094 active   17.0% lapsed
2025-11-30   3130 active   16.9% lapsed
2025-12-15   3165 active   19.2% lapsed
2025-12-31   3208 active   23.2% lapsed
2026-01-15   3244 active   30.1% lapsed
2026-01-31   3291 active   43.1% lapsed
2026-02-15   3316 active   65.5% lapsed
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l03-maturity\" aria-label=\"Fração de membros ativos rotulados como afastados, por corte: 17,1% em 31 de outubro, 17,0% em 15 de novembro, 16,9% em 30 de novembro, depois 19,2%, 23,2%, 30,1%, 43,1% e 65,5% em 15 de fevereiro, à medida que a janela de 90 dias passa do último dia dos dados.\"><path d=\"M70.0 40.0 L70.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M66.0 220.0 L70.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"220.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0%</text><path d=\"M70.0 168.6 L690.0 168.6\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 168.6 L70.0 168.6\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"168.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20%</text><path d=\"M70.0 117.1 L690.0 117.1\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 117.1 L70.0 117.1\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"117.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">40%</text><path d=\"M70.0 65.7 L690.0 65.7\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 65.7 L70.0 65.7\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"65.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">60%</text><text x=\"70.0\" y=\"26.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">rotulados afastados</text><path d=\"M70.0 220.0 L690.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M93.4 220.0 L93.4 176.0 L137.4 176.0 L137.4 220.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"115.4\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">17,1%</text><text x=\"115.4\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">25-10-31</text><path d=\"M169.0 220.0 L169.0 176.3 L213.0 176.3 L213.0 220.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"191.0\" y=\"167.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">17,0%</text><text x=\"191.0\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">25-11-15</text><path d=\"M244.6 220.0 L244.6 176.5 L288.6 176.5 L288.6 220.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"266.6\" y=\"167.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">16,9%</text><text x=\"266.6\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">25-11-30</text><path d=\"M320.2 220.0 L320.2 170.6 L364.2 170.6 L364.2 220.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><text x=\"342.2\" y=\"161.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">19,2%</text><text x=\"342.2\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">25-12-15</text><path d=\"M395.8 220.0 L395.8 160.3 L439.8 160.3 L439.8 220.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><text x=\"417.8\" y=\"151.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">23,2%</text><text x=\"417.8\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">25-12-31</text><path d=\"M471.4 220.0 L471.4 142.6 L515.4 142.6 L515.4 220.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><text x=\"493.4\" y=\"133.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">30,1%</text><text x=\"493.4\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">26-01-15</text><path d=\"M547.0 220.0 L547.0 109.2 L591.0 109.2 L591.0 220.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><text x=\"569.0\" y=\"100.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">43,1%</text><text x=\"569.0\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">26-01-31</text><path d=\"M622.6 220.0 L622.6 51.6 L666.6 51.6 L666.6 220.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><text x=\"644.6\" y=\"42.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">65,5%</text><text x=\"644.6\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">26-02-15</text><text x=\"191.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">janela fechada</text><text x=\"531.2\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">janela ainda aberta</text></svg>", "caption": "O rótulo é honesto até a janela passar dos dados. Depois disso, todo membro que ainda não voltou conta como perdido."}
```

Até 30 de novembro a fração fica em 17%, porque os 90 dias desses cortes acabaram até 28 de
fevereiro. A partir de 15 de dezembro ela sobe, porque as janelas passam do fim dos dados: 23,2% no
fim de dezembro, 43,1% no fim de janeiro, e **65,5% duas semanas antes do último dia do banco**,
quando quase ninguém teve tempo de visitar de novo.

Um modelo treinado com essas linhas aprende que o afastamento é três ou quatro vezes mais comum do
que é, e aprende isso sobretudo com as linhas mais novas, as que um retreino noturno pesaria como as
mais relevantes. **A cura é nunca calcular um rótulo cuja janela está aberta**, o que em SQL é mais
uma condição: o corte mais 90 dias precisa cair até o último dia em que os dados estão completos. Ela
pertence ao pipeline que monta o conjunto de treino, não ao notebook de quem modela, porque é uma
propriedade de quando os dados chegaram.

A mesma forma aparece onde quer que um desfecho leve tempo: um empréstimo que fica inadimplente em
até um ano, uma compra devolvida em até trinta dias, uma fraude informada por um estorno semanas
depois. **Todo rótulo tem um tempo de maturação, e um conjunto de treino precisa conhecê-lo.**
