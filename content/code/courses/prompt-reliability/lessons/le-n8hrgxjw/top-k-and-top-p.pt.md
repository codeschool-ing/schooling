---
title: Top-k e top-p
version: 2
---

A temperatura remodela a distribuição inteira. **Top-k e top-p cortam a cauda dela**, e depois
dividem a probabilidade que sobrou entre os candidatos que ficaram. No `next.py`, como na maioria
dos amostradores, os dois agem depois da temperatura:

```
ana@lab:~/triage$ python3 next.py prompts/v6-escaped.txt cases/dev.jsonl t22 --top-k 3
t22, temperature 1, top-k 3, top-p 1, 1000 draws
  'other'      -0.49   64.5%   626  ##########################
  'billing'    -1.50   23.3%   241  #########
  'account'    -2.15   12.2%   133  #####
  ' billing'   -3.84    0.0%     0  
  'delivery'   -5.18    0.0%     0  
  ' Billing'   -5.81    0.0%     0  
  'Billing'    -6.15    0.0%     0  
  'shipping'   -6.30    0.0%     0  
  'payment'    -6.65    0.0%     0  
  'accounts'   -6.68    0.0%     0  
ana@lab:~/triage$ python3 next.py prompts/v6-escaped.txt cases/dev.jsonl t22 --top-p 0.9
t22, temperature 1, top-k off, top-p 0.9, 1000 draws
  'other'      -0.49   64.5%   626  ##########################
  'billing'    -1.50   23.3%   241  #########
  'account'    -2.15   12.2%   133  #####
  ' billing'   -3.84    0.0%     0  
  'delivery'   -5.18    0.0%     0  
  ' Billing'   -5.81    0.0%     0  
  'Billing'    -6.15    0.0%     0  
  'shipping'   -6.30    0.0%     0  
  'payment'    -6.65    0.0%     0  
  'accounts'   -6.68    0.0%     0  
```

**O top-k mantém um número fixo de candidatos**, aqui os três mais prováveis. Eles tinham 96,3% da
probabilidade entre si, e a parte de cada um agora é dividida por isso: `other` vai de 62,1% para
64,5%, e os quatro tokens que reprovariam na verificação de rótulo não ficam com nada.

**O top-p mantém o menor conjunto de primeiros candidatos cujas probabilidades somam pelo menos p.**
Os três primeiros somam 96,3%, o que já chega a 90%, então o top-p 0,9 mantém exatamente as mesmas
três palavras aqui e as duas tabelas são idênticas. Top-k é uma contagem e top-p é uma parte, e a
diferença aparece quando a distribuição muda de forma: k mantém três palavras quer o primeiro tenha
99% quer tenha 40%, enquanto p mantém menos palavras quando um domina e mais quando a probabilidade
está espalhada.

## A ordem das etapas

A `distribution()` as aplica numa ordem fixa: softmax com a temperatura primeiro, depois top-k,
depois top-p, depois os sobreviventes dividem o total. A ordem importa:

```
ana@lab:~/triage$ python3 next.py prompts/v6-escaped.txt cases/dev.jsonl t22 --temperature 1.5 --top-p 0.9
t22, temperature 1.5, top-k off, top-p 0.9, 1000 draws
  'other'      -0.49   51.4%   493  #####################
  'billing'    -1.50   26.1%   259  ##########
  'account'    -2.15   16.9%   186  #######
  ' billing'   -3.84    5.5%    62  ##
  'delivery'   -5.18    0.0%     0  
  ' Billing'   -5.81    0.0%     0  
  'Billing'    -6.15    0.0%     0  
  'shipping'   -6.30    0.0%     0  
  'payment'    -6.65    0.0%     0  
  'accounts'   -6.68    0.0%     0  
```

A temperatura 1,5 a distribuição está mais achatada antes de o top-p olhar para ela. Os três
primeiros agora somam só 87,8%, abaixo de 90%, então o top-p mantém um quarto token, e o quarto é o
`' billing'`, o que tem espaço e reprova na verificação de rótulo: 62 tiragens em mil. **O efeito de
uma configuração depende das configurações aplicadas antes dela.**

Os provedores diferem em quais delas expõem e nos detalhes de como as combinam. As opções do Ollama
incluem `temperature`, `top_k` e `top_p`. A Messages API da Anthropic aceita `temperature`, `top_k`
e `top_p`; a Chat Completions API da OpenAI aceita `temperature` e `top_p` e não tem `top_k`. Leia a
documentação do que você chama, e mude uma configuração de cada vez, pelo motivo que a aula 7 deu.
