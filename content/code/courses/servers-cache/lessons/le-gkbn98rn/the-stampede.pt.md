---
title: O estouro
version: 1
---

Todo padrão da aula 10 tinha a mesma suposição silenciosa: **um leitor erra o cache por vez**. Num livro
pouco procurado isso vale. Na página mais movimentada da loja falha no instante em que a chave vence,
porque toda requisição que chega antes de a primeira reabastecer o cache também erra, e cada uma vai ao
banco pela mesma linha. Isso é um **estouro de cache** (*cache stampede*), também chamado de manada
trovejante ou de pilha de cachorros, e é a falha que um leitor deste curso tem mais chance de encontrar
em produção.

Este programa manda um número de leitores para o `bookcache.get_book(2)` de uma vez, cada um na própria
thread, depois de apagar a chave para que o primeiro deles não encontre nada:

```python
import importlib
import sys
import threading
import time

import catalogue

readers, module = int(sys.argv[1]), importlib.import_module(sys.argv[2])
if "--keep" not in sys.argv:
    module.r.delete("book:2")

before = catalogue.queries
start = time.perf_counter()
threads = [threading.Thread(target=module.get_book, args=(2,)) for _ in range(readers)]
for t in threads:
    t.start()
for t in threads:
    t.join()
ms = (time.perf_counter() - start) * 1000
print(f"{sys.argv[2]}, readers at once: {readers}, database queries: {catalogue.queries - before}, {ms:.0f} ms")
```

```
ana@web:~/work$ python3 stampede.py 1 bookcache
bookcache, readers at once: 1, database queries: 1, 122 ms
ana@web:~/work$ python3 stampede.py 50 bookcache
bookcache, readers at once: 50, database queries: 50, 158 ms
ana@web:~/work$ python3 stampede.py 50 bookcache --keep
bookcache, readers at once: 50, database queries: 0, 15 ms
```

**Um leitor custou uma consulta. Cinquenta leitores de uma vez custaram cinquenta**, todas pela mesma
linha, e a rajada inteira levou pouco mais que o tempo de uma consulta porque elas rodaram lado a lado.
A terceira rodada manteve a cópia em cache e não custou nada. Nada no `bookcache.py` está errado; ele
só não faz ideia de que outras quarenta e nove cópias dele estão fazendo a mesma coisa no mesmo instante.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" aria-label=\"Dois gráficos de consultas ao banco por décimo de segundo em torno do instante em que uma chave popular vence. À esquerda, sem proteção: nada, depois uma única barra de 50 consultas no instante do vencimento, depois nada. À direita, com um lock: uma única barra de 1 consulta no mesmo instante.\"><defs><marker id=\"fsp-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"180\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">sem proteção</text><line x1=\"40\" y1=\"200\" x2=\"330\" y2=\"200\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><line x1=\"40\" y1=\"200\" x2=\"40\" y2=\"35\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><rect x=\"208\" y=\"50.0\" width=\"14\" height=\"150.0\" fill=\"var(--amber)\" stroke=\"none\" fill-opacity=\"0.8\"></rect><text x=\"215\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">50 consultas</text><line x1=\"215\" y1=\"225\" x2=\"215\" y2=\"205\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fsp-ah)\"></line><text x=\"215\" y=\"237\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a chave vence</text><text x=\"520\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">com um lock</text><line x1=\"380\" y1=\"200\" x2=\"670\" y2=\"200\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><line x1=\"380\" y1=\"200\" x2=\"380\" y2=\"35\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><rect x=\"548\" y=\"196\" width=\"14\" height=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" fill-opacity=\"0.8\"></rect><text x=\"555\" y=\"187.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1 consulta</text><line x1=\"555\" y1=\"225\" x2=\"555\" y2=\"205\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fsp-ah)\"></line><text x=\"555\" y=\"237\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a chave vence</text></svg>", "caption": "Cinquenta leitores chegando no mesmo décimo de segundo. Sem proteção cada um pergunta ao banco; com um lock, um pergunta."}
```

A aritmética é o que torna isso perigoso. Uma página lida 500 vezes por segundo, cuja consulta ao banco
leva 120 milissegundos, manda cerca de 60 consultas idênticas no instante em que a chave vence: todas
as requisições desses 120 milissegundos. Se o banco fica lento sob essa carga, a janela aumenta, mais
requisições caem nela, e o banco fica mais lento ainda. **Um cache que poupava o banco vira a coisa que
o derruba**, num horário marcado pelo tempo de vida de uma chave.

O resto desta aula são quatro jeitos de impedir isso, cada um com um custo diferente: fazer os leitores
esperarem um deles, servir a cópia velha enquanto um atualiza, atualizar antes de a chave vencer, e
impedir que as chaves vençam juntas. Depois, os mesmos problemas uma camada acima, no Nginx, e o começo a
frio que nenhum tempo de vida evita.
