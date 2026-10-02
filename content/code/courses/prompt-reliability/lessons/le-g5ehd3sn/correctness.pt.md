---
title: Exatidão, um erro de cada vez
version: 1
---

A taxa de acerto é o primeiro número que todo mundo informa e o que menos diz. Ela conta as respostas
certas e trata toda resposta errada como o mesmo erro. **Uma matriz de confusão mantém cada erro
separado**: uma linha para cada rótulo que uma pessoa deu, uma coluna para cada rótulo que a resposta
deu.

```
ana@lab:~/triage$ pl run prompts/v6-escaped.txt cases/all.jsonl --out runs/v6-all.jsonl
70 calls, prompt fbc4c9b1, written to runs/v6-all.jsonl
ana@lab:~/triage$ pl confusion runs/v6-all.jsonl
expected    billing delivery  returns  account    other    (bad)   recall
billing          13        1        1        0        0        1   0.81
delivery          0       13        0        0        1        0   0.93
returns           0        1       13        0        2        0   0.81
account           1        2        0        9        1        1   0.64
other             1        1        0        0        8        0   0.80
precision      0.87     0.72     0.93     1.00     0.67

accuracy 56/70 = 0.80
```

O `cases/all.jsonl` são as quarenta mensagens de dev e as trinta do holdout juntas. A diagonal são as
respostas certas, 56 de 70. Cada uma das outras células é um erro específico: linha `account`, coluna
`delivery`, 2, quer dizer que duas mensagens de account foram classificadas como delivery. `(bad)`
guarda as respostas sem rótulo utilizável, que a próxima seção conta como formato.

## Recall e precisão

Os dois números nas bordas respondem a perguntas diferentes.

**O recall se lê ao longo de uma linha**: das mensagens que eram de fato account, que fração o prompt
chamou de account? Nove de catorze, 0,64. Cinco mensagens de account foram para outro lugar, e a
equipe de account nunca vai vê-las a menos que alguém as encaminhe.

**A precisão se lê descendo uma coluna**: das mensagens que o prompt chamou de delivery, que fração
era delivery? Treze de dezoito, 0,72. Cinco dos chamados da equipe de entregas são trabalho de outra
pessoa. Account tem a forma oposta, precisão 1,00: quando o prompt diz account ele acerta, e diz
account vezes de menos.

Um prompt consegue subir um abaixando o outro. Chamar tudo de account levaria o recall de account a
1,00 e a precisão dele ao chão. É por isso que os dois são informados juntos, por rótulo.

## Que erros custam mais

As células não custam o mesmo. A urgência mostra isso melhor:

```
ana@lab:~/triage$ grep h03 cases/all.jsonl
{"id": "h03", "message": "My account shows an order I never placed and my card has been charged for it.", "expect": {"category": "billing", "urgency": "high"}}
ana@lab:~/triage$ pl show runs/v6-all.jsonl h03
│ {
│   "category": "billing",
│   "urgency": "normal",
│   "summary": "Their account shows an order they never placed and their card has been charged for it."
│ }
stop: end, tokens in 123, out 41
ana@lab:~/triage$ pl confusion runs/v6-all.jsonl --field urgency
expected        low   normal     high    (bad)   recall
low              17        7        0        0   0.71
normal            1       27        0        2   0.90
high              0        6       10        0   0.62
precision      0.94     0.68     1.00

accuracy 54/70 = 0.77
```

`h03` é um cartão cobrado por um pedido que o cliente nunca fez, o que pode querer dizer que outra
pessoa está usando o cartão dele. A categoria está certa e a urgência é normal, então ela espera na
fila comum. É uma de seis mensagens high classificadas como normal: o recall de high é 0,62. A
precisão de high é 1,00, então nada foi escalado sem motivo.

O acerto de urgência é 54 de 70, e esse número conta `h03` exatamente como as sete mensagens de
urgência baixa classificadas como normal, cujo único custo é serem respondidas um pouco antes do
necessário. **Uma mensagem urgente perdida e um alarme falso são, os dois, uma resposta errada, e não
custam o mesmo.** Decida quanto custa cada tipo de erro antes de ler a matriz, e informe as células
caras pelo nome: *seis high classificadas como normal* é uma frase sobre a qual alguém age, e *0,77*
não é.
