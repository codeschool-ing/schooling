---
title: Os cabeçalhos que decidem
version: 1
---

**O `Cache-Control` diz por quanto tempo uma cópia vale e quem pode guardá-la**; o `ETag` e o
`Last-Modified` dão a uma cópia algo com que ser conferida. Cada um é um cabeçalho de resposta do
servidor, e as conferências são cabeçalhos de requisição do navegador.

## Cache-Control

| diretiva | o que diz |
|---|---|
| `max-age=N` | a cópia vale por N segundos sem perguntar |
| `s-maxage=N` | o mesmo, só para caches compartilhados; ali ela passa por cima do `max-age` |
| `no-cache` | guarde, mas pergunte toda vez antes de usar; apesar do nome, é uma regra sobre conferir, não sobre guardar |
| `no-store` | não guarde em lugar nenhum |
| `public` | qualquer cache pode guardar, inclusive um compartilhado |
| `private` | só o navegador do próprio visitante pode guardar |
| `immutable` | o arquivo nunca vai mudar neste endereço, então nem confira quando a pessoa recarregar |
| `stale-while-revalidate=N` | por N segundos depois de deixar de ser fresca, uma cópia vencida pode ser usada enquanto uma nova é buscada |

## Conferindo uma cópia

**Um `ETag` é um nome para uma versão de uma resposta**, escolhido pelo servidor, em geral um hash do corpo.
Um navegador que tem uma cópia o manda de volta como `If-None-Match`, e um servidor cuja versão atual tem o
mesmo ETag responde `304 Not Modified` sem corpo. O `Last-Modified` e o `If-Modified-Since` fazem o mesmo
com uma data, o que é mais grosseiro, um segundo no máximo, e errado para qualquer coisa gerada por
requisição.

## Vary

**O `Vary` nomeia os cabeçalhos de requisição de que uma resposta depende.** O planner já manda
`vary: accept-encoding` desde a aula 6, porque o mesmo endereço responde com gzip a um navegador que pede e
sem a um que não pede. Um cache compartilhado guarda uma cópia por valor dos cabeçalhos nomeados; sem o
`Vary`, ele poderia entregar a cópia comprimida a um cliente que não consegue lê-la.

## Age

**Um cache compartilhado acrescenta o `Age`**: quantos segundos a cópia que está mandando está guardada nele.
É como um navegador, ou uma pessoa com `curl`, distingue uma cópia de uma CDN de uma que acabou de sair do
servidor, e a seção "Uma CDN só sua" o lê.
