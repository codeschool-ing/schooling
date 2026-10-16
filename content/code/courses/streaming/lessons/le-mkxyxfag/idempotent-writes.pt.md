---
title: Gravações que podem ser repetidas
version: 1
---

**Uma gravação é idempotente quando fazê-la duas vezes deixa o mesmo resultado que fazê-la uma
vez.** A lição 7 terminou com um consumidor que entrega toda venda pelo menos uma vez, e portanto
às vezes duas. Se toda gravação que ele faz é idempotente, a segunda entrega não muda nada e a
duplicata é inofensiva, sem ninguém precisar detectá-la.

A diferença está no formato do comando, não no banco:

| idempotente | não idempotente |
|---|---|
| `SET qty = 98` | `SET qty = qty - 2` |
| inserir a venda **pela chave do id dela**, ignorando uma que já está lá | inserir a venda com um id de linha novo a cada vez |
| pôr um arquivo num nome fixo | acrescentar uma linha a um arquivo |
| `DELETE` da reserva do pedido 42 | diminuir uma contagem de reservas |

A coluna da esquerda **define um valor**; a da direita soma ao valor que está lá. Um estoque
mantido subtraindo cada venda é o código mais natural que alguém escreve, e o mais frágil sob pelo
menos uma vez.

## No SQLite

O destino nesta lição é o SQLite, um banco de dados num único arquivo, que já vem com o Python. O
Python 3.12 também roda um comando SQL de cada vez a partir do shell com `python -m sqlite3 ARQUIVO
"SQL"`, que é o que as transcrições abaixo usam; ele imprime cada linha como uma tupla. Primeiro, o
contador que soma, com a mesma venda de duas cópias do `bk-04` aplicada duas vezes:

```
ubuntu@stream:~/work$ python -m sqlite3 demo.db "CREATE TABLE sold (book TEXT PRIMARY KEY, qty INTEGER NOT NULL)"
ubuntu@stream:~/work$ python -m sqlite3 demo.db "INSERT INTO sold VALUES ('bk-04', 0)"
ubuntu@stream:~/work$ python -m sqlite3 demo.db "UPDATE sold SET qty = qty + 2 WHERE book = 'bk-04'"
ubuntu@stream:~/work$ python -m sqlite3 demo.db "UPDATE sold SET qty = qty + 2 WHERE book = 'bk-04'"
ubuntu@stream:~/work$ python -m sqlite3 demo.db "SELECT * FROM sold"
('bk-04', 4)
```

**Duas entregas de uma venda de duas cópias, e a tabela diz quatro.** Nada no segundo comando
conseguia saber que era uma repetição; ele soma ao que estiver lá.

Agora o outro formato. As próprias vendas são guardadas, **pela chave do id da venda**, e o número
vendido é calculado a partir delas. `ON CONFLICT (sale) DO NOTHING` transforma um segundo insert do
mesmo id em nada; o SQLite chama essa cláusula de **upsert**, faça ela nada ou atualize:

```
ubuntu@stream:~/work$ python -m sqlite3 demo.db "CREATE TABLE sales (sale TEXT PRIMARY KEY, book TEXT, qty INTEGER)"
ubuntu@stream:~/work$ python -m sqlite3 demo.db "INSERT INTO sales VALUES ('rec-000007', 'bk-04', 2) ON CONFLICT (sale) DO NOTHING"
ubuntu@stream:~/work$ python -m sqlite3 demo.db "INSERT INTO sales VALUES ('rec-000007', 'bk-04', 2) ON CONFLICT (sale) DO NOTHING"
ubuntu@stream:~/work$ python -m sqlite3 demo.db "SELECT book, sum(qty) FROM sales GROUP BY book"
('bk-04', 2)
```

O segundo insert bate na chave primária e não faz nada, e **o total continua em dois**. A duplicata
foi inofensiva sem ninguém procurá-la, porque a gravação tinha um formato em que uma segunda cópia
não tem para onde ir.

## O porém

Guardar fatos e calcular totais a partir deles é um desenho robusto, e nem sempre está disponível.
Um estoque que precisa ser lido mil vezes por segundo não vai ser um `SUM` sobre toda venda já
feita; a API de um provedor de pagamento que cobra um cartão não é uma tabela com chave primária.
**Tornar a gravação idempotente funciona quando você controla o formato dela**, e quando não
controla, o consumidor precisa lembrar o que já fez. Essa é a próxima seção, e ela acaba sendo a
mesma ideia um passo adiante: uma tabela pela chave do id da venda, mas guardando só os ids.
