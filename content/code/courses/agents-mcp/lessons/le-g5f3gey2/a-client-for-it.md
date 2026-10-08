---
title: A client for it
version: 2
---

A host reaches a remote server with the same `Client` as before, given a URL transport instead of a command. `remote_client.py` adds the two things the network needs:

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
      "note": "**The one authority this client trusts**, by file. Not the system's list, and never no check at all."
    },
    {
      "code": "    tls = ssl.create_default_context(cafile=CA)\n",
      "note": "**Hostname and chain are verified as usual**, against that authority."
    },
    {
      "code": "    async with httpx2.AsyncClient(verify=tls, headers={\"Authorization\": f\"Bearer {token}\"}) as http:\n",
      "note": "**The bearer token on every request**, from a file only ana can read."
    },
    {
      "code": "        async with Client(streamable_http_client(URL, http_client=http)) as client:\n            result = await client.call_tool(tool, json.loads(arguments))\n            print((\"error: \" if result.is_error else \"result: \") + result.content[0].text[:120])\n\n\n",
      "note": "**The same `Client` as lesson 15**, over Streamable HTTP."
    },
    {
      "code": "def first_cause(group):\n    \"\"\"The innermost exception of a (possibly nested) group: the one that says what happened.\"\"\"\n    while isinstance(group, BaseExceptionGroup):\n        group = group.exceptions[0]\n    return group\n\n\ntry:\n    asyncio.run(main(*sys.argv[1:]))\nexcept BaseException as e:\n    cause = first_cause(e)\n    print(f\"refused: {type(cause).__name__}: {cause}\")",
      "note": "**The SDK reports a refused connection as a group of exceptions**; this prints the innermost one."
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

With the `support` token the call worked, through the SDK's own requests: discovery, the call, each with the headers lesson 13 sent by hand. With the `billing` token the server's `401` came back as *"Server returned an error response"*. A client built for real use would read the `WWW-Authenticate` header at that point and start the flow of section 08; the SDK has OAuth client support for that, which this lab cannot exercise without a working authorization server.

For lesson 15's host, moving a server from local to remote changes the `SERVERS` entry from a command to a URL and adds a token. What it removes is just as important: there is no `ENV` to get right, because the host starts nothing, and no question of what files the server can read on ana's machine, because it runs on another. **What it adds is a secret**, the token, that the host has to keep out of logs, out of the model's context and out of every server it did not come from.
