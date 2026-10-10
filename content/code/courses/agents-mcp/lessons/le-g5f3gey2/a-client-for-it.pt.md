---
title: Um cliente para ele
version: 2
---

Um hospedeiro alcança um servidor remoto com o mesmo `Client` de antes, recebendo um transporte de URL em vez de um comando. O `remote_client.py` acrescenta as duas coisas de que a rede precisa:

```schooling-example
{
  "language": "python",
  "file": "remote_client.py",
  "parts": [
    {
      "code": "\"\"\"Call the remote server: TLS checked against the second machine's CA, and a bearer token from a file.\"\"\"\nimport asyncio\nimport json\nimport ssl\nimport sys\n\nimport httpx2\nfrom mcp import Client\nfrom mcp.client.streamable_http import streamable_http_client\n\nURL = \"https://mcp.marginalia.test:8443/mcp\"\n"
    },
    {
      "code": "CA = \"marginalia-ca.crt\"   # the second machine's authority, and the only one this client trusts\n\n\nasync def main(token_name, tool, arguments):\n    token = open(f\"tokens/{token_name}\").read()\n",
      "note": "**A única autoridade em que este cliente confia**, por arquivo. Não a lista do sistema, e nunca checagem nenhuma."
    },
    {
      "code": "    tls = ssl.create_default_context(cafile=CA)\n",
      "note": "**O nome do host e a cadeia são verificados como sempre**, contra essa autoridade."
    },
    {
      "code": "    async with httpx2.AsyncClient(verify=tls, headers={\"Authorization\": f\"Bearer {token}\"}) as http:\n",
      "note": "**O token de portador em todo pedido**, de um arquivo que só a ana consegue ler."
    },
    {
      "code": "        async with Client(streamable_http_client(URL, http_client=http)) as client:\n            result = await client.call_tool(tool, json.loads(arguments))\n            print((\"error: \" if result.is_error else \"result: \") + result.content[0].text[:120])\n\n\n",
      "note": "**O mesmo `Client` da aula 15**, sobre Streamable HTTP."
    },
    {
      "code": "def first_cause(group):\n    \"\"\"The innermost exception of a (possibly nested) group: the one that says what happened.\"\"\"\n    while isinstance(group, BaseExceptionGroup):\n        group = group.exceptions[0]\n    return group\n\n\ntry:\n    asyncio.run(main(*sys.argv[1:]))\nexcept BaseException as e:\n    cause = first_cause(e)\n    print(f\"refused: {type(cause).__name__}: {cause}\")",
      "note": "**O SDK informa uma conexão recusada como um grupo de exceções**; isto imprime a mais interna."
    }
  ]
}
```

```
ana@lab:~/agents$ python remote_client.py support get_order '{"order_id": "M-1043"}'
result: {"id": "M-1043", "status": "shipped", "placed_on": "2026-09-28", "delivered_on": null, "tracking": "BR5512340003", "tota
ana@lab:~/agents$ python remote_client.py billing get_order '{"order_id": "M-1043"}'
refused: MCPError: Server returned an error response
```

Com o token `support`, a chamada funcionou, pelos próprios pedidos do SDK: a descoberta, a chamada, cada um com os cabeçalhos que a aula 13 mandou à mão. Com o token `billing`, o `401` do servidor voltou como *"Server returned an error response"*. Um cliente feito para uso de verdade leria o cabeçalho `WWW-Authenticate` nesse ponto e começaria o fluxo da seção 08; o SDK tem suporte de cliente OAuth para isso, que este laboratório não consegue exercitar sem um servidor de autorização que funcione.

Para o hospedeiro da aula 15, levar um servidor de local para remoto troca a entrada em `SERVERS` de um comando para uma URL e acrescenta um token. O que isso tira é igualmente importante: não há `ENV` para acertar, porque o hospedeiro não inicia nada, nem a questão de que arquivos o servidor consegue ler na máquina da ana, porque ele roda em outra. **O que acrescenta é um segredo**, o token, que o hospedeiro tem de manter fora dos logs, fora do contexto do modelo e fora de todo servidor de onde ele não veio.
