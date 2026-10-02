---
title: Top-k e top-p
version: 1
---

A temperatura muda a forma da distribuição inteira. **Top-k e top-p cortam a cauda dela**, e depois
dividem a probabilidade que sobrou entre as candidatas que ficaram. Os dois agem depois da
temperatura:

```
ana@lab:~/triage$ pl sample --top-k 3
Your parcel is ___   temperature 1, top-k 3, top-p 1, 1000 draws
  on         52.4%    570  #####################
  delayed    31.8%    277  #############
  here       15.8%    153  ######
  lost        0.0%      0  
  ready       0.0%      0  
  wet         0.0%      0  
  singing     0.0%      0  
  purple      0.0%      0  
ana@lab:~/triage$ pl sample --top-p 0.9
Your parcel is ___   temperature 1, top-k off, top-p 0.9, 1000 draws
  on         48.6%    523  ###################
  delayed    29.5%    259  ############
  here       14.6%    139  ######
  lost        7.3%     79  ###
  ready       0.0%      0  
  wet         0.0%      0  
  singing     0.0%      0  
  purple      0.0%      0  
```

**O top-k mantém um número fixo de candidatas**, aqui as três mais prováveis. Elas tinham 86.1% da
probabilidade entre si, e a parte de cada uma agora é dividida por isso: `on` vai de 45.1% para
52.4%.

**O top-p mantém o menor conjunto de candidatas do topo cujas probabilidades somam pelo menos p.** As
três primeiras somam 86.1%, abaixo de 90%, então `lost` entra e o total chega a 92.8%. Ficam quatro
palavras. Top-k é uma contagem e top-p é uma fração. A diferença aparece quando a distribuição
muda de forma: k mantém três palavras quer a do topo tenha 99% ou 40%, enquanto p mantém menos
palavras quando uma domina e mais quando a probabilidade está espalhada.

## A ordem das etapas

O amostrador do laboratório aplica as etapas numa ordem fixa, e o código-fonte diz qual:

```
ana@lab:~/triage$ sed -n '/^def distribution/,/return \[/p' promptlab/sample.py
def distribution(scores, temperature=1.0, top_k=0, top_p=1.0):
    """The probability of each candidate after temperature, then top-k, then
    top-p. A candidate cut by k or p gets exactly zero."""
    probs = softmax(scores, temperature)
    order = sorted(range(len(probs)), key=lambda i: -probs[i])
    keep = set(order[:top_k] if top_k else order)
    if top_p < 1.0:
        kept, acc = set(), 0.0
        for i in order:
            if i not in keep:
                continue
            kept.add(i)
            acc += probs[i]
            if acc >= top_p:
                break
        keep = kept
    total = sum(probs[i] for i in keep)
    return [probs[i] / total if i in keep else 0.0 for i in range(len(probs))]
ana@lab:~/triage$ pl sample --temperature 1.5 --top-p 0.9
Your parcel is ___   temperature 1.5, top-k off, top-p 0.9, 1000 draws
  on         37.1%    405  ###############
  delayed    26.6%    255  ###########
  here       16.7%    140  #######
  lost       10.5%    101  ####
  ready       9.2%     99  ####
  wet         0.0%      0  
  singing     0.0%      0  
  purple      0.0%      0  
```

Primeiro o softmax com a temperatura, depois o top-k, depois o top-p, e então as sobreviventes são
renormalizadas. A ordem importa: com temperatura 1.5 a distribuição chega mais achatada ao top-p, e
0.9 agora mantém cinco palavras, onde com temperatura 1 mantinha quatro. **O efeito de uma
configuração depende das configurações aplicadas antes dela.**

Os provedores diferem em quais delas expõem e nos detalhes de como as combinam. A Messages API da
Anthropic aceita `temperature`, `top_k` e `top_p`; a Chat Completions API da OpenAI aceita
`temperature` e `top_p` e não tem `top_k`. Leia a documentação daquele que você chama e mude uma
configuração de cada vez, pelo motivo dado na aula 7.
