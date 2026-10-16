---
title: O programa que faz pedidos
version: 1
---

**O `tickets.py` responde quanto custa um ingresso. Vender ingressos também exige um pedido**: vários
ingressos para uma sessão, um total, e um registro de que a venda aconteceu. O Rafael escreveu essa parte
também, e é o primeiro programa do curso que guarda algo depois de terminar. Salve em `~/aurora` como
`orders.py`.

```schooling-example
{"language": "python", "file": "orders.py", "parts": [{"code": "# orders.py\nimport sqlite3\nimport sys\nfrom tickets import brl, price\n", "note": "Um pedido usa a regra de preço do `tickets.py` para cada ingresso, e o `sqlite3`, o banco de dados do próprio Python, para guardar um registro dele. Deixe-o em `~/aurora` ao lado do `tickets.py`."}, {"code": "\ndb = sqlite3.connect(\"aurora.db\", isolation_level=None)\ndb.execute(\"CREATE TABLE IF NOT EXISTS orders\"\n           \" (id INTEGER PRIMARY KEY, session TEXT, tickets INTEGER, total INTEGER)\")\n", "note": "O banco é um arquivo, `aurora.db`, com uma tabela, `orders`: um número, a sessão, quantos ingressos e o total em centavos. `isolation_level=None` faz cada comando ser salvo na hora."}, {"code": "\n\ndef place(day, time, ages):\n    cur = db.execute(\"INSERT INTO orders (session, tickets, total) VALUES (?, ?, 0)\",\n                     (f\"{day} {time}\", len(ages)))\n", "note": "Fazer um pedido começa gravando a linha dele, com total zero para ser preenchido mais abaixo."}, {"code": "    if not 1 <= len(ages) <= 6:\n        return \"refused: an order holds 1 to 6 tickets\"\n", "note": "A quarta frase da regra: um pedido tem de um a seis ingressos. Qualquer outra coisa é recusada."}, {"code": "    total = sum(price(age, False, day, time) for age in ages)\n    db.execute(\"UPDATE orders SET total = ? WHERE id = ?\", (total, cur.lastrowid))\n    return f\"order {cur.lastrowid}: {len(ages)} tickets, {brl(total)}\"\n", "note": "Senão, o preço de cada ingresso é somado e gravado na linha. Esta versão não vende meia de estudante: passa `False` para todos, e a Joana deixou os estudantes para depois."}, {"code": "\n\nif __name__ == \"__main__\":\n    day, time = sys.argv[1], sys.argv[2]\n    print(place(day, time, [int(a) for a in sys.argv[3:]]))\n", "note": "Na linha de comando: o dia, o horário, e depois a idade de cada pessoa, uma palavra por ingresso."}]}
```

## Fazendo pedidos por fora

O comando recebe o dia, o horário e uma idade por ingresso. Uma família de dois adultos e uma criança numa
noite de quinta, e dois adultos numa matinê de sábado:

```
lia@lab:~/aurora$ python orders.py thu 20:00 35 35 8
order 1: 3 tickets, R$ 90,00
lia@lab:~/aurora$ python orders.py sat 15:00 35 35
order 2: 2 tickets, R$ 56,00
```

As duas respostas estão certas pela regra. Dois adultos a R$ 36,00 e uma criança a R$ 18,00 dão R$ 90,00;
dois adultos numa matinê dão R$ 56,00. Os números dos pedidos contam a partir de um. De fora, o programa faz
o que deveria.

## E por dentro

Quem testa como caixa cinza não para no que o programa imprimiu, porque o programa também gravou algo. O
módulo `sqlite3` do Python tem uma linha de comando própria que roda uma consulta contra um arquivo de banco
e imprime as linhas. Eis tudo o que há na tabela `orders`:

```
lia@lab:~/aurora$ python -m sqlite3 aurora.db "SELECT * FROM orders"
(1, 'thu 20:00', 3, 9000)
(2, 'sat 15:00', 2, 5600)
```

Cada linha é uma tupla: o número do pedido, a sessão, o número de ingressos e o total em centavos. Elas
batem com o que a tela disse: 9000 centavos são R$ 90,00, e 5600 são R$ 56,00. **O lado de fora e o de
dentro contam a mesma história**, e é para isso que uma conferência de caixa cinza serve: confirmar que o
que foi dito ao usuário é o que o sistema registrou.

Essa concordância não é automática. Um programa pode imprimir um total e guardar outro, porque imprimir e
guardar são duas linhas separadas que podem dar errado separadamente. Quando concordam, o teste conferiu
algo que a caixa preta não conseguiria. A próxima seção é sobre quando não concordam.
