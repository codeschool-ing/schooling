---
title: Uma semana que parece real
version: 1
---

O script de dados de exemplo do loanbook tem vinte e quatro linhas:

```schooling-example
{"language": "python", "file": "seed.py", "parts": [{"code": "\"\"\"Fill an empty loanbook with a week that looks like a real one.\"\"\"\nfrom contextlib import closing\nfrom datetime import date, timedelta\n\nimport app", "note": "Usa as funções da própria aplicação, e não SQL cru, então os empréstimos semeados passam pelas mesmas regras que os de uma professora: um empréstimo semeado também não poderia ser feito duas vezes."}, {"code": "ITEMS = [\"Projector 1\", \"Projector 2\", \"Laptop 03\", \"Laptop 07\", \"HDMI adapter A\",\n         \"Document camera\", \"Tripod\", \"Conference speaker\"]", "note": "Nomes que a sala de TI de fato usaria, com a numeração que um inventário real tem."}, {"code": "LOANS = [  # item, borrower, how many days ago it went out\n    (\"Projector 2\", \"Beatriz Nunes\", 2),\n    (\"Laptop 03\", \"Carlos Mendes\", 9),\n    (\"Document camera\", \"Dora Okafor\", 1),\n    (\"Tripod\", \"Eduardo Lins\", 4),\n]", "note": "Pessoas inventadas, com nomes do tipo que a lista de funcionários de uma escola tem. As datas são relativas a hoje, então os dados nunca envelhecem; nove dias atrás passa dos sete dias de empréstimo, então um empréstimo está sempre atrasado, e a captura sempre mostra esse estado."}, {"code": "with closing(app.connect()) as db:\n    if db.execute(\"SELECT count(*) FROM items\").fetchone()[0]:\n        raise SystemExit(\"loanbook already has items; seed only an empty one\")", "note": "Recusa mexer num banco que já tem itens. Um script de dados que roda por engano num banco real é como dados de demonstração acabam misturados com empréstimos de verdade."}, {"code": "    with db:\n        db.executemany(\"INSERT INTO items (name) VALUES (?)\", [(n,) for n in ITEMS])\n    ids = {r[\"name\"]: r[\"id\"] for r in db.execute(\"SELECT id, name FROM items\")}\n    for name, borrower, ago in LOANS:\n        app.lend(db, ids[name], borrower, date.today() - timedelta(days=ago))\n    print(f\"seeded {len(ITEMS)} items, {len(LOANS)} of them out\")", "note": "Os itens entram numa transação; os empréstimos passam por `lend`. Termina dizendo o que fez, numa linha."}]}
```

Rodado num banco vazio, produz uma semana que qualquer sala de TI reconheceria:

```
ana@laptop:~/loanbook$ python3 seed.py
seeded 8 items, 4 of them out
ana@laptop:~/loanbook$ sqlite3 -header -column loanbook.db "SELECT i.name, l.borrower, l.lent_on, l.due_on FROM items i LEFT JOIN loans l ON l.item_id = i.id AND l.returned_on IS NULL ORDER BY i.name"
name                borrower       lent_on     due_on    
------------------  -------------  ----------  ----------
Conference speaker                                       
Document camera     Dora Okafor    2026-09-26  2026-10-03
HDMI adapter A                                           
Laptop 03           Carlos Mendes  2026-09-18  2026-09-25
Laptop 07                                                
Projector 1                                              
Projector 2         Beatriz Nunes  2026-09-25  2026-10-02
Tripod              Eduardo Lins   2026-09-23  2026-09-30
```

Oito itens, quatro fora, e **cada empréstimo escolhido para mostrar algo**: o Laptop 03 saiu há nove dias,
então está atrasado; os outros três vencem em dias diferentes, então a lista não é uniforme; quatro itens
estão disponíveis, então o formulário *Lend* aparece também. Todo estado que a página tem está na tela ao
mesmo tempo. Rode de novo e ele recusa, como a quarta parte diz que deve:

```
ana@laptop:~/loanbook$ python3 seed.py
loanbook already has items; seed only an empty one
```

Três propriedades valem ser copiadas para qualquer script de dados. **Datas relativas**: um script com
`2026-06-24` escrito nele fica atrasado meses depois, e a demonstração muda de sentido sozinha. **Pela
aplicação, não por fora dela**: chamar `lend` quer dizer que o script não consegue criar um estado que as
regras proíbem. **Recusar rodar duas vezes**: o único erro que um script de dados nunca pode cometer é
misturar empréstimos inventados com reais.
