---
title: Tokens e escopos
version: 2
---

O `call.sh` manda um `tools/call` com um token nomeado, os cabeçalhos da aula 13 e a CA do laboratório:

```bash
# call.sh TOKEN-NAME TOOL ARGUMENTS: one tools/call to the remote server, by hand, with curl.
curl -s --cacert marginalia-ca.crt https://mcp.marginalia.test:8443/mcp \
  -H "Authorization: Bearer $(cat tokens/$1)" \
  -H "Content-Type: application/json" -H "Accept: application/json, text/event-stream" \
  -H "MCP-Protocol-Version: 2026-07-28" -H "Mcp-Method: tools/call" -H "Mcp-Name: $2" \
  -d "{\"jsonrpc\": \"2.0\", \"id\": 1, \"method\": \"tools/call\", \"params\": {\"name\": \"$2\", \"arguments\": $3,
       \"_meta\": {\"io.modelcontextprotocol/protocolVersion\": \"2026-07-28\", \"io.modelcontextprotocol/clientCapabilities\": {}}}}" \
  -w "  [HTTP %{http_code}]\n"
```

Quatro tokens, cinco chamadas:

```
ana@lab:~/agents$ bash call.sh support get_order '{"order_id": "M-1043"}' | cut -c1-170
{"jsonrpc":"2.0","id":1,"result":{"content":[{"text":"{\"id\": \"M-1043\", \"status\": \"shipped\", \"placed_on\": \"2026-09-28\", \"delivered_on\": null, \"tracking\": \
ana@lab:~/agents$ bash call.sh support refund '{"order_id": "M-1047", "cents": 3890, "reason": "one copy arrived damaged"}' | cut -c1-170
{"jsonrpc":"2.0","id":1,"result":{"content":[{"text":"Error executing tool refund: the token of support-agent does not carry orders:refund","type":"text"}],"isError":true
ana@lab:~/agents$ bash call.sh refunds refund '{"order_id": "M-1047", "cents": 3890, "reason": "one copy arrived damaged"}' | cut -c1-170
{"jsonrpc":"2.0","id":1,"result":{"content":[{"text":"{\"order_id\": \"M-1047\", \"refunded\": 3890, \"left\": 3890}","type":"text"}],"isError":false,"resultType":"comple
ana@lab:~/agents$ bash call.sh billing get_order '{"order_id": "M-1043"}'
{"error": "invalid_token", "error_description": "Authentication required"}  [HTTP 401]
ana@lab:~/agents$ bash call.sh expired get_order '{"order_id": "M-1043"}'
{"error": "invalid_token", "error_description": "Authentication required"}  [HTTP 401]
```

- **`support`**, escopo `orders:read`, leu o pedido. Só os campos da lista de permitidos voltaram.
- **`support` de novo, pedindo um reembolso**, recebeu um erro de ferramenta: *"the token of support-agent does not carry orders:refund"*. O token era válido; a ferramenta recusou porque o escopo dele era estreito demais.
- **`refunds`**, com `orders:read` e `orders:refund`, reembolsou 3890 centavos, na cópia da loja da própria segunda máquina.
- **`billing`**, válido e não vencido mas **emitido para `https://billing.marginalia.test/mcp`**, recebeu `401`. Essa é a **regra de audiência** da especificação: um servidor MCP só pode aceitar tokens emitidos para ele. Sem ela, um token que o cliente da ana obteve para um serviço funcionaria em qualquer outro serviço que confiasse no mesmo servidor de autorização, e um servidor malicioso que recebesse um token poderia reutilizá-lo em outro lugar.
- **`expired`** também recebeu `401`, com o mesmo corpo. Um cliente não consegue saber pela resposta que checagem falhou, e isso é de propósito: o servidor não dá a ninguém um jeito de sondar que tokens existem.

Um ponto em que este servidor e a especificação se separam. Para um token válido com **escopo estreito demais**, a especificação recomenda `403 Forbidden` com um cabeçalho `WWW-Authenticate` que nomeie o escopo necessário, para um cliente poder voltar e pedi-lo. Aqui a recusa é um erro de ferramenta dentro de um `200`: um modelo consegue lê-lo, mas um cliente não consegue agir sobre ele sozinho. O modo de servidor de recurso do SDK confere um conjunto de escopos obrigatórios para o servidor inteiro; um escopo por ferramenta é conferido na ferramenta, como aqui, e informá-lo do jeito que a especificação recomenda exigiria mais código do que o servidor desta aula tem.

O ponto de desenho vale de qualquer jeito: **dê a cada cliente o token mais estreito que faz o trabalho dele**. O agente de suporte lê; só a mesa de reembolsos reembolsa. Se o token do agente de suporte vazar, ou se o modelo dele for convencido a tentar um reembolso (aula 17), o servidor diz não.
