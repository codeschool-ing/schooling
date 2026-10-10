---
title: O prefixo de cada linha
version: 1
---

Uma linha de log é um **prefixo** e uma **mensagem**. A mensagem é o que aconteceu; o prefixo é
quando, em que processo e para quem, e é a parte que torna uma linha encontrável uma semana depois.
Ele é definido por `log_line_prefix`, e o pacote do Ubuntu o configura com algo melhor que o padrão
do próprio PostgreSQL:

@@1@@

@@2@@

Cada escape com `%` é substituído em toda linha:

| escape | vira | na linha acima |
|---|---|---|
| `%m` | a hora, até o milissegundo, com o fuso | a data e o `-03` |
| `%p` | o id do processo, aqui entre `[ ]` | o backend que rodou o comando |
| `%q` | nada; encerra o prefixo para processos sem sessão | — |
| `%u` | o papel | `ana` |
| `%d` | o banco | `shop` |

**O `%q` é o esperto.** O checkpointer e os outros processos de fundo não têm usuário nem banco, e
sem `%q` as linhas deles levariam um `@` vazio. Com ele, tudo o que vem depois do `%q` fica de fora
para eles, então uma linha de checkpoint termina depois do id do processo. O id do processo é o que
amarra as linhas: o `ERROR` e o `STATEMENT` embaixo dele compartilham um, e o mesmo vale para tudo o
mais que aquela sessão escreveu.

A segunda linha existe por causa do `log_min_error_statement`, que é `error` por padrão: **todo
comando que falha é escrito depois do seu erro**, estejam os comandos sendo registrados ou não.
Muitas vezes é tudo de que um desenvolvedor precisa para reproduzir um bug, e é também o jeito como
uma senha digitada num comando que falhou acaba no log.

## Acrescentando a aplicação

Vale estender o prefixo numa direção: **qual programa mandou o comando**. O `%a` é o
`application_name` que o cliente declarou, que o psql preenche sozinho e que a maioria dos drivers
deixa a aplicação definir. Mudar o prefixo só precisa de um reload:

@@3@@

@@4@@

O próprio reload fica registrado, com o valor novo, e a linha do postmaster não tem usuário por
causa do `%q`. Num servidor compartilhado por uma aplicação web, um job em lote e uma ferramenta de
relatórios, o `%a` é a diferença entre *alguma sessão ficou lenta* e *a exportação da madrugada
ficou lenta*. Os outros escapes estão na documentação do `log_line_prefix`: `%h` acrescenta o
endereço do cliente, que vale a pena quando as conexões chegam pela rede, e `%x` o id da transação.

**Mantenha a hora primeiro e o formato estável.** Toda ferramenta que lê essas linhas, do `grep` a
um coletor de logs, é escrita contra o prefixo, e mudá-lo num servidor movimentado quebra o que quer
que o interprete.
