---
title: Propagação, o cabeçalho que faz dele um rastro só
version: 1
---

Um rastro atravessa a fronteira de um serviço em **um cabeçalho HTTP**, definido pela recomendação
Trace Context do W3C e chamado `traceparent`. A bilheteria o escreve com `propagate.inject` em toda
chamada ao payments, e o payments o imprime como chega. Uma venda, depois a última linha do log de
cada serviço:

```
ana@lab:~/tickets$ curl -s -X POST localhost:8080/events/2/tickets; echo
{"event": 2, "seat": 1, "code": "8b862c7b06ca08c1"}
ana@lab:~/tickets$ docker compose logs payments --no-log-prefix | tail -1
{"message": "charge", "traceparent": "00-5bd86167ca0ed7a647e37c1ebe501aac-b78031cb62daec0c-03"}
ana@lab:~/tickets$ docker compose logs app --no-log-prefix | grep '"POST"' | tail -1
{"time": "2026-10-10T06:22:21.113+00:00", "level": "info", "message": "request", "host": "dd4bf75a071b", "method": "POST", "route": "/events/{id}/tickets", "status": 201, "ms": 46.2, "trace_id": "5bd86167ca0ed7a647e37c1ebe501aac"}
```

O cabeçalho são quatro campos separados por hífens:

| campo | aqui | significado |
|---|---|---|
| versão | `00` | a versão do formato |
| id do rastro | `5bd86167ca0ed7a647e37c1ebe501aac` | o rastro a que este pedido pertence: o mesmo que o `trace_id` na linha de log da bilheteria |
| id do pai | `b78031cb62daec0c` | o span que fez esta chamada, o span `charge` da bilheteria, que vira o pai do span do payments |
| flags | `03` | o bit `01` diz que o rastro foi amostrado, então o payments registra o span dele também; o bit `02`, mais novo, diz que o id do rastro foi gerado ao acaso |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"O cabeçalho traceparent que a bilheteria mandou ao payments, separado nos quatro campos: versão 00, um id de rastro de 32 dígitos compartilhado pelo rastro inteiro, um id de pai de 16 dígitos que nomeia o span de cobrança da bilheteria, e as flags 03, cujo bit mais baixo diz que o rastro foi amostrado.\"><rect x=\"40\" y=\"40\" width=\"30\" height=\"34\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"55.0\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">00</text><text x=\"55.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">versão</text><text x=\"80\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">-</text><rect x=\"90\" y=\"40\" width=\"270\" height=\"34\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"225.0\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">5bd86167ca0ed7a647e37c1ebe501aac</text><text x=\"225.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">id do rastro</text><text x=\"370\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">-</text><rect x=\"380\" y=\"40\" width=\"140\" height=\"34\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"450.0\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">b78031cb62daec0c</text><text x=\"450.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">id do pai</text><text x=\"530\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">-</text><rect x=\"540\" y=\"40\" width=\"30\" height=\"34\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></rect><text x=\"555.0\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">03</text><text x=\"555.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">flags</text><text x=\"40\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">igual ao trace_id no log da bilheteria</text><text x=\"400\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o span charge, pai do span do payments</text></svg>", "caption": "Quatro campos, e o segundo é o que faz de dois serviços um rastro.", "same": ["flags"]}
```

Esse é o contrato inteiro. O payments não precisa do SDK, da linguagem nem do fornecedor da
bilheteria; precisa ler quatro campos e passá-los adiante. **Um serviço no meio que não repassa o
cabeçalho parte o rastro em dois**, e a causa mais comum de rastros que param num serviço é
exatamente essa: um proxy, uma fila ou um cliente HTTP escrito à mão que descarta cabeçalhos
desconhecidos.

## Um rastro que começa fora

A bilheteria continua um rastro que recebe, não só os que ela começa. Aqui um cliente manda o próprio
`traceparent`, o exemplo da própria especificação do W3C:

```
ana@lab:~/tickets$ curl -s -X POST -H 'traceparent: 00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01' localhost:8080/events/3/tickets; echo
{"event": 3, "seat": 1, "code": "aaec814f7270e014"}
ana@lab:~/tickets$ sleep 7
ana@lab:~/tickets$ python3 trace.py
trace 0af7651916cd43dd8448eb211c80319c
POST /events/{id}/tickets      tickets   at   0.0 ms  took  43.8 ms
  charge                       tickets   at   0.1 ms  took  35.3 ms
    POST /charges              payments  at   1.9 ms  took  33.1 ms
  UPDATE events                tickets   at  35.8 ms  took   0.7 ms
  sign                         tickets   at  36.5 ms  took   5.0 ms
  INSERT tickets               tickets   at  41.6 ms  took   0.7 ms
```

**O id do rastro é o que o cliente escolheu**, `0af7651916cd43dd8448eb211c80319c`, e o span raiz da
bilheteria é filho do span `b7ad6b7169203331` do cliente, que o Jaeger não tem porque o cliente nunca
o mandou. É assim que um rastro cobre um navegador, um balanceador de carga, um gateway e todo serviço
atrás deles: cada um lê o cabeçalho, continua o rastro e o passa adiante.

Numa fila de mensagens a mesma identidade viaja nos cabeçalhos da mensagem em vez dos do HTTP, e os
propagadores do OpenTelemetry tratam os dois casos.

## E o custo de um cabeçalho

Aceitar um `traceparent` de fora significa que um cliente pode escolher os seus ids de rastro e a sua
decisão de amostragem. Sistemas que se importam põem um gateway na borda que começa um rastro novo
para quem chama sem ser confiável, ou registra o rastro de quem chamou como um vínculo (*link*) em
vez de como pai, para que ninguém de fora possa encher um back end de rastros pedindo que todo pedido
seja amostrado.
