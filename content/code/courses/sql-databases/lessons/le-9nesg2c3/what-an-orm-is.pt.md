---
title: O que um ORM é, e o que não é
version: 1
---

Toda aula até aqui foi escrita num prompt do `psql`. Quase nenhuma aplicação é. Uma aplicação é
escrita numa linguagem de programação, e a linguagem tem objetos, listas e métodos onde o banco
tem tabelas, linhas e instruções. Um **mapeador objeto-relacional** é a camada que traduz entre os
dois.

```
customer = Customer.find(42)          -- SELECT … FROM customers WHERE id = 42
customer.name = 'Ana'
customer.save()                       -- UPDATE customers SET name = 'Ana' WHERE id = 42
```

É essa a ideia inteira. Uma classe representa uma tabela, uma instância representa uma linha, e
uma chamada de método vira uma instrução. O bloco acima não é nenhum ORM em particular — cada um
tem a própria grafia — e a forma é a mesma em Django, Rails, Hibernate, SQLAlchemy, Entity
Framework e Prisma.

## O que ele compra para você

Quatro coisas, e vale a pena tê-las:

**Parâmetros, por padrão.** O ORM nunca cola um valor no texto de uma instrução; ele manda a
instrução e o valor separados. A seção sobre parâmetros diz por que essa é a linha mais importante
desta aula.

**Tipos que combinam.** Um `timestamptz` chega como o tipo de data da linguagem, um `numeric` como
decimal em vez de float, um `boolean` como booleano. O cuidado da aula 3 com tipos é preservado na
saída em vez de perdido na fronteira.

**As instruções óbvias escritas uma vez.** Buscar por chave primária, inserir uma linha, atualizar
as colunas que mudaram, apagar. Ninguém deveria escrever essas à mão quinhentas vezes, e uma
aplicação tem quinhentas delas.

**Migrações.** Um jeito de mudar o esquema que é versionado, repetível e amarrado ao código que
precisa dele, que é uma seção própria e é a segunda metade desta aula.

## O que ele não é

Um ORM não é um jeito de evitar saber SQL, e esta é a frase sobre a qual a aula é construída:

> **O ORM emite SQL. Tenha você escrito ou não, o banco roda uma instrução, planeja, e cobra por
> ela — e tudo das aulas 4 a 10 se aplica a essa instrução exatamente como se você a tivesse
> digitado.**

Um `ORDER BY` que falta falta seja um método que o deixou de fora ou você. Uma junção sem índice é
uma varredura esteja o laço no seu código ou no de uma biblioteca. O problema N+1, que é a seção
depois da próxima, é o caso mais claro: uma página que parece dez linhas de código comum roda
cinquenta e uma instruções, e nada nessas dez linhas diz isso.

Então a habilidade que esta aula ensina não é a API do ORM, que cada ORM documenta. É o hábito de
**saber o que ele emitiu**, e os três ou quatro lugares em que o que ele emite não é o que quem lê
o código chutaria.

## Duas formas de ORM

Elas diferem em onde mora o mapeamento, e a diferença decide como o resto desta aula se lê.

**Active Record.** O objeto é a linha. `customer.save()` escreve; `Customer.find(42)` lê uma. O
Rails nomeou o padrão e o ORM do Django, o Eloquent do Laravel e a maioria dos ORMs de linguagens
dinâmicas o seguem. Curto de escrever, e o objeto sabe do banco.

**Data Mapper.** O objeto é simples, e uma coisa à parte — uma sessão, uma unidade de trabalho, um
repositório — sabe como movê-lo de e para uma tabela. Hibernate, a camada ORM do SQLAlchemy,
Doctrine e Entity Framework têm essa forma. Mais coisa para montar, e o objeto não sabe que é
guardado.

Abaixo dos dois fica o **query builder**, que não é mapeador nenhum: ele compõe SQL a partir de
chamadas de método — `select('id').from('orders').where('total > ?', 100)` — e devolve linhas.
Knex, jOOQ, SQLAlchemy Core, os querysets crus do Django. É o meio honesto: a instrução continua
sendo sua, e continua parametrizada, indentada e componível. A última seção diz quando cada uma
das três é a camada certa.

## A moldura do resto

Duas metades. As seções dois a seis são sobre **ler** o que o ORM faz — ver o SQL dele, o N+1,
carregar de uma vez, parâmetros, e as coisas que ele esconde. As seções sete a nove são sobre
**escrever** o esquema por ele — migrações, quem é dono do esquema, e onde o ORM cabe afinal. As
duas metades se apoiam na mesma regra, e a aula 10 é onde olhar quando a regra é quebrada: meça o
que ele emitiu.
