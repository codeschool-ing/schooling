---
title: Um limiar é uma troca
version: 2
---

A aula 10 mediu os veredictos do juiz contra as pessoas e os achou fracos. Um veredicto, porém, é um
limiar sobre um julgamento, e um detector tem um ajuste. A pergunta é justa: **em que limiar este juiz
seria um detector útil?**

O veredicto de um juiz é aprovado ou reprovado, mas o `judge.py` também pede uma **nota** de 0 a 1, e
uma nota vira um detector em qualquer limiar: marcar toda resposta com nota abaixo dele. O `sweep.py`
dá nota às quarenta e oito respostas da aula 10 e conta, em seis limiares, quantas marcaria e quantas
dessas as pessoas reprovaram:

```python
"""sweep.py: the judge's relevance score used to flag the replies people failed, at several thresholds,
against the agreed labels of lesson 10. A flag is a score below the threshold."""
import json

import judge
import telemetry

telemetry.setup("judge-spans.jsonl", service="judge")
agreed = {(r["case"], r["release"]): r["relevance-v2"]["agreed"] for r in map(json.loads, open("data/labels.jsonl"))}
scored = []
for run in ("old", "new"):
    for r in map(json.loads, open(f"runs/{run}.jsonl")):
        score = judge.grade("relevance", r["question"], r["reply"], r["sources"])["score"]
        scored.append((score, agreed[r["id"], r["release"]] == "fail"))
bad = sum(b for _, b in scored)
print(f"{len(scored)} replies scored by the judge, {bad} of them failed by the agreed labels")
print("scores given:", sorted(set(s for s, _ in scored)))
print("threshold  flagged  caught  precision  recall")
for t in (0.1, 0.3, 0.5, 0.7, 0.9, 1.0):
    flagged = [b for s, b in scored if s < t]
    caught = sum(flagged)
    precision = f"{caught / len(flagged):9.0%}" if flagged else "        -"
    print(f"     {t:.2f}  {len(flagged):7}  {caught:6}  {precision}  {caught / bad:6.0%}")
```

```
ana@dev:~/obs$ python sweep.py
48 replies scored by the judge, 7 of them failed by the agreed labels
scores given: [0, 0.5, 0.6, 0.67, 0.8, 0.9]
threshold  flagged  caught  precision  recall
     0.10       15       4        27%     57%
     0.30       15       4        27%     57%
     0.50       15       4        27%     57%
     0.70       29       4        14%     57%
     0.90       47       7        15%    100%
     1.00       48       7        15%    100%
```

**Não há limiar em que este juiz seja um detector que valha a pena.** Leia a primeira linha: o juiz usou
só seis notas para quarenta e oito respostas, e quinze delas levaram 0.

- **Até 0,50 as mesmas quinze são marcadas**, as respostas com nota 0, e quatro são ruins. As outras
  onze são as dez recusas certas e uma resposta certa. Precisão de 27%, revocação de 57%.
- **Em 0,70 mais catorze são marcadas**, todas boas. A precisão cai para 14% e a revocação não se mexe.
- **Em 0,90 tudo menos uma resposta é marcado**, e a revocação chega a 100% do jeito que sempre pode,
  marcando o lote inteiro.

E as notas não ficam paradas. Rode o `sweep.py` duas vezes e o conjunto de notas muda: numa segunda
execução o mesmo juiz deu 0,2 a uma resposta em que antes tinha dado nota mais alta, e deu 0,8 a três
recusas chamando cada uma de reprovada na mesma resposta. **Uma nota que discorda do próprio veredicto
não é uma medida**, e um limiar traçado sobre ela não divide nada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Precisão e revocação da nota de relevância do juiz como detector das respostas que as pessoas reprovaram, em limiares de 0,1 a 1,0. A revocação é 57% até 0,7 e 100% a partir de 0,9, quando quase toda resposta é marcada. A precisão é 27% até 0,5 e cai para 14% e 15% depois. As duas linhas nunca trocam uma pela outra.\"><path d=\"M90 210 L660 210\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M90 210 L90 40\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M85 210 L90 210\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"80\" y=\"210\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0%</text><path d=\"M85 125 L90 125\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"80\" y=\"125\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">50%</text><path d=\"M85 40 L90 40\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"80\" y=\"40\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100%</text><path d=\"M90 210 L90 215\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"90\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,1</text><path d=\"M216.67 210 L216.67 215\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"216.67\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,3</text><path d=\"M343.33 210 L343.33 215\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"343.33\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,5</text><path d=\"M470 210 L470 215\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"470\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,7</text><path d=\"M596.67 210 L596.67 215\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"596.67\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,9</text><path d=\"M660 210 L660 215\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"660\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1,0</text><text x=\"375\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">limiar: uma resposta com nota abaixo dele é marcada</text><path d=\"M90 113.1 L216.67 113.1 L343.33 113.1 L470 113.1 L596.67 40 L660 40\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"90\" cy=\"113.1\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"216.67\" cy=\"113.1\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"343.33\" cy=\"113.1\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"470\" cy=\"113.1\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"596.67\" cy=\"40\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"660\" cy=\"40\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><path d=\"M90 164.1 L216.67 164.1 L343.33 164.1 L470 186.2 L596.67 184.5 L660 184.5\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"90\" cy=\"164.1\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"216.67\" cy=\"164.1\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"343.33\" cy=\"164.1\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"470\" cy=\"186.2\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"596.67\" cy=\"184.5\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"660\" cy=\"184.5\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"100\" cy=\"16\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\"></circle><text x=\"110\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">precisão</text><circle cx=\"220\" cy=\"16\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"230\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">revocação</text></svg>", "caption": "Um detector que vale ajustar mostra as duas linhas se cruzando conforme o limiar se move. Estas ficam paradas e depois saltam juntas, porque as notas não ordenam as respostas."}
```

Essa é a primeira coisa a conferir antes de escolher um limiar: **que a nota ordene as respostas.** Um
detector só ganha uma troca entre precisão e revocação quando as respostas ruins tendem a ter nota mais
baixa que as boas, e mover o limiar move os dois números um contra o outro. Aqui as recusas que o juiz
não sabe julgar ficam em 0 junto com as ruins, e todo o resto é ruído entre 0,5 e 0,9. Compare com a
regra da aula 10, que decide as recusas pelo gabarito: nas recusas a precisão e a revocação dela são as
duas 100%, porque ela lê o único fato que as decide.

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
