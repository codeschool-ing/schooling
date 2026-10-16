---
title: Tentar de novo é trabalho da aplicação
version: 1
---

As seções 03 e 04 desta aula terminaram no mesmo lugar: uma transação recusada com o SQLSTATE
**40001**, e um `HINT` dizendo que ela poderia dar certo se tentada de novo. A reação comum é tratar
isso como erro do banco, registrar no log e devolver uma falha ao usuário. **Não é um erro nesse
sentido.** É o servidor dizendo "esta transação perdeu uma corrida e nada do que ela fez foi
mantido; rode de novo". Em `REPEATABLE READ` ou `SERIALIZABLE`, escrever a nova tentativa faz parte
de escrever a transação, do mesmo jeito que o deadlock da aula 12, SQLSTATE **40P01**, precisa de
uma.

Três regras tornam uma nova tentativa correta:

- **Repita a transação inteira, desde o `BEGIN`.** A transação que falhou é desfeita por completo;
  reenviar o último comando dela o rodaria sem transação em volta, sobre dados que ele nunca leu.
- **Repita as leituras também.** O objetivo da nova tentativa é um snapshot novo. Um código que leu o
  preço antes do laço e só repete a escrita recria a atualização perdida.
- **Repita só 40001 e 40P01, um número limitado de vezes.** Esses dois querem dizer "tente de novo".
  Uma violação de constraint ou um erro de sintaxe falharia igual para sempre.

## O pgbench repete, e quanto isso custa

O pgbench tem o laço embutido: `--max-tries` roda de novo uma transação que falha com 40001 ou 40P01,
até esse número de vezes. O mesmo `price-bump.sql`, agora em `SERIALIZABLE`, com até dez tentativas
cada:

```
market=# SELECT sum(price_cents) AS before FROM products WHERE id <= 10 \gset
Time: 1.553 ms

market=# \! PGOPTIONS='-c default_transaction_isolation=serializable' pgbench -n -c 8 -j 4 -T 10 --max-tries=10 -f ~/workload/price-bump.sql market
pgbench (16.15 (Ubuntu 16.15-0ubuntu0.24.04.1))
transaction type: /home/ana/workload/price-bump.sql
scaling factor: 1
query mode: simple
number of clients: 8
number of threads: 4
maximum number of tries: 10
duration: 10 s
number of transactions actually processed: 37218
number of failed transactions: 17 (0.046%)
number of transactions retried: 12509 (33.595%)
total number of retries: 20781
latency average = 2.147 ms (including failures)
initial connection time = 17.458 ms
tps = 3724.890914 (without initial connection time)

market=# SELECT sum(price_cents) - :before AS cents_added FROM products WHERE id <= 10;
 cents_added 
-------------
       37218
(1 row)

Time: 0.668 ms
```

**37.218 transações confirmadas, e os preços subiram exatamente 37.218 centavos.** 12.509 delas, um
terço, precisaram de mais de uma tentativa, 20.781 tentativas a mais no total, e 17 ainda falharam
depois de dez, porque oito clientes em dez linhas é uma briga em que alguma transação perde dez vezes
seguidas.

Lado a lado, as três execuções desta aula:

| | read committed | repeatable read | serializable, 10 tentativas |
|---|---|---|---|
| confirmadas | 55.802 | 49.741 | 37.218 |
| centavos somados | 37.821 | 49.741 | 37.218 |
| perdidas ou com falha | 17.981 perdidas | 28.848 com falha | 17 com falha |
| transações por segundo | 5578 | 4975 | 3725 |

**Só a última coluna está ao mesmo tempo correta e completa.** O `READ COMMITTED` foi o mais rápido e
errou em um terço. O `REPEATABLE READ` acertou toda transação que confirmou e recusou um terço delas.
O `SERIALIZABLE` com novas tentativas confirmou menos por segundo que os dois, porque cada nova
tentativa é trabalho feito duas vezes, e acertou todas menos 17. Tome as taxas de transação como
aproximadas: nesta máquina, a mesma execução de dez segundos varia uma boa fração entre tentativas, e
as contagens são a parte que não varia. Numa carga de verdade, com milhares de linhas em vez de dez,
conflitos são raros, as novas tentativas são uma fração de um por cento, e o custo do nível mais
forte é sobretudo a contabilidade.

## Um laço de novas tentativas, em Python

Uma aplicação precisa fazer o que o `--max-tries` fez. Aqui está em Python, com o **psycopg**, o
driver de PostgreSQL que o Ubuntu empacota. Instale-o na máquina virtual:

```
ana@vm:~$ sudo apt install -y python3-psycopg

WARNING: apt does not have a stable CLI interface. Use with caution in scripts.

Reading package lists...
Building dependency tree...
Reading state information...
python3-psycopg is already the newest version (3.1.17-2).
0 upgraded, 0 newly installed, 0 to remove and 140 not upgraded.
```

Esta máquina já o tinha; a sua vai baixá-lo antes. O programa aumenta o preço do produto 1 em um
centavo, N vezes, cada uma na própria transação `SERIALIZABLE`, e repete o que o servidor recusar.
Copie-o inteiro para `~/bump.py`:

