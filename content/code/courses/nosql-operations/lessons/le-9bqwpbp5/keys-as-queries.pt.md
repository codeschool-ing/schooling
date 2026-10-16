---
title: A chave é a consulta, no Redis
version: 1
---

O Redis leva o método até o fim. Não há partição a nomear nem campo a pesquisar: **a única pergunta
que o Redis responde é "o que está sob esta chave", então projetar para o Redis é projetar nomes de
chave.** A linha 2 da lista, a cesta, é a escrita mais frequente da loja, e a aplicação sabe uma
coisa quando pergunta: quem é o cliente.

## Um nome montado a partir do que a aplicação sabe

Então a chave da cesta é montada a partir disso: `cart:` e o e-mail da cliente. Um hash a guarda, um
campo por código de produto e a quantidade como valor:

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> HSET cart:ana@example.com CB-012 2 MS-204 1
(integer) 2
127.0.0.1:6379> HINCRBY cart:ana@example.com CB-012 1
(integer) 3
127.0.0.1:6379> HGETALL cart:ana@example.com
1) "CB-012"
2) "3"
3) "MS-204"
4) "1"
127.0.0.1:6379> exit
```

Acrescentar um terceiro cabo foi um `HINCRBY` num campo, feito dentro do servidor num passo só, sem
ler a cesta antes. Ler a cesta foi um `HGETALL` numa chave que a aplicação montou a partir da sessão;
nada foi pesquisado. **Isso é uma consulta, nos termos do Redis**: a aplicação escreve a pergunta no
nome, e o servidor só precisa procurá-lo.

Os dois-pontos não significam nada para o Redis. São uma convenção, `tipo:id`, que deixa as pessoas
lerem uma chave e as ferramentas agruparem chaves pelo prefixo, e vale segui-la à risca, porque o
prefixo é a única estrutura que um espaço de chaves tem. `cart:ana@example.com`, `order:1001` e
`product:MS-204` dizem o que são; `ana`, `1001` e `MS-204` colidiriam no dia em que dois tipos de
coisa compartilhassem um id.

## Achando chaves por padrão, e o comando a não usar

Às vezes um operador precisa achar chaves em vez de nomear uma: toda cesta, digamos, para contá-las
ou limpá-las. O Redis de uma loja de verdade não guarda uma cesta só. Aqui ele também guarda um
milhão de chaves de sessão, gravadas por um gerador de uma linha ligado ao `redis-cli --pipe`, que
envia comandos sem esperar cada resposta:

```
ana@vm:~$ seq 1 1000000 | awk '{print "SET session:" $1 " x"}' | docker exec -i redis redis-cli --pipe
All data transferred. Waiting for the last reply...
Last reply received from server.
errors: 0, replies: 1000000
ana@vm:~$ docker exec redis redis-cli DBSIZE
1000001
```

Há dois jeitos de pedir toda chave que começa com `cart:`:

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> CONFIG RESETSTAT
OK
127.0.0.1:6379> KEYS cart:*
1) "cart:ana@example.com"
127.0.0.1:6379> SCAN 0 MATCH cart:* COUNT 1000
1) "512"
2) (empty array)
127.0.0.1:6379> exit
ana@vm:~$ docker exec redis redis-cli --scan --pattern 'cart:*' --count 1000
cart:ana@example.com
ana@vm:~$ docker exec redis redis-cli INFO commandstats | grep -E "keys|scan"
cmdstat_scan:calls=1001,usec=273243,usec_per_call=272.97,rejected_calls=0,failed_calls=0
cmdstat_keys:calls=1,usec=138837,usec_per_call=138837.00,rejected_calls=0,failed_calls=0
```

Os dois acharam a única cesta. O que custaram está nas duas últimas linhas, a contagem do próprio
servidor do tempo gasto em cada comando desde o `CONFIG RESETSTAT`:

- **`KEYS cart:*` foi uma chamada de 138.837 microssegundos**, cerca de 139 ms, para percorrer as
  1.000.001 chaves. O Redis roda um comando por vez, então durante esses 139 ms todo outro cliente
  esperou: toda atualização de cesta e toda página que lê uma sessão.
- **`SCAN` foram 1.001 chamadas de 273 microssegundos em média.** Cada chamada percorre uma fatia do
  espaço de chaves e devolve um cursor de onde continuar; a chamada manual mostra um, `512`, e uma
  lista vazia, porque aquela fatia não tinha cesta. O `redis-cli --scan` segue o cursor até ele
  voltar a `0`.

O `SCAN` fez mais trabalho no total, cerca de 273 ms contra 139, e tudo bem. O que importa para os
outros clientes é a **maior pausa isolada**, e a do SCAN foi de algumas centenas de microssegundos
entre chamadas que deixam todo mundo passar. Um milhão de chaves é um Redis pequeno; com cem milhões,
o `KEYS` para o servidor por muitos segundos, tempo bastante para uma verificação de saúde o declarar
morto.

Então o `KEYS` é coisa de notebook. Em produção ele costuma ser renomeado ou desativado na
configuração, e toda ferramenta que precisa percorrer chaves usa o `SCAN`. Nenhum dos dois é uma
consulta no sentido do resto desta aula: os dois são varreduras, e um projeto que precisa de uma a
cada visualização de página está com uma chave faltando. Se a loja precisasse de "toda cesta" com
frequência, ela manteria **um set com as chaves das cestas** ao lado delas, atualizado a cada cesta,
para que a pergunta tenha uma chave própria. A aula 12 tem as estruturas para isso.
