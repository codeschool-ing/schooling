---
title: Listas para a ordem, sets para a pertinência
version: 1
---

Uma lista e um set guardam várias strings sob uma chave, e respondem a perguntas opostas. **Uma
lista lembra a ordem e aceita repetições; um set esquece a ordem e recusa repetições.** Escolher o
errado aparece como uma caixa de "vistos recentemente" que mostra o mesmo teclado três vezes, ou uma
busca por etiqueta que precisa ler todos os produtos.

## "Vistos recentemente": uma lista com tamanho

Cada página de produto que a Ana abre é empurrada para a esquerda da lista dela, então a mais nova
fica primeiro. Ela abriu o monitor, depois o teclado, o mouse, o cabo e o teclado de novo:

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> LPUSH viewed:ana MN-330
(integer) 1
127.0.0.1:6379> LPUSH viewed:ana KB-101 MS-204 CB-012 KB-101
(integer) 5
127.0.0.1:6379> LRANGE viewed:ana 0 -1
1) "KB-101"
2) "CB-012"
3) "MS-204"
4) "KB-101"
5) "MN-330"
```

`LRANGE … 0 -1` lê a lista inteira, da mais nova para a mais antiga, e o teclado aparece duas vezes.
Para uma caixa de "vistos recentemente" isso está errado. Então, antes de empurrar um produto, a loja
remove qualquer cópia anterior dele e, depois de empurrar, corta a lista nos três que a página mostra:

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> LREM viewed:ana 0 KB-101
(integer) 2
127.0.0.1:6379> LPUSH viewed:ana KB-101
(integer) 4
127.0.0.1:6379> LTRIM viewed:ana 0 2
OK
127.0.0.1:6379> LRANGE viewed:ana 0 -1
1) "KB-101"
2) "CB-012"
3) "MS-204"
```

`LREM … 0 KB-101` removeu as duas cópias (`2`), o push pôs uma de volta na frente e `LTRIM … 0 2`
manteve as posições de 0 a 2 e descartou o resto. **Depois de cada visualização a lista volta a ter
três entradas**, por mais páginas que a Ana abra, e é isso que torna viável uma lista por cliente para
um milhão de clientes.

Os três comandos são separados, então duas visualizações no mesmo instante poderiam intercalá-los.
Para esta caixa o pior resultado é um item repetido durante um carregamento de página, e a loja
aceita isso. Onde não é aceitável, `MULTI` e `EXEC` mandam os três como uma única transação.

## Uma lista não é uma fila confiável

Uma lista também é a fila óbvia: a loja empurra uma tarefa, um worker a retira.

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> LPUSH jobs:email order-1001
(integer) 1
127.0.0.1:6379> RPOP jobs:email
"order-1001"
127.0.0.1:6379> LLEN jobs:email
(integer) 0
```

O `RPOP` entregou a tarefa e **a removeu do Redis no mesmo passo**. Se o worker cair antes de o
e-mail sair, a tarefa não está em lugar nenhum: nem na lista, nem em outro canto, e o `LLEN` responde
`0` como se tudo estivesse bem. O Redis tem um contorno baseado em listas, o `LMOVE`, que move a
tarefa para uma segunda lista de "em andamento" em vez de apagá-la, e aí a aplicação precisa limpar
essa lista por conta própria. A estrutura feita para esse problema é o stream, duas seções adiante.

## Etiquetas: um set por etiqueta

Um set responde "isto é membro?" e "o que estes têm em comum?" sem a aplicação ler nada de que não
precise. Um set por etiqueta, com códigos de produto:

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> SADD tag:office KB-101 MS-204 MN-330 CB-012
(integer) 4
127.0.0.1:6379> SADD tag:usb-c CB-012 MN-330
(integer) 2
127.0.0.1:6379> SADD tag:wireless MS-204
(integer) 1
127.0.0.1:6379> SISMEMBER tag:wireless KB-101
(integer) 0
127.0.0.1:6379> SINTER tag:office tag:usb-c
1) "CB-012"
2) "MN-330"
127.0.0.1:6379> SADD tag:usb-c CB-012
(integer) 0
127.0.0.1:6379> SCARD tag:usb-c
(integer) 2
```

O `SISMEMBER` faz uma pergunta sobre um produto e responde `0` ou `1`. O `SINTER` cruza duas
etiquetas no servidor: os produtos marcados ao mesmo tempo com `office` e `usb-c`. E o segundo `SADD`
de `CB-012` respondeu `0`: ele já estava lá, então nada foi acrescentado e o `SCARD` continua
contando dois. Um set não comporta repetição, que é a propriedade que a lista de "vistos
recentemente" teve de imitar com o `LREM`.

## Uma thread, e o comando que a trava

Cada comando acima mexeu num punhado de membros. **O Redis executa um comando de cada vez, numa
única thread**, que é o que tornou o `INCR` seguro duas seções atrás, e isso tem um custo: um comando
não é interrompido para deixar outros rodarem. `SMEMBERS` num set de um milhão de membros, `SINTER` de
dois sets assim, `LRANGE … 0 -1` numa lista que ninguém cortou, `HGETALL` num hash com todos os
clientes dentro: cada um percorre a chave inteira enquanto todos os outros clientes esperam.

A documentação do Redis dá a complexidade de cada comando, e vale lê-la antes de usar um comando numa
chave que cresce: `SISMEMBER` é O(1) qualquer que seja o tamanho do set, `SMEMBERS` é O(N). Uma chave
que cresce sem limite é chamada de **big key**, e achá-la antes que cause uma parada faz parte de
vigiar o Redis, o assunto da aula 20.
