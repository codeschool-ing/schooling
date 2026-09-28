---
title: O que teste teste diz
version: 1
---

Aqui está o loanbook do jeito que fica depois do tipo mais comum de teste manual: alguns itens acrescentados
com pressa, e um empréstimo para o primeiro nome que veio à cabeça:

```
ana@laptop:~/loanbook$ python3 app.py add test; python3 app.py add asdf; python3 app.py add "item 3"
added test
added asdf
added item 3
ana@laptop:~/loanbook$ sqlite3 loanbook.db "INSERT INTO loans (item_id, borrower, lent_on, due_on) VALUES (2, 'test test', date('now'), date('now', '+7 days'))"
ana@laptop:~/loanbook$ sqlite3 -header -column loanbook.db 'SELECT i.name, l.borrower FROM items i LEFT JOIN loans l ON l.item_id = i.id'
name    borrower 
------  ---------
test             
asdf    test test
item 3           
```

Nada aqui está quebrado, e tudo aqui está errado para uma demonstração. **Uma captura de tela disto não mostra
nada**: não há empréstimo atrasado, nem segundo empréstimo recusado, nem ideia do que a página faz. **Quem
avalia e lê isto aprende que o projeto nunca foi usado como os usuários usariam.** E esconde problemas de
verdade: uma lista de três itens nunca mostra como a página se comporta com quarenta, ou com um nome de mais
de uma palavra.

A saída não é digitar com mais cuidado a cada vez. É escrever os dados uma vez, como código, para a mesma
semana crível aparecer toda vez que o projeto é montado: na sua máquina, no servidor da aula 15, na captura
de tela e no vídeo. Esse código é um **script de dados de exemplo** (*seed*).
