---
title: O diagrama de confiabilidade
version: 2
---

Uma confiança declarada de 0,8 faz uma afirmação que pode ser conferida: de todas as respostas
declaradas com 0,8, cerca de 80% deveriam estar certas. **Calibração se confere em muitas respostas,
nunca numa só**, porque uma resposta isolada está certa ou errada, e nenhum dos dois resultados
refuta um 0,8.

Então agrupe as respostas pelo que declararam e conte. Este programa faz isso, e com `--thresholds`
também imprime a troca que a última seção desta aula usa. Salve-o como `calibrate.py`:

```python
"""calibrate: does the confidence a reply states match how often its category
is right? Replies are grouped by what they stated, and each group is counted."""
import sys

from pl import parse, read_jsonl

rows = read_jsonl(sys.argv[1])
expect = {c["id"]: c["expect"] for c in read_jsonl(rows[0]["cases"])}
pairs, missing = [], 0
for r in rows:
    obj = parse(r["text"]) or {}
    conf = obj.get("confidence")
    if isinstance(conf, bool) or not isinstance(conf, (int, float)) or not 0 <= conf <= 1:
        missing += 1
        continue
    pairs.append((float(conf), obj.get("category") == expect[r["case"]]["category"]))

edges = [0.0, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]
print("stated         n  mean said  accuracy")
ece = 0.0
for lo, hi in zip(edges, edges[1:]):
    group = [(c, ok) for c, ok in pairs if lo <= c < hi or (hi == 1.0 and c == 1.0)]
    if not group:
        print("%.2f-%.2f %5d %10s %9s" % (lo, hi, 0, "-", "-"))
        continue
    said = sum(c for c, _ in group) / len(group)
    right = sum(ok for _, ok in group) / len(group)
    ece += len(group) / len(pairs) * abs(said - right)
    print("%.2f-%.2f %5d %10.2f %9.2f" % (lo, hi, len(group), said, right))
brier = sum((c - ok) ** 2 for c, ok in pairs) / len(pairs)
print("\nreplies %d, %d with no usable confidence; right %d of %d, mean stated %.2f"
      % (len(rows), missing, sum(ok for _, ok in pairs), len(pairs),
         sum(c for c, _ in pairs) / len(pairs)))
print("ECE %.3f   Brier %.3f" % (ece, brier))
if "--thresholds" in sys.argv:
    print("\nanswer if      answered  accuracy")
    for t in (0.0, 0.8, 0.85, 0.9, 0.95):
        kept = [ok for c, ok in pairs if c >= t]
        acc = "%.2f" % (sum(kept) / len(kept)) if kept else "-"
        print("conf >= %.2f %8d %9s" % (t, len(kept), acc))
```

Uma confiança ausente, que não é número ou que fica fora de 0 a 1 é contada e deixada de fora, nunca
adivinhada. Rode-o sobre as setenta respostas:

```
ana@lab:~/triage$ python3 calibrate.py runs/v9.jsonl
stated         n  mean said  accuracy
0.00-0.50     1       0.00      1.00
0.50-0.60     0          -         -
0.60-0.70     0          -         -
0.70-0.80     0          -         -
0.80-0.90    46       0.80      0.72
0.90-1.00    23       0.90      0.78

replies 70, 0 with no usable confidence; right 52 of 70, mean stated 0.82
ECE 0.108   Brier 0.212
```

O `calibrate.py` separa as respostas em faixas pela confiança declarada: uma faixa abaixo de 0,5 e
cinco de largura 0,1 acima dela. Para cada faixa ele imprime quantas respostas caíram nela, a média
da confiança declarada e a fração que acertou. Só três faixas têm alguma coisa, porque o modelo usou
quatro valores.

Leia faixa por faixa. As 46 respostas que disseram 0,8 acertaram 0,72 das vezes. As 23 que disseram
0,9, ou 0,95 uma vez, acertaram 0,78. A que disse 0,0 acertou. No total, a média da confiança
declarada é 0,82 e a acurácia 52 de 70, 0,74.

