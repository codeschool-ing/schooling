---
title: Temperatura
version: 2
---

**A temperatura divide cada pontuação antes do softmax.** Abaixo de 1 ela estica as distâncias
entre as pontuações, então o primeiro candidato fica com mais probabilidade. Acima de 1 ela as
encolhe, então a cauda fica com mais. Aqui está o `t22` a 0,2 e a 1,5:

```
ana@lab:~/triage$ python3 next.py prompts/v6-escaped.txt cases/dev.jsonl t22 --temperature 0.2
t22, temperature 0.2, top-k off, top-p 1, 1000 draws
  'other'      -0.49   99.4%   995  ########################################
  'billing'    -1.50    0.6%     5  
  'account'    -2.15    0.0%     0  
  ' billing'   -3.84    0.0%     0  
  'delivery'   -5.18    0.0%     0  
  ' Billing'   -5.81    0.0%     0  
  'Billing'    -6.15    0.0%     0  
  'shipping'   -6.30    0.0%     0  
  'payment'    -6.65    0.0%     0  
  'accounts'   -6.68    0.0%     0  
ana@lab:~/triage$ python3 next.py prompts/v6-escaped.txt cases/dev.jsonl t22 --temperature 1.5
t22, temperature 1.5, top-k off, top-p 1, 1000 draws
  'other'      -0.49   47.8%   449  ###################
  'billing'    -1.50   24.3%   253  ##########
  'account'    -2.15   15.7%   165  ######
  ' billing'   -3.84    5.1%    61  ##
  'delivery'   -5.18    2.1%    14  #
  ' Billing'   -5.81    1.4%    11  #
  'Billing'    -6.15    1.1%    19  
  'shipping'   -6.30    1.0%    11  
  'payment'    -6.65    0.8%    10  
  'accounts'   -6.68    0.8%     7  
```

A 0,2 a distância de um ponto entre `other` e `billing` vira uma distância de cinco pontos, e `other`
fica com 99,4%: cinco tiragens em mil dizem billing. A 1,5 a mesma distância encolhe para dois terços
de ponto, e `other` cai para 47,8%. **Achatar também dá chances à cauda**: o `'Billing'` com
maiúscula e o `' billing'` com espaço, que reprovam na verificação de rótulo, foram tirados 19 e 61
vezes em mil, e `'shipping'` e `'payment'`, que nem são rótulos, 11 e 10.

Temperatura 0 não pode ser calculada assim, já que nada se divide por zero, então ela é definida
como o limite: pegar sempre o primeiro candidato, sem tiragem nenhuma. É o que o `pl run` pede por
padrão, e é por isso que as execuções dele se repetem.

**O número é relativo às pontuações que ele divide.** No `t22` as duas primeiras pontuações estão a
um ponto de distância, então uma temperatura de 1 deixa a billing com mais de uma chance em cinco. No
`t08`, onde a distância é de quase sete pontos, a mesma temperatura quase não muda nada. Em outro
modelo a mesma configuração não promete a mesma quantidade, e o jeito de saber é medir na sua própria
tarefa, como faz a última seção desta aula.
