---
title: Escolhendo
version: 1
---

| a necessidade | comece com | por quê |
| --- | --- | --- |
| um painel atualizado a cada minuto, poucos observadores | polling | nada a construir nem a operar; o desperdício é pequeno |
| a página deve mudar quando algo acontece no servidor | Server-Sent Events | HTTP comum, reconecta e retoma sozinho |
| mensagens nos dois sentidos, muitas por segundo | WebSocket | o único feito para isso |
| redes que bloqueiam tudo acima, ou clientes muito antigos | long polling | funciona onde o HTTP funcionar |
| um servidor avisando outro | um webhook, ou um broker | nenhum dos lados é um navegador |

Para a Quitanda, a página de status do pedido e o selo "restam 2" são **SSE**: o servidor tem a novidade,
a página escuta, e uma página de pedido deixada aberta num celular sobrevive aos túneis do metrô. Um chat
de suporte futuro seria um **WebSocket**. E seja qual for, com mais de uma instância um **backplane** entra
no mesmo dia, porque a falha que ele evita é silenciosa.

Quando terminar, pare o laboratório:

```sh
docker compose down
```