## A figura

A tabela tem dois números por faixa, e o formato é o argumento, então esta é a figura pela qual o
tema é conhecido. **Um diagrama de confiabilidade** põe a confiança declarada num eixo e a acurácia
no outro. Os pontos de um modelo perfeitamente calibrado ficam sobre a diagonal, onde dizer 0,8
significa acertar 80% das vezes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" aria-label=\"Diagrama de confiabilidade de 70 respostas. Confiança declarada no eixo horizontal de 0 a 1, acurácia no eixo vertical de 0 a 1, e uma diagonal para a calibração perfeita. Três grupos: 1 resposta disse 0,00 e acertou; 46 disseram 0,80 e acertaram 0,72 das vezes; 23 disseram 0,90 e acertaram 0,78. Os dois grupos grandes ficam abaixo da diagonal.\"><path d=\"M110 290 L450 290\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M110 290 L110 40\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M110.0 290 L110.0 294\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"110.0\" y=\"305\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0,0</text><path d=\"M178.0 290 L178.0 294\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"178.0\" y=\"305\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0,2</text><path d=\"M246.0 290 L246.0 294\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"246.0\" y=\"305\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0,4</text><path d=\"M314.0 290 L314.0 294\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"314.0\" y=\"305\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0,6</text><path d=\"M382.0 290 L382.0 294\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"382.0\" y=\"305\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0,8</text><path d=\"M450.0 290 L450.0 294\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"450.0\" y=\"305\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1,0</text><path d=\"M106 290.0 L110 290.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"102\" y=\"290.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0,0</text><path d=\"M106 165.0 L110 165.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"102\" y=\"165.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0,5</text><path d=\"M106 40.0 L110 40.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"102\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1,0</text><text x=\"280\" y=\"324\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">confiança declarada</text><text x=\"70\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">acurácia</text><path d=\"M110 290 L450 40\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 4\"></path><path d=\"M110.0 290.0 L110.0 40.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"2 3\"></path><circle cx=\"110.0\" cy=\"40.0\" r=\"4.2\" fill=\"var(--phosphor)\"></circle><text x=\"124\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">n=1  0,00 → 1,00</text><path d=\"M382.0 90.0 L382.0 110.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"2 3\"></path><circle cx=\"382.0\" cy=\"110.0\" r=\"9.0\" fill=\"var(--phosphor)\"></circle><text x=\"394\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">n=46  0,80 → 0,72</text><path d=\"M416.0 65.0 L416.0 95.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"2 3\"></path><circle cx=\"416.0\" cy=\"95.0\" r=\"7.4\" fill=\"var(--phosphor)\"></circle><text x=\"432\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">n=23  0,90 → 0,78</text><path d=\"M560 200 L590 200\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"600\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">calibração perfeita</text><circle cx=\"575\" cy=\"230\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"600\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um grupo de respostas</text></svg>", "caption": "Quase toda resposta disse 0,8 ou 0,9, os números que os exemplos mostravam. Os dois grupos grandes ficam abaixo da diagonal, e perto um do outro: o número declarado mal separa um grupo do outro."}
```

Os dois grupos grandes ficam abaixo da diagonal: nos dois, o modelo disse mais do que entregou. Isso
é **excesso de confiança**, e aqui ele é leve, oito e doze pontos. O mais revelador é o quanto os
dois grupos estão perto um do outro. Respostas declaradas com 0,9 acertaram 0,78 das vezes e as
declaradas com 0,8 acertaram 0,72. **Uma confiança é útil quando separa as respostas certas das que
não estão**, e esta mal separa.

Dois cuidados ao ler um diagrama. Uma faixa de uma resposta não diz nada, então um ponto precisa do
seu `n` ao lado. E um diagrama feito com setenta respostas é um esboço: setenta é uma amostra
pequena, e a diferença entre 0,72 e 0,78 está bem dentro do que outras setenta mensagens poderiam
mover.
