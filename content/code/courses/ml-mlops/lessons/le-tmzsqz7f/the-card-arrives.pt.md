---
title: O boletim chega
version: 1
---

As notas de 28 de fevereiro fecharam em 29 de maio, e os dados da loja agora vão até 30 de junho.
**O boletim que a lição 9 não conseguia ler agora pode ser lido**, e o de 29 de março também, o
último domingo cujos 90 dias já passaram:

```
ana@dev:~/ml$ python report_card.py 2026-02-28
{
  "night": "2026-02-28",
  "model_version": "1",
  "members": 3355,
  "lapsed": 624,
  "roc_auc": 0.779,
  "average_precision": 0.521,
  "lapsed_in_top_300": 191,
  "said": 0.174,
  "happened": 0.186
}
ana@dev:~/ml$ python report_card.py 2026-03-29
{
  "night": "2026-03-29",
  "model_version": "1",
  "members": 3429,
  "lapsed": 720,
  "roc_auc": 0.747,
  "average_precision": 0.496,
  "lapsed_in_top_300": 193,
  "said": 0.177,
  "happened": 0.21
}
```

| | teste, 30 nov 2025 | 28 fev 2026 | 29 mar 2026 |
| --- | --- | --- | --- |
| ROC AUC | 0,793 | 0,779 | 0,747 |
| precisão média | 0,522 | 0,521 | 0,496 |
| afastados entre os 300 primeiros | 190 | 191 | 193 |
| dito | 0,177 | 0,174 | 0,177 |
| acontecido | 0,169 | 0,186 | 0,210 |

**O modelo piorou, e piorou de um jeito específico.** A ordenação escorregou: a AUC caiu de 0,793
para 0,747. Mas a mudança maior está nas duas últimas linhas. O modelo continuou dizendo que uns
17,5% dos membros se afastariam, e a fração que de fato se afastou subiu de 16,9% para 21,0%. **As
probabilidades dele deixaram de estar calibradas**, e a conta de limiar da lição 4, que transforma
uma probabilidade num cupom que vale mandar, depende delas.

Os 300 primeiros aguentaram, 193 contra 190, porque os mais prováveis de se afastar continuam sendo
as pessoas sem visita recente, e essa relação não mudou. O que mudou está em algum lugar que o topo
da lista não alcança.

**As entradas não conseguem dizer o que mudou; os desfechos conseguem, divididos por grupo.** Um
número para 3.429 membros faz a média de um grupo que mudou com os muitos que não mudaram.
