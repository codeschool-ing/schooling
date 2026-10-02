---
title: O diagrama de confiabilidade
version: 1
---

Uma confiança declarada de 0,85 faz uma afirmação que dá para conferir: das respostas declaradas
em cerca de 0,85, cerca de 85% devem estar certas. **Calibração se confere em muitas respostas,
nunca em uma**, porque uma resposta isolada está certa ou errada, e nenhum dos dois resultados
desmente um 0,85.

Então agrupe as respostas pelo que declararam e conte:

```
ana@lab:~/triage$ pl calibrate runs/v9.jsonl
stated         n  mean said  accuracy
0.50-0.60    0          -         -
0.60-0.70    2       0.69      0.00
0.70-0.80    7       0.73      0.29
0.80-0.90   27       0.85      0.81
0.90-1.00   34       0.96      0.94

replies 70, right 56, mean stated confidence 0.89
ECE 0.088   Brier 0.139
```

O `pl calibrate` separa as respostas em faixas pela confiança declarada, aqui cinco faixas de
largura 0,1 a partir de 0,5. Para cada faixa, imprime quantas respostas caíram nela, a média da
confiança declarada e a fração que estava certa. A faixa de 0,5 a 0,6 está vazia, já que o
substituto nunca declara menos de 0,62.

Leia faixa por faixa. As 34 respostas declaradas acima de 0,9 disseram 0,96 em média e acertaram
0,94 das vezes: perto. As 27 entre 0,8 e 0,9 disseram 0,85 e acertaram 0,81. As sete entre 0,7 e
0,8 disseram 0,73 e acertaram **0,29**, e as duas abaixo de 0,7 disseram 0,69 e não acertaram
nenhuma vez. No total, a média da confiança declarada é 0,89 e a acurácia, 56 de 70, 0,80.

## A imagem

A tabela tem dois números por faixa, e o formato é o argumento, então esta é a figura pela qual o
assunto é conhecido. **Um diagrama de confiabilidade** põe a confiança declarada num eixo e a
acurácia no outro. Os pontos de um modelo perfeitamente calibrado ficam na diagonal, onde dizer 0,85
significa acertar 85% das vezes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" aria-label=\"Diagrama de confiabilidade de 70 respostas. Confiança declarada no eixo horizontal, de 0,5 a 1, acurácia no eixo vertical, de 0 a 1, e uma diagonal para a calibração perfeita. Quatro faixas: 2 respostas disseram 0,69 e acertaram 0,00 das vezes; 7 disseram 0,73 e acertaram 0,29; 27 disseram 0,85 e acertaram 0,81; 34 disseram 0,96 e acertaram 0,94. Todo ponto fica abaixo da diagonal.\"><path d=\"M110 290 L450 290\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M110 290 L110 40\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M110.0 290 L110.0 294\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"110.0\" y=\"305\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0,5</text><path d=\"M178.0 290 L178.0 294\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"178.0\" y=\"305\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0,6</text><path d=\"M245.99999999999997 290 L245.99999999999997 294\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"245.99999999999997\" y=\"305\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0,7</text><path d=\"M314.0 290 L314.0 294\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"314.0\" y=\"305\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0,8</text><path d=\"M382.0 290 L382.0 294\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"382.0\" y=\"305\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0,9</text><path d=\"M450.0 290 L450.0 294\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"450.0\" y=\"305\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1,0</text><path d=\"M106 290 L110 290\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"102\" y=\"290\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0,0</text><path d=\"M106 165.0 L110 165.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"102\" y=\"165.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0,5</text><path d=\"M106 40.0 L110 40.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"102\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1,0</text><text x=\"280.0\" y=\"324\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">confiança declarada</text><text x=\"70\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">acurácia</text><path d=\"M110.0 165.0 L450.0 40.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 4\"></path><path d=\"M239.19999999999996 117.5 L239.19999999999996 290.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"2 3\"></path><circle cx=\"239.19999999999996\" cy=\"290.0\" r=\"4.3\" fill=\"var(--phosphor)\"></circle><path d=\"M266.4 107.5 L266.4 217.5\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"2 3\"></path><circle cx=\"266.4\" cy=\"217.5\" r=\"5.4\" fill=\"var(--phosphor)\"></circle><path d=\"M348.0 77.5 L348.0 87.5\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"2 3\"></path><circle cx=\"348.0\" cy=\"87.5\" r=\"7.7\" fill=\"var(--phosphor)\"></circle><path d=\"M422.79999999999995 50.0 L422.79999999999995 55.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"2 3\"></path><circle cx=\"422.79999999999995\" cy=\"55.0\" r=\"8.2\" fill=\"var(--phosphor)\"></circle><text x=\"253.19999999999996\" y=\"276.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">n=2  0,69 → 0,00</text><text x=\"284.4\" y=\"217.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">n=7  0,73 → 0,29</text><text x=\"366.0\" y=\"107.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">n=27  0,85 → 0,81</text><text x=\"438.79999999999995\" y=\"77.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">n=34  0,96 → 0,94</text><path d=\"M500 200 L530 200\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"540\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">calibração perfeita</text><circle cx=\"515\" cy=\"230\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"540\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">uma faixa de respostas</text></svg>", "caption": "Toda faixa fica abaixo da diagonal: o substituto disse mais do que entregou. As duas faixas grandes ficam perto da linha; a distância é maior onde a evidência era fraca."}
```

Todo ponto fica abaixo da diagonal: em toda faixa o substituto disse mais do que entregou. Isso é
**excesso de confiança**, e ele não está distribuído por igual. As duas faixas grandes ficam perto
da linha, e o estrago está nas faixas pequenas, onde a evidência do substituto era fraca e ele ainda
assim disse 0,7.

Dois cuidados ao ler um diagrama assim. Uma faixa de duas respostas não diz quase nada, então um
ponto precisa do seu `n` ao lado. E um diagrama feito com setenta respostas é um esboço: setenta é
uma amostra pequena, e uma faixa de sete é menor ainda.
