---
title: Um limiar é uma troca
version: 1
---

O judge-1 responde relevância com uma nota além do veredicto, e o veredicto é a nota contra um limiar
de 0,40 que o laboratório escolheu. A aula 10 viu que em 0,40 ele nunca marca nada que as pessoas
chamam de irrelevante. Mas o limiar é um ajuste, e todo juiz que devolve uma nota tem um, então a
pergunta é justa: **em que limiar ele seria um detector útil?**

O `sweep.py` dá nota às 36 respostas que o juiz lê (as recusas são aprovadas por regra, como a aula 10
decidiu) e conta, em seis limiares, quantas ele marcaria e quantas dessas as pessoas reprovaram:

```python
"""sweep.py: judge-1's relevance score used to flag irrelevant replies, at six thresholds,
against the agreed labels of lesson 10. A flag is a score below the threshold."""
import json

import checks
import judge
import telemetry

telemetry.setup("judge-spans.jsonl", service="judge")
agreed = {(r["case"], r["release"]): r["label"] for r in map(json.loads, open("data/labels.jsonl"))
          if r["rubric"] == "relevance-v2" and r["rater"] == "agreed"}
scored = []
for run in ("old", "new"):
    for r in map(json.loads, open(f"runs/{run}.jsonl")):
        if checks.is_refusal(r["reply"]):
            continue   # passed by rule, as in lesson 10
        score = judge.grade("relevance", r["question"], r["reply"], r["sources"])["score"]
        scored.append((score, agreed[r["id"], r["release"]] == "fail"))
bad = sum(b for _, b in scored)
print(f"{len(scored)} replies read by the judge, {bad} of them irrelevant by the agreed labels")
print("threshold  flagged  caught  precision  recall")
for t in (0.40, 0.55, 0.60, 0.65, 0.70, 0.75):
    flagged = [b for s, b in scored if s < t]
    caught = sum(flagged)
    precision = f"{caught / len(flagged):9.0%}" if flagged else "        -"
    print(f"     {t:.2f}  {len(flagged):7}  {caught:6}  {precision}  {caught / bad:6.0%}")
```

```
ana@lab:~/obs$ python sweep.py
36 replies read by the judge, 7 of them irrelevant by the agreed labels
threshold  flagged  caught  precision  recall
     0.40        0       0          -      0%
     0.55        1       1       100%     14%
     0.60        6       2        33%     29%
     0.65        9       4        44%     57%
     0.70       13       7        54%    100%
     0.75       19       7        37%    100%
```

Descer na tabela é subir o limiar, e as duas colunas se mexem:

- **Em 0,40 nada é marcado.** A precisão não tem sobre o que ser, e a revocação é zero: o juiz da
  aula 10.
- **Em 0,55 uma resposta é marcada, e ela é ruim.** Precisão perfeita, e seis das sete respostas
  ruins passam.
- **Em 0,70 as sete são pegas**, entre treze marcadas: revocação de 100%, precisão de 54%. Seis
  respostas que as pessoas aprovaram são marcadas junto.
- **Em 0,75 as marcas a mais são todas alarmes falsos.** A revocação não tem como subir, e a precisão
  cai.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Precisão e revocação da nota de relevância do judge-1 como detector, em limiares de 0,40 a 0,75. A revocação sobe de 0% em 0,40 para 100% em 0,70 e fica ali. A precisão não é definida em 0,40, é 100% em 0,55 com um único sinal, depois 33%, 44%, 54% em 0,70, e cai para 37% em 0,75.\"><path d=\"M90 210 L660 210\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M90 210 L90 40\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M85 210 L90 210\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"80\" y=\"210\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0%</text><path d=\"M85 125 L90 125\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"80\" y=\"125\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">50%</text><path d=\"M85 40 L90 40\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"80\" y=\"40\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100%</text><path d=\"M90 210 L90 215\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"90\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,40</text><path d=\"M334.286 210 L334.286 215\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"334.286\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,55</text><path d=\"M415.714 210 L415.714 215\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"415.714\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,60</text><path d=\"M497.143 210 L497.143 215\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"497.143\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,65</text><path d=\"M578.571 210 L578.571 215\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"578.571\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,70</text><path d=\"M660 210 L660 215\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"660\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,75</text><text x=\"375\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">limiar: uma resposta com nota abaixo dele é marcada</text><path d=\"M90 210 L334.286 186.2 L415.714 160.7 L497.143 113.1 L578.571 40 L660 40\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M334.286 40 L415.714 153.9 L497.143 135.2 L578.571 118.2 L660 147.1\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"90\" cy=\"210\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"334.286\" cy=\"186.2\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"415.714\" cy=\"160.7\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"497.143\" cy=\"113.1\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"578.571\" cy=\"40\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"660\" cy=\"40\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"334.286\" cy=\"40\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"415.714\" cy=\"153.9\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"497.143\" cy=\"135.2\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"578.571\" cy=\"118.2\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"660\" cy=\"147.1\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"100\" cy=\"16\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\"></circle><text x=\"110\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">precisão</text><circle cx=\"220\" cy=\"16\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"230\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">revocação</text></svg>", "caption": "Cada passo para a direita pega mais respostas ruins e marca mais respostas boas. Em 0,40, o ajuste do laboratório, nada é marcado."}
```

0,70 parece o melhor nesta tabela, e seria um erro adotá-lo por esta tabela. **Sete respostas ruins são
poucas demais para escolher um limiar.** As notas das ruins (0,54 a 0,68) se sobrepõem às das boas
(0,55 a 0,90) porque o judge-1 mede palavras em comum. Um limiar ajustado em sessenta respostas para
pegar exatamente estas sete está encaixado nelas. Uma equipe faz isso com algumas centenas de respostas
rotuladas, e confere o limiar escolhido em rótulos que não usou para ajustá-lo, que é a separação entre
um conjunto de desenvolvimento e um reservado, assunto da aula 13.

## Para que lado errar

O limiar é escolhido pelo **custo de cada tipo de erro**, e isso depende do que o detector aciona:

- **Um alerta que acorda alguém** precisa de precisão. Um detector que erra metade das vezes em que
  dispara é silenciado em uma semana, e aí não pega mais nada. A aula 16 define alertas com isso em
  mente.
- **Um portão que bloqueia uma versão** precisa de revocação. Uma resposta ruim que passa chega aos
  clientes; um alarme falso custa a alguém o tempo de ler as respostas marcadas e liberar. A aula 15
  monta o portão.
- **Uma fila para pessoas lerem** fica no meio. O tamanho dela é a tarde de alguém, então a precisão
  decide quanto dela é desperdiçado, e a revocação decide quanto ela perde.

Então o mesmo juiz pode rodar em dois limiares para dois propósitos, e isso não é incoerência. Cada
limiar fica escrito ao lado do propósito que serve, com a precisão e a revocação que tinha nos rótulos
no dia em que foi escolhido.
