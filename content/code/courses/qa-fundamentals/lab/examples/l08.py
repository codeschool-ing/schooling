# lesson 8: the order program, which writes to a database

example('orders', 'orders.py', [
    ('# orders.py\nimport sqlite3\nimport sys\nfrom tickets import brl, price\n',
     'An order uses the price rule from `tickets.py` for each ticket, and `sqlite3`, Python’s own database, '
     'to keep a record of it. Keep it in `~/aurora` beside `tickets.py`.',
     'Um pedido usa a regra de preço do `tickets.py` para cada ingresso, e o `sqlite3`, o banco de dados do '
     'próprio Python, para guardar um registro dele. Deixe-o em `~/aurora` ao lado do `tickets.py`.'),
    ('\ndb = sqlite3.connect("aurora.db", isolation_level=None)\ndb.execute("CREATE TABLE IF NOT EXISTS orders"\n           " (id INTEGER PRIMARY KEY, session TEXT, tickets INTEGER, total INTEGER)")\n',
     'The database is one file, `aurora.db`, with one table, `orders`: a number, the session, how many '
     'tickets and the total in centavos. `isolation_level=None` makes every statement save at once.',
     'O banco é um arquivo, `aurora.db`, com uma tabela, `orders`: um número, a sessão, quantos ingressos e o '
     'total em centavos. `isolation_level=None` faz cada comando ser salvo na hora.'),
    ('\n\ndef place(day, time, ages):\n    cur = db.execute("INSERT INTO orders (session, tickets, total) VALUES (?, ?, 0)",\n                     (f"{day} {time}", len(ages)))\n',
     'Placing an order starts by writing its row, with a total of zero to be filled in below.',
     'Fazer um pedido começa gravando a linha dele, com total zero para ser preenchido mais abaixo.'),
    ('    if not 1 <= len(ages) <= 6:\n        return "refused: an order holds 1 to 6 tickets"\n',
     'The rule’s fourth sentence: an order holds between one and six tickets. Anything else is refused.',
     'A quarta frase da regra: um pedido tem de um a seis ingressos. Qualquer outra coisa é recusada.'),
    ('    total = sum(price(age, False, day, time) for age in ages)\n    db.execute("UPDATE orders SET total = ? WHERE id = ?", (total, cur.lastrowid))\n    return f"order {cur.lastrowid}: {len(ages)} tickets, {brl(total)}"\n',
     'Otherwise the price of each ticket is added up and written into the row. This version sells no '
     'student tickets: `False` is passed for every one, and Joana has scheduled students for later.',
     'Senão, o preço de cada ingresso é somado e gravado na linha. Esta versão não vende meia de estudante: '
     'passa `False` para todos, e a Joana deixou os estudantes para depois.'),
    ('\n\nif __name__ == "__main__":\n    day, time = sys.argv[1], sys.argv[2]\n    print(place(day, time, [int(a) for a in sys.argv[3:]]))\n',
     'On the command line: the day, the time, and then the age of each person, one word per ticket.',
     'Na linha de comando: o dia, o horário, e depois a idade de cada pessoa, uma palavra por ingresso.'),
])
