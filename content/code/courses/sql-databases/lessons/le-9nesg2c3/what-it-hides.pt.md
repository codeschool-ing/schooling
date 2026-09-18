---
title: Cinco coisas que o mapeador faz e o código não diz
version: 1
---

O trabalho de um mapeador é fazer o banco sumir do código. Ele consegue, e cada coisa que esconde
é um lugar em que a instrução que o servidor roda não é a que um leitor chutaria. O N+1 é a
famosa. Estas são as outras cinco, e cada uma tem uma aula por trás.

## 1. Ele seleciona toda coluna

`Customer.find(42)` monta um objeto cliente, e o objeto tem todo campo, então a instrução é
`SELECT id, name, email, city, created_at, …` — toda coluna, sempre. A aula 10 tinha o número: a
diferença entre um index-only scan e um que busca toda linha era uma coluna na lista do `SELECT`.
Um modelo com uma coluna `bio` de dez kilobytes busca dez kilobytes por linha numa tela que mostra
nomes.

Todo ORM tem um jeito de pedir menos — `only()`, `select()`, `defer()`, uma projeção numa
estrutura simples — e o hábito é o que a aula 4 começou: nomeie as colunas, nas consultas que
rodam com frequência.

## 2. Ele manda toda coluna num insert também

A aula 3 disse e prometeu o mecanismo aqui. Um `DEFAULT` dispara quando a coluna está **ausente**
do insert. Um mapeador montando um `INSERT` a partir de um objeto manda todo campo que o objeto
tem, e um campo que o código nunca definiu não está ausente — é `NULL`:

```
shop=# CREATE TABLE notes (id integer PRIMARY KEY, body text NOT NULL, created_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE

shop=# INSERT INTO notes (id, body) VALUES (1, 'from the database');
INSERT 0 1

shop=# INSERT INTO notes (id, body, created_at) VALUES (2, 'from the application', NULL);
ERROR:  null value in column "created_at" of relation "notes" violates not-null constraint
DETAIL:  Failing row contains (2, from the application, null).
```

O primeiro insert deixou `created_at` de fora e o banco preencheu. O segundo a nomeou e mandou
`NULL`, que é um valor, e uma coluna `NOT NULL` recusou. Sem a restrição a linha seria guardada sem
timestamp, em silêncio, numa tabela cuja definição diz que ela tem um.

Alguns mapeadores sabem quais campos foram definidos e omitem o resto; alguns mandam tudo; alguns
têm uma marca por coluna para dizer *deixe o banco cuidar desta*. Qual é o caso do seu é um fato
sobre ele que decide se um default do banco algum dia roda — e um default que nunca roda é uma
regra que parece aplicada e não é. A tabela `notes` acima, com uma linha de cada lado:

```
shop=# INSERT INTO notes (id, body, created_at) VALUES (2, 'from the application', '2020-01-01');
INSERT 0 1

shop=# SELECT id, body, created_at FROM notes ORDER BY id;
 id |         body         |          created_at           
----+----------------------+-------------------------------
  1 | from the database    | 2026-09-17 23:31:57.290649+00
  2 | from the application | 2020-01-01 00:00:00+00
(2 rows)
```

## 3. Ele carrega na ordem em que a tabela estiver

`Customer.all()` sem ordenação emite `SELECT … FROM customers` sem `ORDER BY`, e a aula 4 disse o
que isso significa: a ordem que o banco achou conveniente, que muda depois de um update, de um
vacuum ou de um plano diferente. Uma lista numa tela que fica estável por meses e depois embaralha
depois de um deploy é isso, e o deploy não fez nada além de mudar o plano.

Alguns ORMs acrescentam um `ORDER BY` pela chave primária ao paginar, porque um `LIMIT` sem ordem
é uma amostra aleatória diferente por página. Alguns não, e a página que mostra uma linha duas
vezes e pula outra é o sintoma. Diga a ordem.

## 4. Ele mantém uma transação aberta por mais tempo do que você queria

Uma sessão de data mapper é uma **unidade de trabalho**: ela recolhe as mudanças feitas nos
objetos e as escreve no fim, numa transação só. É um bom projeto e tem uma consequência que a aula
8 descreveu: a transação fica aberta da primeira leitura ao commit, segurando o que uma transação
segura.

A forma usual do estrago é um handler de requisição que carrega um pedido, chama um provedor de
pagamento pela rede, espera dois segundos, e então salva. Por esses dois segundos a transação está
aberta, os bloqueios dela estão mantidos, e o `VACUUM` não consegue recuperar nada mais novo que
ela. Um handler não é nada; mil por minuto é um banco enchendo devagar de versões de linha que
ninguém consegue limpar.

Duas regras. **Faça a chamada de rede fora da transação**, e abra-a depois para a escrita. E
conheça o padrão do seu framework, porque ele decide se um handler lento está segurando um
bloqueio: o Django abre uma transação por requisição só se você pedir (`ATOMIC_REQUESTS`), o
Rails não envolve uma requisição, e a sessão do SQLAlchemy começa uma no primeiro uso.

## 5. Ele guarda um objeto em cache e lhe mostra o velho

Uma sessão lembra os objetos que carregou — o identity map — para que buscar o cliente 42 duas
vezes devolva o mesmo objeto, e uma mudança feita por uma referência seja visível pela outra.
Útil, e significa que a segunda busca pode não rodar instrução nenhuma: a sessão responde da
memória, com a linha como estava quando foi carregada, diga o banco o que disser agora.

Isso é o nível de isolamento da aula 8, reimplementado uma camada acima e sem o vocabulário.
Dentro de uma requisição é o que você quer; numa sessão de vida longa — um worker de fundo que
segura uma sessão por uma hora — é um worker lendo dado de uma hora atrás e acreditando que é
atual. Sessões curtas, uma por unidade de trabalho, é a regra, e é a mesma regra da transação pela
mesma razão.

## O que elas têm em comum

Cada uma das cinco é o mapeador fazendo exatamente o que documenta, e cada uma é visível num
lugar: a instrução que o servidor recebeu. Toda coluna, `NULL` onde se esperava um default, sem
`ORDER BY`, um `BEGIN` sem `COMMIT` por dois segundos, uma busca que nunca chegou. O log mostra as
cinco, e é por isso que a segunda seção disse para deixá-lo ligado.
