---
title: De pontuações a uma escolha
version: 2
---

É tentador imaginar um modelo decidindo a próxima palavra. **O que ele produz é uma pontuação para
cada token que poderia escrever em seguida**, e uma etapa separada, o amostrador, transforma essas
pontuações numa escolha. Temperatura, top-k e top-p são configurações dessa etapa e de mais nada.
`prompt-engineering` os apresentou nas aulas 13 e 14. Esta aula os retoma de propósito e os mede na
tarefa de triagem, em que uma resposta amostrada ou está certa ou está errada.

O Ollama consegue devolver as pontuações. Peça `logprobs`, e cada token da resposta volta com a sua
**log-probabilidade**, e com as log-probabilidades dos outros tokens que o modelo pesou naquele
ponto. Este programa pede uma resposta de triagem, acha o momento em que o modelo começa a escrever a
categoria e imprime os dez tokens que ele considerou ali. Depois faz o que um amostrador faz com
eles, mil vezes, para você ver as configurações agindo. Salve-o como `next.py`:

```python
"""next: the model's own scores for the first token of the category, and what
temperature, top-k and top-p would make of them."""
import argparse
import json
import math
import random
import urllib.request

from pl import DEFAULTS, OLLAMA, read_jsonl, read_prompt, render


def candidates(prompt, n=10):
    """The n likeliest first tokens of the category, as (token, logprob)."""
    body = {"model": DEFAULTS["model"], "stream": False, "logprobs": True, "top_logprobs": n,
            "options": {"temperature": 0, "seed": 1, "num_predict": 12},
            "messages": [{"role": "user", "content": prompt}]}
    req = urllib.request.Request(OLLAMA + "/api/chat", json.dumps(body).encode(),
                                 {"Content-Type": "application/json"})
    reply = json.load(urllib.request.urlopen(req))
    text = ""
    for step in reply["logprobs"]:
        if text.endswith('"category": "'):
            return [(c["token"], c["logprob"]) for c in step["top_logprobs"]]
        text += step["token"]
    raise SystemExit("next: the reply has no category: " + text)


def distribution(scores, temperature=1.0, top_k=0, top_p=1.0):
    """Temperature, then top-k, then top-p, then the survivors share the total."""
    top = max(scores)
    weights = [math.exp((s - top) / temperature) for s in scores]
    probs = [w / sum(weights) for w in weights]
    order = sorted(range(len(probs)), key=lambda i: -probs[i])
    keep = order[:top_k] if top_k else order
    if top_p < 1.0:
        kept, total = [], 0.0
        for i in keep:
            kept.append(i)
            total += probs[i]
            if total >= top_p:
                break
        keep = kept
    total = sum(probs[i] for i in keep)
    return [probs[i] / total if i in keep else 0.0 for i in range(len(probs))]


p = argparse.ArgumentParser(prog="next")
p.add_argument("prompt")
p.add_argument("cases")
p.add_argument("id")
p.add_argument("--temperature", type=float, default=1.0)
p.add_argument("--top-k", type=int, default=0)
p.add_argument("--top-p", type=float, default=1.0)
p.add_argument("--draws", type=int, default=1000)
a = p.parse_args()

case = next(c for c in read_jsonl(a.cases) if c["id"] == a.id)
_, template = read_prompt(a.prompt)
cands = candidates(render(template, {"message": case["message"]}))
probs = distribution([lp for _, lp in cands], a.temperature, a.top_k, a.top_p)
rng = random.Random(1)
drawn = rng.choices(range(len(cands)), weights=probs, k=a.draws)
print("%s, temperature %g, top-k %s, top-p %g, %d draws"
      % (a.id, a.temperature, a.top_k or "off", a.top_p, a.draws))
for i, (token, logprob) in enumerate(cands):
    print("  %-10s %7.2f %6.1f%% %5d  %s" % (repr(token), logprob, 100 * probs[i],
                                            drawn.count(i), "#" * round(40 * probs[i])))
```

As pontuações são do modelo; a tiragem é feita pela `distribution()` e pelo `random` do Python, para
você ver cada etapa. Aqui está o `t22`, a pergunta do vale-presente sobre a qual a aula 5
discutiu:

```
ana@lab:~/triage$ grep t22 cases/dev.jsonl
{"id": "t22", "message": "Can I pay with a gift card and a credit card on the same order?", "expect": {"category": "billing", "urgency": "low"}}
ana@lab:~/triage$ python3 next.py prompts/v6-escaped.txt cases/dev.jsonl t22
t22, temperature 1, top-k off, top-p 1, 1000 draws
  'other'      -0.49   62.1%   604  #########################
  'billing'    -1.50   22.5%   226  #########
  'account'    -2.15   11.7%   122  #####
  ' billing'   -3.84    2.2%    32  #
  'delivery'   -5.18    0.6%     8  
  ' Billing'   -5.81    0.3%     3  
  'Billing'    -6.15    0.2%     2  
  'shipping'   -6.30    0.2%     1  
  'payment'    -6.65    0.1%     2  
  'accounts'   -6.68    0.1%     0  
```

Cada linha é um token que o modelo considerou, a log-probabilidade dele, a parte dele depois que o
programa transformou as pontuações em probabilidades, quantas de 1.000 tiragens o escolheram e uma
barra. **O softmax é a etapa que transforma pontuações em probabilidades**: eleve *e* a cada
pontuação, depois divida cada resultado pelo total deles, para que tudo some um. Só as diferenças
entre as pontuações importam. `other` pontua cerca de um ponto a mais que `billing`, e *e* elevado a
1,01 dá cerca de 2,75, que é a razão entre 62,1% e 22,5%. O programa fica só com os dez tokens mais
prováveis, então as partes são desses dez; o resto do vocabulário do modelo quase não tinha nada
aqui.

Três coisas nessa lista valem uma segunda olhada. **O favorito do modelo está errado**: uma pessoa
rotulou o `t22` como billing, e o modelo dá a billing 22,5%. Temperatura 0 pega o favorito toda vez,
e é por isso que o `t22` falhou nas aulas 5 e 7. A lista também tem tokens que quebrariam o contrato:
`' billing'` com um espaço na frente e `'Billing'` com maiúscula são tokens diferentes de `billing`,
e qualquer um dos dois reprovaria na verificação `labels`. E algumas mensagens não são casos
apertados de jeito nenhum:

```
ana@lab:~/triage$ python3 next.py prompts/v6-escaped.txt cases/dev.jsonl t08
t08, temperature 1, top-k off, top-p 1, 1000 draws
  'returns'    -0.00   99.8%   998  ########################################
  'Returns'    -6.75    0.1%     2  
  '_returns'   -7.28    0.1%     0  
  ' returns'   -8.19    0.0%     0  
  'return'     -8.97    0.0%     0  
  ' Returns'   -9.44    0.0%     0  
  'orders'    -11.16    0.0%     0  
  'ret'       -11.77    0.0%     0  
  'other'     -11.80    0.0%     0  
  'returned'  -11.90    0.0%     0  
```

O `t08`, uma troca de capa dura por brochura, é `returns` com 99,8%. Nenhuma configuração do
amostrador faz muita diferença ali. O resto desta aula é sobre as mensagens como o `t22`, onde faz.
