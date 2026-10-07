---
title: Memcached ou Redis
version: 1
---

Os dois guardam valores na memória sob chaves, os dois despejam, os dois respondem bem abaixo de um
milissegundo no loopback. Onde diferem é em tudo em volta disso:

| | Memcached | Redis |
|---|---|---|
| valores | bytes, até 1 MB por padrão | strings, hashes, listas, conjuntos, conjuntos ordenados e mais |
| threads | várias threads de trabalho | os comandos rodam um por vez |
| com a memória cheia | despeja, o menos usado recentemente por classe de slab | o que o `maxmemory-policy` disser; o Ubuntu recusa gravações |
| depois de um reinício | vazio | o que o RDB ou o AOF guardaram |
| vários servidores | o cliente espalha as chaves por hash | o cliente, ou o Redis Cluster |
| mudanças atômicas | `incr`, `decr`, `add`, `cas` | todo comando, mais `MULTI` e scripts |
| controle de acesso | o endereço em que escuta; um arquivo de senha opcional | o endereço, o protected mode, usuários de ACL |

**O Memcached serve para um cache puro de objetos inteiros.** Fragmentos renderizados, registros
serializados, os resultados de consultas caras: valores gravados inteiros, lidos inteiros, e que
ninguém sente falta quando somem. Numa máquina com muitos núcleos e bastante memória, as threads dele
fazem um servidor dar conta do trabalho que o Redis espalharia por vários processos.

**O Redis serve quando o cache precisa ser mais que um dicionário**: um ranking mantido em ordem, um
contador por campo, uma lista de itens recentes aparada a cada inserção, um tempo de vida por chave que
ele sabe informar. Ele também serve quando o Redis já roda para outra coisa, porque um segundo sistema
tem um custo próprio: mais um serviço para atualizar, vigiar e proteger.

As duas próximas aulas usam o Redis, pelos comandos que faltam ao Memcached. Todo padrão delas ainda
funciona sobre o Memcached, com `add` onde elas pegam um lock e `cas` onde conferem o que está lá antes
de gravar.