```schooling-example
{
  "language": "python",
  "file": "bump.py",
  "parts": [
    {
      "code": "#!/usr/bin/env python3\n\"\"\"bump.py N: raise product 1's price by one cent, N times, each time in a\nSERIALIZABLE transaction, retrying whatever the server refuses to serialise.\"\"\"\nimport random\nimport sys\nimport time\n\nimport psycopg\nfrom psycopg import errors\n\n"
    },
    {
      "code": "RETRY = (errors.SerializationFailure, errors.DeadlockDetected)  # 40001, 40P01\n\n",
      "note": "**Os dois erros que vale repetir.** Os dois querem dizer \"esta transação perdeu uma corrida e foi desfeita inteira\", então rodá-la de novo desde o começo é seguro. Qualquer outro, um erro de sintaxe ou uma constraint violada, falharia igual toda vez, e repeti-lo só o esconde."
    },
    {
      "code": "\ndef bump(conn):\n    with conn.transaction():\n        price = conn.execute(\"SELECT price_cents FROM products WHERE id = 1\").fetchone()[0]\n        time.sleep(0.001)  # the application decides; others get in meanwhile\n        conn.execute(\"UPDATE products SET price_cents = %s WHERE id = 1\", (price + 1,))\n\n",
      "note": "**A transação inteira é uma função.** O `conn.transaction()` manda `BEGIN`, e `COMMIT` quando o bloco termina, ou `ROLLBACK` se algo lá dentro levantou erro. A leitura e a escrita estão as duas dentro, então uma nova tentativa repete a leitura também e parte do preço novo, e é isso que torna a repetição correta em vez de uma segunda atualização perdida."
    },
    {
      "code": "\ndef with_retries(conn, work, tries=10):\n    for attempt in range(1, tries + 1):\n        try:\n            work(conn)\n            return attempt\n        except RETRY:\n            time.sleep(random.uniform(0, 0.005 * 2 ** attempt))  # back off: twice as long each time\n    raise RuntimeError(f\"gave up after {tries} tries\")\n\n",
      "note": "**O laço.** Roda o trabalho; num erro que vale repetir, espera um tempo curto e aleatório e roda de novo; desiste depois de dez tentativas e avisa. A espera aleatória evita que duas transações que colidiram colidam de novo no mesmo instante, e o teto dela dobra a cada tentativa, então uma transação que continua perdendo espera o bastante para a outra terminar."
    },
    {
      "code": "\nconn = psycopg.connect(\"dbname=market\", autocommit=True)\nconn.execute(\"SET default_transaction_isolation = 'serializable'\")\nn = int(sys.argv[1])\nattempts = [with_retries(conn, bump) for _ in range(n)]\nprint(f\"{n} bumps, {sum(attempts) - n} retries, at most {max(attempts)} tries for one\")\n",
      "note": "**Toda transação nesta conexão é `SERIALIZABLE`.** O `autocommit=True` impede o psycopg de abrir uma transação própria em volta de tudo, então as únicas transações são as que o `bump` pede. A última linha conta quantas tentativas foram a mais."
    }
  ]
}
```

Duas cópias ao mesmo tempo, quinhentos aumentos cada, com o preço lido antes e depois. Rode do
`psql market`, para que uma janela guarde as duas leituras:

```
market=# SELECT price_cents FROM products WHERE id = 1;
 price_cents 
-------------
       22303
(1 row)

Time: 1.883 ms

market=# \! python3 ~/bump.py 500 & python3 ~/bump.py 500 & wait
500 bumps, 2 retries, at most 3 tries for one
500 bumps, 8 retries, at most 9 tries for one

market=# SELECT price_cents FROM products WHERE id = 1;
 price_cents 
-------------
       23303
(1 row)

Time: 0.379 ms
```

**1000 aumentos, e o preço foi de 22303 para 23303: exatamente 1000 centavos.** Os dois programas
colidiram 10 vezes entre eles, duas novas tentativas num e oito no outro, e uma transação precisou de
nove tentativas. Ninguém viu erro, e nada se perdeu.

Enquanto esta aula era gravada, uma primeira versão do programa esperava no máximo alguns
milissegundos entre tentativas, crescendo devagar, e uma das duas cópias desistiu depois de dez
tentativas: as duas continuavam colidindo no mesmo passo. A espera que dobra a cada vez foi o que
desfez o empate. Essa é a lição geral sobre novas tentativas: **sem uma espera aleatória e crescente,
duas transações que colidiram uma vez tendem a colidir de novo.**

## Onde o laço fica

- **Em volta da unidade de trabalho, não de cada comando.** Numa aplicação web, isso costuma ser a
  transação do tratador da requisição, ou uma função como a `bump`, que o laço pode chamar de novo.
- **Não em volta de nada com efeito fora do banco.** Se a transação manda um e-mail ou cobra um
  cartão antes de confirmar, uma nova tentativa faz isso duas vezes. Faça essas coisas depois do
  commit.
- **Atrás de um contador.** Conte novas tentativas e desistências, como a última linha do programa
  faz. Uma taxa de novas tentativas subindo é o primeiro sinal de que duas partes da aplicação
  começaram a brigar pelas mesmas linhas, muito antes de alguém ver um erro.

Ponha o `market` de volta com `~/reset-market.sh` antes da aula 15: esta aula aumentou muitos
preços.
