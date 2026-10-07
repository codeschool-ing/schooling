---
title: Strings, contadores e um lock
version: 1
---

O `redis-cli` manda um comando e imprime a resposta. O tipo mais simples é a **string**, e uma chave é
qualquer nome que você quiser; a convenção são palavras separadas por dois-pontos, do geral para o
específico, `views:book:2`, para chaves relacionadas ficarem juntas em ordem e em varreduras.

```
ana@web:~$ redis-cli SET greeting "Bem-vindo à Ipê Livros"
OK
ana@web:~$ redis-cli GET greeting
Bem-vindo à Ipê Livros
ana@web:~$ redis-cli GET nothing-here
```

Uma chave que não existe responde com nada, que o `redis-cli` imprime como uma linha vazia. Strings são
bytes, então os acentos voltaram exatamente como entraram.

## Contadores

```
ana@web:~$ redis-cli SET views:book:2 0 && redis-cli INCR views:book:2 && redis-cli INCRBY views:book:2 10
OK
1
11
```

**O `INCR` lê, soma e grava num passo só.** Uma aplicação que fizesse `GET`, somasse um no próprio código
e fizesse `SET` perderia incrementos sempre que duas cópias dela fizessem isso no mesmo instante; o
`INCR` não perde, porque o Redis roda um comando por vez. O `INCRBY` soma qualquer valor, e os dois criam
a chave com 0 se ela não existir. Um contador de visualizações, um limite de taxa, um número sequencial
de pedidos: cada um é um `INCR`.

## Gravar só se não existir

```
ana@web:~$ redis-cli SET lock:report ana NX; redis-cli SET lock:report bruno NX; redis-cli GET lock:report
OK

ana
ana@web:~$ redis-cli TYPE views:book:2; redis-cli OBJECT ENCODING views:book:2
string
int
```

`NX` quer dizer "só se a chave não existir". O primeiro `SET` gravou `ana` e respondeu `OK`; o segundo
achou a chave lá e não gravou nada, respondendo com nada. Isso é um **lock** num comando: o processo que
recebe `OK` o segura, e os outros sabem que não o têm. A aula 11 usa exatamente isso para garantir que
só uma requisição reconstrua um valor vencido.

A última linha lembra que os tipos são de verdade. `views:book:2` é uma string cujo conteúdo é um número,
e o Redis o guarda como inteiro, `int`, que ocupa menos memória que o texto.
