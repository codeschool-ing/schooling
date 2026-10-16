---
title: Tentar de novo sem fazer duas vezes
version: 1
---

**Um timeout não é uma falha. É um resultado desconhecido, e um resultado desconhecido só é seguro de
repetir se fazer a coisa duas vezes tiver o mesmo efeito que fazer uma.** Essa propriedade se chama
**idempotência**. Marcar a doca 4 do Batel como "vazia" é idempotente: marque duas vezes e ela
continua vazia. Somar uma tarifa à conta de um cliente não é: some duas vezes e o cliente paga duas
vezes.

A imagem errada é a de que uma nova tentativa repete um pedido que falhou. Muitas vezes o pedido nem
falhou. Ele fez o trabalho, e a resposta se perdeu na volta, que é um dos três silêncios da seção
anterior.

## Tentar de novo direito

Três hábitos tornam as novas tentativas seguras para o sistema que as recebe:

- esperar antes de tentar de novo, e esperar mais a cada vez, dobrando a espera a cada tentativa;
  isso se chama **backoff exponencial**, e dá a um serviço em apuros espaço para se recuperar;
- pôr um acaso na espera, o chamado **jitter**, para que mil clientes que falharam no mesmo
  instante não voltem todos no mesmo instante;
- desistir depois de poucas tentativas, e avisar alto, em vez de tentar para sempre.

## Tornar a escrita segura de repetir

O programa abaixo é um serviço de pagamento com uma rede ruim: ele registra cada cobrança e depois
perde a resposta, duas vezes seguidas, antes de uma terceira resposta passar. A tarifa é de 450
centavos, um preço inventado para o exemplo. Um cliente tenta de novo com backoff, uma vez contra um
serviço que insere uma linha a cada pedido, e uma vez contra um serviço que lembra o **id do pedido**
que o cliente mandou e se recusa a cobrar o mesmo id duas vezes. Salve como `retry.py`:

```schooling-example
{"language": "python", "file": "spread/retry.py", "parts": [
{"code": "# spread/retry.py\nimport random\nimport sqlite3\nimport time\n\nrandom.seed(3)\ndb = sqlite3.connect(\":memory:\")\ndb.execute(\"CREATE TABLE charges (request TEXT UNIQUE, ride TEXT, cents INTEGER)\")\n\n\n", "note": "Um livro-caixa em memória, com uma coluna para o id do pedido que o banco não deixa repetir."},
{"code": "def charge(request, ride, cents, safe):\n    if safe:            # a request id the ledger has seen is a repeat, not a charge\n        db.execute(\"INSERT OR IGNORE INTO charges VALUES (?, ?, ?)\", (request, ride, cents))\n    else:\n        db.execute(\"INSERT INTO charges (ride, cents) VALUES (?, ?)\", (ride, cents))\n    if lost.pop(0):     # the charge was made; the reply did not come back\n        raise TimeoutError\n\n\n", "note": "O serviço de pagamento. Seguro ou não, ele registra a cobrança primeiro e depois perde a resposta, enquanto `lost` mandar. A versão insegura insere uma linha nova a cada vez; a segura só insere se o id do pedido for novo, num único comando."},
{"code": "for safe in (False, True):\n    print(\"request id checked:\", \"yes\" if safe else \"no\")\n    db.execute(\"DELETE FROM charges\")\n    lost = [True, True, False]\n", "note": "O cliente, executado duas vezes. Cada execução perde as duas primeiras respostas e entrega a terceira."},
{"code": "    for attempt in range(1, 5):\n        try:\n            charge(\"req-0001\", \"R000123\", 450, safe)\n            print(f\"  attempt {attempt}: ok\")\n            break\n        except TimeoutError:\n            wait = 0.1 * 2 ** (attempt - 1) * random.uniform(0.5, 1)\n            print(f\"  attempt {attempt}: no reply, waiting {wait:.2f} s\")\n            time.sleep(wait)\n", "note": "Até quatro tentativas. Depois de cada silêncio a espera dobra, 0,1 s, 0,2 s, 0,4 s, e então é multiplicada por um fator aleatório entre meio e um, para que clientes que falharam juntos não tentem todos de novo ao mesmo tempo."},
{"code": "    rows, cents = db.execute(\"SELECT count(*), sum(cents) FROM charges\").fetchone()\n    print(f\"  rows in the ledger: {rows}, total {cents} cents\")\n", "note": "O que o livro-caixa guarda para uma viagem, depois que o cliente ouviu \"ok\" uma vez."}
]}
```

```
ana@lab:~/roda/spread$ python retry.py
request id checked: no
  attempt 1: no reply, waiting 0.06 s
  attempt 2: no reply, waiting 0.15 s
  attempt 3: ok
  rows in the ledger: 3, total 1350 cents
request id checked: yes
  attempt 1: no reply, waiting 0.07 s
  attempt 2: no reply, waiting 0.16 s
  attempt 3: ok
  rows in the ledger: 1, total 450 cents
```

Os dois clientes viram a mesma coisa: dois silêncios, depois `ok`. Sem id do pedido, o livro-caixa
tem três cobranças e 1350 centavos por uma viagem, e nada na saída do cliente diz isso. Com ele, tem
uma cobrança de 450 centavos.

O trabalho é feito por duas coisas juntas. O cliente inventa o id do pedido **uma vez**, para a
cobrança que pretende fazer, e manda o mesmo id em cada nova tentativa dela; um id novo a cada
tentativa faria toda nova tentativa parecer nova. E o serviço deixa o banco recusar a duplicata: a
coluna `UNIQUE` e o `INSERT OR IGNORE` decidem num único comando. Conferir antes e inserir depois
seriam dois passos, e duas tentativas chegando juntas podem passar as duas pela conferência antes de
qualquer uma inserir.

A mesma ideia aparece onde quer que um pedido possa chegar duas vezes. Provedores de pagamento
costumam aceitar uma chave de idempotência em cada pedido exatamente por isso. E a aula 8 a encontra
pelo outro lado. Um consumidor de fluxo que cai depois de fazer o trabalho, e antes de registrar que
o fez, lê as mesmas mensagens de novo; gravar os resultados de um jeito que uma repetição não mude
nada é o que torna isso inofensivo.
