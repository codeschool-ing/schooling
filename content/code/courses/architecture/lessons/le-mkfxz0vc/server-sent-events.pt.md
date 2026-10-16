---
title: Server-Sent Events
version: 1
---

Os **Server-Sent Events** transformam a própria resposta no canal. O navegador faz uma requisição com
`Accept: text/event-stream`, e o servidor responde com uma resposta que nunca termina, escrevendo cada
evento nela como algumas linhas de texto: uma linha `id:`, uma linha `data:`, e uma linha em branco para
fechá-lo. Abra o fluxo por quatro segundos enquanto o armazém marca o pedido como enviado:

```
ana@vm:~/lab/live$ timeout 4 curl -sN localhost:8001/events & sleep 1; curl -s -X POST localhost:8001/publish -d "o-1 shipped" > /dev/null; wait
id: 1
data: a: o-1 paid

id: 2
data: a: o-1 packed

id: 3
data: a: o-1 shipped
```

O fluxo primeiro mandou os dois eventos que já existiam, depois ficou parado, depois escreveu o evento 3
no momento em que foi publicado. Num navegador o cliente inteiro são duas linhas de JavaScript,
`new EventSource("/events")` e um tratador para as mensagens, e o navegador cuida do que a maior parte do
código erra: **ele reconecta sozinho**, e quando reconecta manda o id do último evento que recebeu num
cabeçalho `Last-Event-ID`. O servidor começa o fluxo depois dele:

```
ana@vm:~/lab/live$ timeout 2 curl -sN localhost:8001/events -H "Last-Event-ID: 2"
id: 3
data: a: o-1 shipped
```

Pedido para retomar depois do evento 2, o fluxo mandou o evento 3 e nada antes dele. Uma conexão que cai
num trem não custa nada ao cliente.

SSE é HTTP comum, então passa por proxies, balanceadores e firewalls corporativos que entendem HTTP,
funciona com HTTP/2 e HTTP/3, e é comprimido e autenticado como qualquer outra resposta. Os limites dele
são levar **texto, só do servidor**, e no HTTP/1.1 um navegador abrir no máximo seis conexões para um host,
o que várias abas com um fluxo cada podem esgotar; no HTTP/2 os fluxos dividem uma conexão e o limite
some. Para "avise a página quando algo mudar", que é a maior parte do que uma loja precisa, ele costuma ser
a resposta certa e a mais esquecida.
