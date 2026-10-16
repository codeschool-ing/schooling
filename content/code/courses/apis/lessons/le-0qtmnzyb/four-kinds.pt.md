---
title: Quatro tipos de chamada
version: 1
---

**Um método gRPC é de um entre quatro tipos, e o que os separa é qual lado pode enviar mais de uma
mensagem.** A palavra `stream` na frente de um tipo de mensagem na linha `rpc` é toda a declaração.
Seja qual for o tipo, continua sendo **uma chamada**: um stream HTTP/2, um prazo e um status no fim.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 370\" role=\"img\" aria-label=\"Quatro tipos de chamada gRPC, cada um em duas faixas, o cliente em cima e o servidor embaixo, com o tempo correndo para a direita. Unária: uma mensagem desce, uma sobe, depois o status. Streaming do servidor: uma desce, várias sobem, depois o status. Streaming do cliente: várias descem, uma sobe, depois o status. Bidirecional: mensagens nos dois sentidos, intercaladas, depois o status.\"><defs><marker id=\"l04-calls-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"16\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">unária</text><text x=\"16\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">GetStock, Reserve</text><text x=\"196\" y=\"28\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">cliente</text><text x=\"196\" y=\"72\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">servidor</text><line x1=\"204\" y1=\"28\" x2=\"690\" y2=\"28\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></line><line x1=\"204\" y1=\"72\" x2=\"690\" y2=\"72\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></line><line x1=\"230\" y1=\"30\" x2=\"256\" y2=\"69\" stroke=\"var(--paper)\" stroke-width=\"1.4\" marker-end=\"url(#l04-calls-ah)\"></line><line x1=\"300\" y1=\"70\" x2=\"326\" y2=\"31\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l04-calls-ah)\"></line><line x1=\"580\" y1=\"70\" x2=\"606\" y2=\"31\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l04-calls-ah)\"></line><text x=\"614\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">status</text><text x=\"16\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">streaming do servidor</text><text x=\"16\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">WatchStock</text><text x=\"196\" y=\"112\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">cliente</text><text x=\"196\" y=\"156\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">servidor</text><line x1=\"204\" y1=\"112\" x2=\"690\" y2=\"112\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></line><line x1=\"204\" y1=\"156\" x2=\"690\" y2=\"156\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></line><line x1=\"230\" y1=\"114\" x2=\"256\" y2=\"153\" stroke=\"var(--paper)\" stroke-width=\"1.4\" marker-end=\"url(#l04-calls-ah)\"></line><line x1=\"300\" y1=\"154\" x2=\"326\" y2=\"115\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l04-calls-ah)\"></line><line x1=\"380\" y1=\"154\" x2=\"406\" y2=\"115\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l04-calls-ah)\"></line><line x1=\"460\" y1=\"154\" x2=\"486\" y2=\"115\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l04-calls-ah)\"></line><line x1=\"580\" y1=\"154\" x2=\"606\" y2=\"115\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l04-calls-ah)\"></line><text x=\"614\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">status</text><text x=\"16\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">streaming do cliente</text><text x=\"16\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">Restock</text><text x=\"196\" y=\"196\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">cliente</text><text x=\"196\" y=\"240\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">servidor</text><line x1=\"204\" y1=\"196\" x2=\"690\" y2=\"196\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></line><line x1=\"204\" y1=\"240\" x2=\"690\" y2=\"240\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></line><line x1=\"230\" y1=\"198\" x2=\"256\" y2=\"237\" stroke=\"var(--paper)\" stroke-width=\"1.4\" marker-end=\"url(#l04-calls-ah)\"></line><line x1=\"300\" y1=\"198\" x2=\"326\" y2=\"237\" stroke=\"var(--paper)\" stroke-width=\"1.4\" marker-end=\"url(#l04-calls-ah)\"></line><line x1=\"370\" y1=\"198\" x2=\"396\" y2=\"237\" stroke=\"var(--paper)\" stroke-width=\"1.4\" marker-end=\"url(#l04-calls-ah)\"></line><line x1=\"450\" y1=\"238\" x2=\"476\" y2=\"199\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l04-calls-ah)\"></line><line x1=\"580\" y1=\"238\" x2=\"606\" y2=\"199\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l04-calls-ah)\"></line><text x=\"614\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">status</text><text x=\"16\" y=\"288\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">bidirecional</text><text x=\"16\" y=\"306\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">(nenhum no shelf)</text><text x=\"196\" y=\"280\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">cliente</text><text x=\"196\" y=\"324\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">servidor</text><line x1=\"204\" y1=\"280\" x2=\"690\" y2=\"280\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></line><line x1=\"204\" y1=\"324\" x2=\"690\" y2=\"324\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></line><line x1=\"230\" y1=\"282\" x2=\"256\" y2=\"321\" stroke=\"var(--paper)\" stroke-width=\"1.4\" marker-end=\"url(#l04-calls-ah)\"></line><line x1=\"280\" y1=\"322\" x2=\"306\" y2=\"283\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l04-calls-ah)\"></line><line x1=\"330\" y1=\"282\" x2=\"356\" y2=\"321\" stroke=\"var(--paper)\" stroke-width=\"1.4\" marker-end=\"url(#l04-calls-ah)\"></line><line x1=\"380\" y1=\"282\" x2=\"406\" y2=\"321\" stroke=\"var(--paper)\" stroke-width=\"1.4\" marker-end=\"url(#l04-calls-ah)\"></line><line x1=\"430\" y1=\"322\" x2=\"456\" y2=\"283\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l04-calls-ah)\"></line><line x1=\"470\" y1=\"322\" x2=\"496\" y2=\"283\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l04-calls-ah)\"></line><line x1=\"580\" y1=\"322\" x2=\"606\" y2=\"283\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l04-calls-ah)\"></line><text x=\"614\" y=\"302\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">status</text><line x1=\"20\" y1=\"358\" x2=\"44\" y2=\"358\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></line><text x=\"50\" y=\"358\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma mensagem do cliente</text><line x1=\"250\" y1=\"358\" x2=\"274\" y2=\"358\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><text x=\"280\" y=\"358\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma mensagem do servidor</text><line x1=\"480\" y1=\"358\" x2=\"504\" y2=\"358\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><text x=\"510\" y=\"358\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o único status que encerra a chamada</text></svg>", "caption": "Quatro tipos de chamada, que se distinguem por qual lado pode enviar mais de uma mensagem. Cada um é uma chamada só, e cada um termina com exatamente um status.", "same": ["status"]}
```

| tipo | a linha `rpc` | no depósito |
|---|---|---|
| unária | `rpc GetStock(BookRef) returns (StockLevel)` | uma pergunta, uma resposta |
| streaming do servidor | `returns (stream StockLevel)` | o nível agora, depois cada mudança |
| streaming do cliente | `rpc Restock(stream Delivery)` | uma entrega caixa por caixa, um resumo |
| bidirecional | `stream` dos dois lados | nenhum aqui; um chat, ou um caixa enviando leituras e recebendo totais parciais |

A imagem errada é a de que um stream são muitas chamadas feitas depressa, do jeito que uma página
pergunta alguma coisa a cada poucos segundos. **Um stream é uma chamada que fica aberta**, e cada
mensagem vai pela conexão que já existe. Ninguém pergunta de novo, e não chega nada que o outro lado
não tenha escolhido enviar.

## Um stream do servidor

O `WatchStock` envia o nível na hora e de novo sempre que ele muda. Alguma coisa precisa mudá-lo
enquanto você observa, então o comando abaixo dispara duas reservas em segundo plano, com um segundo
entre elas, e observa em primeiro plano. Com Americanah em quatro exemplares:

```
ana@api:~/shelf$ python3 stock_client.py get 9786500000061
isbn: "9786500000061"
title: "Americanah"
copies: 4
availability: IN_STOCK
ana@api:~/shelf$ (sleep 1; python3 stock_client.py reserve 9786500000061 1 >/dev/null; sleep 1; python3 stock_client.py reserve 9786500000061 1 >/dev/null) & python3 stock_client.py watch 9786500000061 4
4 IN_STOCK
3 LOW
2 LOW
DEADLINE_EXCEEDED Deadline Exceeded
```

Três mensagens numa chamada: o nível quando o watch começou, depois uma por reserva, a primeira
delas levando o livro de `IN_STOCK` para `LOW`. A última linha não é uma mensagem. **O cliente pediu
quatro segundos, e a chamada acabou quando eles terminaram**, que é como um watch diz quanto tempo
quer ouvir; a próxima seção trata desse status.

O stream é empurrado para o cliente, mas o servidor descobre as mudanças lendo a linha cinco vezes
por segundo, como diz a nota dele. Um depósito de verdade seria avisado por quem muda o estoque. A
chamada que o cliente vê seria a mesma.

## Um stream do cliente

O `Restock` recebe uma entrega como um stream de caixas, e responde uma vez só, quando o cliente diz
que enviou a última. Três caixas, duas delas do mesmo livro:

```
ana@api:~/shelf$ python3 stock_client.py restock 9786500000061 5 9786500000030 2 9786500000061 1
boxes: 3
copies: 8
isbns: "9786500000061"
isbns: "9786500000030"
```

**O cliente enviou três mensagens e recebeu uma**, com `isbns` trazendo cada livro uma vez. O
cliente não esperou resposta entre as caixas, e o servidor não respondeu até o fim. É o formato para
um upload, um lote, ou qualquer coisa em que a resposta útil precise de toda a entrada.

## Os dois ao mesmo tempo

Um método bidirecional tem um stream de cada lado, e os dois correm de forma independente: cada lado
envia quando tem algo, e **a ordem se mantém dentro de cada sentido e não entre eles**. Um caixa
poderia transmitir cada livro lido e receber um total parcial depois de cada um. O depósito não tem
um método assim, e a livraria não precisa de um, então ele aparece no desenho acima e não é
construído.
