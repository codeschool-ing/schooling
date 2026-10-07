---
title: Apague, não grave
version: 1
---

Se quem grava sabe o preço novo, por que não gravá-lo no cache em vez de apagar a chave, e poupar o
próximo leitor do erro de cache? Porque **dois escritores podem terminar numa ordem diferente da que
começaram**. Este programa roda dois deles, cada um na própria thread, uma vez gravando no cache e outra
apagando:

```schooling-example
{"language": "python", "file": "writers.py", "parts": [{"code": "import json\nimport threading\nimport time\n\nimport catalogue\nfrom bookcache import get_book, r\n\nbase = catalogue.get_book(2)\n\n\ndef set_on_write(price, before_db, before_cache):\n    time.sleep(before_db)\n    catalogue.set_price(2, price)\n    time.sleep(before_cache)\n    r.set(\"book:2\", json.dumps(dict(base, price_cents=price)), ex=300)\n\n\ndef delete_on_write(price, before_db, before_cache):\n    time.sleep(before_db)\n    catalogue.set_price(2, price)\n    time.sleep(before_cache)\n    r.delete(\"book:2\")\n\n\nfor name, write in ((\"set on write\", set_on_write), (\"delete on write\", delete_on_write)):\n    a = threading.Thread(target=write, args=(7990, 0.0, 0.2))\n    b = threading.Thread(target=write, args=(6990, 0.1, 0.0))\n    a.start(); b.start(); a.join(); b.join()\n    print(f\"{name:>15}: database {catalogue.get_book(2)['price_cents']}, cache {get_book(2)['price_cents']}\")\n", "note": "Dois escritores em duas threads, cronometrados para que o primeiro a gravar o banco seja o último a gravar o cache."}]}
```

As pausas arranjam o que um servidor ocupado faz por acidente: o escritor A atualiza o banco primeiro e
a gravação dele no cache demora, o escritor B vem depois e é rápido.

```
ana@web:~/work$ python3 writers.py
   set on write: database 6990, cache 7990
delete on write: database 6990, cache 6990
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 260\" role=\"img\" aria-label=\"Quatro colunas: escritor A, o banco, o cache e escritor B, com o tempo descendo. Em 0 ms A grava 7.990 no banco. Em 100 ms B grava 6.990 no banco e depois 6.990 no cache. Em 200 ms A grava 7.990 no cache. O banco termina em 6.990 e o cache em 7.990.\"><defs><marker id=\"ftw-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"10\" width=\"140\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"90.0\" y=\"27.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">escritor A</text><rect x=\"210\" y=\"10\" width=\"120\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"270.0\" y=\"27.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">banco</text><rect x=\"370\" y=\"10\" width=\"120\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"430.0\" y=\"27.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cache</text><rect x=\"540\" y=\"10\" width=\"140\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"610.0\" y=\"27.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">escritor B</text><line x1=\"90\" y1=\"44\" x2=\"90\" y2=\"215\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><line x1=\"270\" y1=\"44\" x2=\"270\" y2=\"215\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><line x1=\"430\" y1=\"44\" x2=\"430\" y2=\"215\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><line x1=\"610\" y1=\"44\" x2=\"610\" y2=\"215\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><line x1=\"90\" y1=\"75\" x2=\"267\" y2=\"75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#ftw-ah)\"></line><text x=\"180.0\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">0 ms: 7.990</text><line x1=\"610\" y1=\"115\" x2=\"273\" y2=\"115\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#ftw-ah)\"></line><text x=\"440.0\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">100 ms: 6.990</text><line x1=\"610\" y1=\"150\" x2=\"433\" y2=\"150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#ftw-ah)\"></line><text x=\"520.0\" y=\"141\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">100 ms: 6.990</text><line x1=\"90\" y1=\"190\" x2=\"427\" y2=\"190\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#ftw-ah)\"></line><text x=\"180\" y=\"181\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">200 ms: 7.990</text><text x=\"270\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">termina em 6.990</text><text x=\"430\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">termina em 7.990</text></svg>", "caption": "Cada escritor grava no cache o próprio preço. Quem termina por último ganha o cache, e não é quem gravou o banco por último.", "same": ["cache"]}
```

**Gravando no cache, o banco diz 6.990 e o cache 7.990**, e vai dizer isso por cinco minutos: a última
gravação no banco foi a do B, a última no cache foi a do A. Apagando, a ordem dos dois apagamentos não
importa, porque os dois deixam a mesma coisa para trás, nada, e a próxima leitura busca o que quer que o
banco tenha. **Um apagamento é o mesmo em qualquer ordem que chegue; uma gravação não.** Esse é o
argumento inteiro, e é por isso que a invalidação apaga.
