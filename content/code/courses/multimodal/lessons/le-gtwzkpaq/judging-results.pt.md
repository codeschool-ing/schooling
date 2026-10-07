---
title: Julgando as imagens, e quanto custa uma aceita
version: 2
---

Uma grade de imagens não decide nada sozinha. Alguém olha para ela, e o olhar funciona melhor com uma lista escrita antes de chegar a primeira imagem, porque uma imagem impressionante que não atende à exigência continua sendo um erro.

Para o banner, a lista é a exigência e o guia de estilo:

1. O terço direito está vazio o bastante para uma manchete?
2. Há algum texto, ou algo que tente ser texto?
3. Há um rosto, ou algo que possa ser lido como uma pessoa real ou uma marca real?
4. O meio e a paleta são os do guia?
5. Um leitor veria uma pilha de livros, rapidamente, no tamanho em que a newsletter a mostra?

Cada imagem recebe sim ou não por linha, e só uma imagem com cinco sins é candidata. Escrever a lista primeiro é o que impede o julgamento de virar gosto.

## O custo de uma imagem aceita

A geração de imagens é cobrada por imagem. Este curso lê os preços de um lugar só, uma tabela que a biblioteca de código aberto LiteLLM mantém de todo modelo que sabe chamar, e a lê com um programa curto. A tabela é a cópia que um terceiro faz das páginas dos próprios provedores, e o programa fixa uma versão dela, então os números abaixo continuam os mesmos por mais tempo que passe até você rodá-lo.

`prices.py`, que as aulas 9, 10 e 13 também usam:

```python
"""prices: what LiteLLM's price sheet says about a model, read at one pinned commit.

    python prices.py show NAME                every field of one entry
    python prices.py find TEXT [MODE]         every entry whose name contains TEXT

LiteLLM is an open-source library that calls a hundred providers through one
interface, and it keeps one JSON file of every model's prices to do it. It is a
third party's copy of the providers' pages, so every number this course takes
from it says so. The commit is pinned, so the same file comes out next year.
"""
import json
import os
import sys
import urllib.request

COMMIT = "21881c571181fc0e409dd717b8a277e5b43152a7"
URL = f"https://raw.githubusercontent.com/BerriAI/litellm/{COMMIT}/model_prices_and_context_window.json"
CACHE = os.path.expanduser(f"~/mm/data/litellm-{COMMIT[:8]}.json")

if not os.path.exists(CACHE):                       # downloaded once, then read from disk
    os.makedirs(os.path.dirname(CACHE), exist_ok=True)
    urllib.request.urlretrieve(URL, CACHE)
sheet = json.load(open(CACHE))

if sys.argv[1] == "show":
    for key, value in sorted(sheet[sys.argv[2]].items()):
        print(f"{key:42} {value}")
elif sys.argv[1] == "find":
    mode = sys.argv[3] if len(sys.argv) > 3 else None
    for name, entry in sorted(sheet.items()):
        if sys.argv[2] in name and mode in (None, entry.get("mode")):
            print(f"{name:44} {entry.get('litellm_provider', ''):26} {entry.get('deprecation_date', '')}")
```

O que ela diz sobre o modelo de imagem do Google:

```
ana@lab:~/mm$ python prices.py show gemini/gemini-2.5-flash-image | grep -E "output_cost_per_image|deprecation|source"
deprecation_date                           2026-10-02
output_cost_per_image                      0.039
output_cost_per_image_token                3e-05
source                                     https://ai.google.dev/gemini-api/docs/pricing
ana@lab:~/mm$ python -c "print(round(0.039 * 4, 3), round(0.039 * 12, 3))"
0.156 0.468
```

**0,039 dólar por imagem**, e uma **data de descontinuação em 2 de outubro de 2026**, cinco dias antes de esta aula ser gravada. As duas coisas são fatos de um dia de um provedor, lidos da cópia que um terceiro faz da página de preços do Google, e as duas vão estar diferentes quando você ler isto. A aula 9 vê o que essa data significa para um código que cita o modelo.

O preço que importa não é por imagem, e sim **por imagem aceita**. Se uma imagem em quatro passa na lista, cada banner custa quatro gerações: 0,156 dólar. Se a equipe gera duas por variante, em cinco variantes, e fica com uma, custa 0,468 dólar por aquele banner, como a segunda linha acima calcula. Ainda é barato para um banner, e não é barato como um recurso que o cliente aperta de novo e de novo, que é o alerta da ficha de design sobre todo este curso e o assunto da aula 13.
