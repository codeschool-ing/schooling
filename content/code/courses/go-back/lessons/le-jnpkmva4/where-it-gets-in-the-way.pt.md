---
title: Onde o framework atrapalha
version: 1
---

Os custos da seção 04 são pagos por todos que usam um framework, no dia em que começam. Alguns
custos só chegam depois, num momento específico, e vale conhecê-los pelo nome, porque cada um parece
um bug no seu código quando acontece.

## Quando o padrão dele não é decisão sua

A seção 07 da aula 4 dispôs seis perguntas e como cada framework as respondeu, e a maior parte das
diferenças eram padrões: **o Gin respondendo 404 a um método errado, o Echo escondendo o motivo de
um 400, o Beego mandando uma página HTML para um cliente JSON, o Gin confiando no
`X-Forwarded-For` de qualquer um.** Cada uma é uma escolha razoável para alguém. Nenhuma foi sua, e
você descobre cada uma no dia em que um cliente ou um auditor descobre.

A biblioteca padrão também tem padrões; a seção 08 da aula 1 gastou uma seção no que mais importa,
os timeouts que faltam. A diferença é o tamanho da superfície. **O `net/http` faz um punhado de
escolhas e a documentação de um pacote as lista**; um framework faz centenas, espalhadas pelo
binding, pelo roteamento, pelo tratamento de erros, pelo log e por cada middleware que ele traz.

## Quando o handler dele não é um `http.Handler`

Os quatro middlewares da aula 2 envolvem qualquer `http.Handler`. Eles funcionam sem mudança em
volta do engine do Gin, do Echo e do Beego, e em volta de um roteador chi, porque todos esses são
`http.Handler` no topo. **Eles não funcionam dentro de uma rota do Gin**, entre o roteador e um
handler, porque ali um handler é um `gin.HandlerFunc` e um middleware tem o formato do Gin; e não
funcionam em lugar nenhum do Fiber, que nem é `net/http`. O ecossistema Go está cheio de middleware
escrito no formato padrão, para tracing, métricas, autenticação e limite de taxa, e cada framework
que sai desse formato precisa da própria versão de cada um, ou de um adaptador.

O mesmo vale para os testes. **O `httptest`, que a aula 15 usa, dirige qualquer `http.Handler`** com
uma requisição falsa e um gravador, e não precisa de mais nada. O Fiber precisa do próprio
`app.Test`.

## Quando o contexto dele sobrevive à requisição

O contexto de um framework carrega a requisição e a resposta, e frameworks reaproveitam esses
objetos para ir mais rápido. A documentação do Gin diz que um handler que inicia uma goroutine
precisa entregar a ela uma cópia do contexto, `c.Copy()`, e nunca o original, porque o original é
reciclado para outra requisição assim que o handler retorna. O Fiber diz o mesmo de toda string lida
do `Ctx` dele, como mostrou a seção 05 da aula 4. **Um programa que quebra essa regra funciona em
todo teste e falha sob carga**, com um valor da requisição de um cliente aparecendo na de outro, que
é o pior tipo de bug de achar.

O `net/http` dá ao handler um `*http.Request` comum, e `r.Context()` é um `context.Context` comum,
o que a aula 12 do `go-concurrency` ensinou. Nada é reciclado pelas suas costas.

## Quando ele esconde o HTTP

`c.JSON(422, value)` é mais curto que o `writeJSON` da aula 3, e esconde a ordem de status,
cabeçalhos e corpo de que tratou a seção 07 da aula 1. Tudo bem até um cabeçalho precisar ser
definido depois que um middleware já escreveu, ou uma resposta precisar ser transmitida aos poucos,
como faz a aula 13, e aí o helper do framework tem de ser contornado e o HTTP entendido de qualquer
jeito. **Um framework não elimina a necessidade de saber HTTP; ele adia o dia em que você descobre
que precisa.**
