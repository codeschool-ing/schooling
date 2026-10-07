---
title: O leitor lento
version: 1
---

Apagar não fecha todas as brechas. Um leitor que erra o cache, lê a linha velha e depois se atrasa antes
de guardar a cópia pode guardá-la depois do apagamento do escritor. É a corrida da aula 6, agora na
aplicação:

```schooling-example
{"language": "python", "file": "readers.py", "parts": [{"code": "import json\nimport threading\nimport time\n\nimport catalogue\nfrom bookcache import get_book, r, update_price\n\n\ndef slow_reader():\n    book = catalogue.get_book(2)        # the cache missed; this is the old price\n    time.sleep(0.2)                     # a pause: a busy CPU, a garbage collection\n    r.set(\"book:2\", json.dumps(book), ex=300)\n\n\ndef writer(price, delete_again):\n    time.sleep(0.2)                     # the reader has its row by now\n    update_price(2, price)\n    if delete_again:\n        time.sleep(0.5)                 # longer than any read takes\n        r.delete(\"book:2\")\n\n\nfor price, delete_again in ((7990, False), (6990, True)):\n    r.delete(\"book:2\")\n    threads = [threading.Thread(target=slow_reader), threading.Thread(target=writer, args=(price, delete_again))]\n    for t in threads:\n        t.start()\n    for t in threads:\n        t.join()\n    print(f\"delete again {delete_again!s:>5}: database {price}, cache {get_book(2)['price_cents']}, ttl {r.ttl('book:2')}\")\n", "note": "Um leitor que pausa entre o banco e o cache, e um escritor que apaga uma vez, depois duas."}]}
```

```
ana@web:~/work$ python3 readers.py
delete again False: database 7990, cache 6990, ttl 300
delete again  True: database 6990, cache 6990, ttl 300
```

Na primeira rodada o escritor fez tudo certo, banco e depois apagamento, e **o cache ainda terminou com
o preço velho e 300 segundos inteiros para guardá-lo**: o `set` do leitor chegou depois do apagamento.
Na segunda rodada o escritor apagou a chave uma segunda vez, meio segundo depois, mais que qualquer
leitura deste programa leva, e a cópia velha foi junto.

Esse segundo apagamento se chama **apagamento duplo atrasado**, e ele estreita a janela em vez de
fechá-la: um leitor mais lento que o atraso ainda ganha. Três coisas limitam o estrago na prática, e o
hábito é usar as três.

- **Um tempo de vida em toda chave.** Seja como for a corrida, o valor errado vive no máximo `TTL`
  segundos. É a única garantia que se mantém quando todo o resto falha, e o motivo de a aula 8 insistir
  nela.
- **O segundo apagamento**, para o caso comum de um leitor algumas centenas de milissegundos lento.
- **Uma versão no valor**, aqui o `updated_at`, para que um leitor possa se recusar a guardar uma linha
  mais velha que outra que ele sabe ter sido gravada. Isso exige que o caminho de escrita registre a
  versão num lugar que o leitor veja, e só vale o esforço onde um valor velho custa dinheiro de verdade.
