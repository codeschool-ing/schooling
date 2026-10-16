---
title: Versões, e a atualização que chega tarde
version: 1
---

**Quando os eventos são atualizações da mesma coisa, uma duplicata não é o único perigo: uma
atualização mais antiga pode chegar depois de uma mais nova, e gravar o que chegar por último põe o
valor antigo de volta.** Essa é a armadilha do *último a escrever vence*. "Último" quer dizer último a
chegar ao banco, que não é o mesmo que último a acontecer.

Dentro de uma partição de um tópico, o Kafka mantém a ordem por chave, a promessa da lição 3, e um
único consumidor aplica as atualizações na ordem em que foram gravadas. A ordem quebra nos lugares
que as lições 3 e 7 apontaram: uma chave que mudou de partição quando partições foram acrescentadas,
uma releitura de um backup antigo por cima de dados mais novos, dois tópicos alimentando a mesma
tabela, um produtor que tentou de novo sem idempotência. Cada um deles pode entregar ao destino a
versão 2 de um preço depois da versão 3.

## Guarde a versão mais alta

A cura é cada atualização **carregar uma versão**, dada por quem é dono da coisa sendo atualizada, e o
destino aplicar uma atualização só se a versão dela for maior que a guardada. A comparação pertence à
própria gravação, para que dois consumidores disputando a mesma linha não passem os dois por uma
verificação feita antes. No SQLite é um `WHERE` na cláusula de conflito.

Três atualizações do preço do `bk-01`, versões 1 e 3 e depois uma versão 2 atrasada:

```
ubuntu@stream:~/work$ python -m sqlite3 prices.db "CREATE TABLE price (book TEXT PRIMARY KEY, cents INTEGER, version INTEGER)"
ubuntu@stream:~/work$ python -m sqlite3 prices.db "INSERT INTO price VALUES ('bk-01', 3990, 1) ON CONFLICT (book) DO UPDATE SET cents = excluded.cents, version = excluded.version WHERE excluded.version > price.version"
ubuntu@stream:~/work$ python -m sqlite3 prices.db "INSERT INTO price VALUES ('bk-01', 4490, 3) ON CONFLICT (book) DO UPDATE SET cents = excluded.cents, version = excluded.version WHERE excluded.version > price.version"
ubuntu@stream:~/work$ python -m sqlite3 prices.db "INSERT INTO price VALUES ('bk-01', 4290, 2) ON CONFLICT (book) DO UPDATE SET cents = excluded.cents, version = excluded.version WHERE excluded.version > price.version"
ubuntu@stream:~/work$ python -m sqlite3 prices.db "SELECT * FROM price"
('bk-01', 4490, 3)
```

A versão 1 foi gravada, a versão 3 a substituiu, e **a versão 2, chegando por último, não mudou
nada**: o preço é 4490 na versão 3. Sem o `WHERE`, seria 4290, um preço que alguém já tinha mudado.

O mesmo comando também é **idempotente**: reaplicar a versão 3 encontra a versão 3 guardada, a condição
é falsa, e nada muda. Um upsert com versão responde a duplicatas e a reordenação de uma vez, e é por
isso que ele é o formato usual de um destino que guarda o estado atual das coisas, e por isso que os
eventos de mudança da lição 14 carregam uma posição do log do banco que pode servir de versão.

## De onde vem a versão

| origem da versão | é sólida quando |
|---|---|
| um contador que o dono incrementa a cada mudança | um sistema é dono da entidade; esta é a mais forte |
| a posição da mudança no log do banco | os eventos vêm do log de um banco, como na lição 14 |
| o timestamp do evento | os relógios concordam com precisão maior que o intervalo entre duas atualizações, o que a lição 9 diz para não supor |
| o offset do Kafka | todas as atualizações da entidade passam por uma partição e nunca são relidas de outro lugar |

**Um timestamp é a escolha tentadora e a fraca.** Duas atualizações no mesmo milissegundo empatam, e
um caixa com o relógio dez minutos adiantado ganha toda discussão por dez minutos. A lição 9 é sobre
com que frequência os relógios discordam.
