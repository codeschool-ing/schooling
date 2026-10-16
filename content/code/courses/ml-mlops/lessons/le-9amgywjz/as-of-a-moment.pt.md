---
title: Em relação a um momento, e nunca depois
version: 1
---

**A junção no ponto do tempo faz ao armazenamento uma pergunta com uma data dentro**: para este
membro, neste momento, o que se sabia? Ela pega a fotografia mais nova até o momento, e nada depois
dele, por mais dados novos que o armazenamento tenha. Salve isto como `asof.py`:

```python
"""asof.py: one member, asked about on three different days."""
import pandas as pd

from featurestore import historical

ask = pd.DataFrame({"member_id": [2, 2, 2], "at": ["2025-11-27", "2025-11-30", "2026-02-28"]})
print(historical(ask)[["member_id", "at", "as_of", "recency_days", "visits_180d"]]
      .to_string(index=False))
```

```
ana@dev:~/ml$ python asof.py
 member_id         at      as_of  recency_days  visits_180d
         2 2025-11-27 2025-11-23          15.0            3
         2 2025-11-30 2025-11-30           0.0            4
         2 2026-02-28 2026-02-28           3.0            4
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l06-asof\" aria-label=\"Uma linha do tempo de fotografias do membro 2: domingos 16, 23 e 30 de novembro de 2025, e sábado 28 de fevereiro de 2026. Uma pergunta na quinta, 27 de novembro, é respondida pela fotografia de 23 de novembro; uma em 30 de novembro, pela daquele dia; uma em 28 de fevereiro, pela daquela noite. Nenhuma resposta vem de uma fotografia posterior à pergunta.\"><defs><marker id=\"st-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><path d=\"M40.0 150.0 L46.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M114.0 150.0 L196.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M264.0 150.0 L346.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M414.0 150.0 L606.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M674.0 150.0 L690.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"510.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" fill=\"var(--paper-dim)\">…</text><text x=\"40.0\" y=\"186.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">fotografias</text><rect x=\"46.0\" y=\"138.0\" width=\"68.0\" height=\"24.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">16 nov</text><rect x=\"196.0\" y=\"138.0\" width=\"68.0\" height=\"24.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"230.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">23 nov</text><rect x=\"346.0\" y=\"138.0\" width=\"68.0\" height=\"24.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"380.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">30 nov</text><rect x=\"606.0\" y=\"138.0\" width=\"68.0\" height=\"24.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">28 fev</text><circle cx=\"330.0\" cy=\"40.0\" r=\"4\" fill=\"var(--amber)\"></circle><text x=\"322.0\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">pergunta em 27 nov</text><path d=\"M330 45 L230 136\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#st-ah-amber)\"></path><circle cx=\"390.0\" cy=\"84.0\" r=\"4\" fill=\"var(--amber)\"></circle><text x=\"398.0\" y=\"84.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">pergunta em 30 nov</text><path d=\"M390 89 L380 136\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#st-ah-amber)\"></path><circle cx=\"640.0\" cy=\"60.0\" r=\"4\" fill=\"var(--amber)\"></circle><text x=\"632.0\" y=\"60.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">pergunta em 28 fev</text><path d=\"M640 65 L640 136\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#st-ah-amber)\"></path></svg>", "caption": "Cada pergunta é respondida pela fotografia mais nova até ela. Linhas mais novas existem no armazenamento o tempo todo, e a junção nunca chega a elas."}
```

Três perguntas sobre o mesmo membro:

- **quinta, 27 de novembro**, cai entre fotografias, então a resposta é a do domingo, 23 de
  novembro: 15 dias desde a última visita, 3 visitas. Quatro dias de atraso, dentro do tempo de vida
  de sete dias, então ela é servida;
- **domingo, 30 de novembro**, tem uma fotografia própria: recência 0, porque o membro 2 comprou algo
  naquele mesmo dia, e 4 visitas;
- **sábado, 28 de fevereiro**, é a fotografia de hoje: 3 dias, 4 visitas.

**O armazenamento tinha as três linhas o tempo todo.** O que ele não fez foi devolver a linha de
fevereiro a uma pergunta sobre novembro, que é exatamente o que a tabela de resumo fazia. O atraso na
quinta é o preço das fotografias semanais, e é um preço conhecido e limitado: no máximo seis dias,
escrito como `MAX_AGE`. Um vazamento não tem limite nem nome.
