---
title: Dois servidores, um nome
version: 1
---

Os nomes de ferramenta são escolhidos por quem escreve um servidor, e nada impede dois servidores de escolher o mesmo. O `orders` oferece `get_order` para pedidos vivos; o `archive`, servidor de outra equipe, também oferece `get_order`, para os do ano passado:

```python
"""Another team's server, "archive", which happens to name its tool get_order too."""
import json

from mcp.server.mcpserver import MCPServer

server = MCPServer("archive")


@server.tool()
def get_order(order_id: str) -> str:
    """Look up an order in last year's archive."""
    return json.dumps({"id": order_id, "status": "archived", "source": "archive server"})


if __name__ == "__main__":
    server.run()
```

Cada hospedeiro recebeu os dois servidores e a pergunta sobre o M-1043. O `names.py` imprime os nomes de ferramenta que o hospedeiro ofereceu ao modelo no primeiro pedido:

```python
"""The tool names the host offered its model in the first request, or that it sent none."""
import json

lines = open("/var/log/labllm/requests.jsonl").readlines()
if not lines:
    print("offered: no request was sent")
else:
    tools = json.loads(lines[0])["request"].get("tools", [])
    flat = [f for t in tools for f in t.get("functionDeclarations", [t])]
    print("offered:", ", ".join(t.get("name") or t["function"]["name"] for t in flat))
```

```
ana@lab:~/agents$ python hosts.py OpenAI 'Where is my order M-1043?' orders archive 2>&1 | grep -v unrecognized_model; python names.py
raised UserError: Duplicate tool names found across MCP servers: 'get_order'. Pass `include_server_in_tool_names=True` to `MCPUtil.get_all_function_tools()` or set `mcp_config={'include_server_in_tool_names': True}` on the agent to prefix tool names with their server name and avoid collisions.
offered: no request was sent
ana@lab:~/agents$ python hosts.py Claude 'Where is my order M-1043?' orders archive 2>&1 | grep -v unrecognized_model; python names.py
Order M-1043 has shipped; its tracking code is BR5512340003, and the link in your shipping email follows it.
offered: mcp__archive__get_order, mcp__orders__get_order
ana@lab:~/agents$ python hosts.py Google 'Where is my order M-1043?' orders archive 2>&1 | grep -v unrecognized_model; python names.py
WARNING:root:Duplicate tool name 'get_order': the previously registered tool is shadowed and can no longer be called.
WARNING:root:Duplicate tool name 'get_order': the previously registered tool is shadowed and can no longer be called.
Order M-1043 is archived, so I cannot see where it is now.
offered: get_order, get_order
```

Três hospedeiros, três comportamentos:

- **O hospedeiro da OpenAI se recusou** a rodar: `UserError: Duplicate tool names found across MCP servers`, com a opção que resolve, `include_server_in_tool_names`. Nenhum pedido chegou ao modelo.
- **O hospedeiro do Claude renomeou** as duas, `mcp__orders__get_order` e `mcp__archive__get_order`, para o modelo distingui-las, e a regra do curso escolheu a viva.
- **O hospedeiro do Google ofereceu ao modelo duas ferramentas com o mesmo nome**, e toda chamada foi para o `archive`, o último registrado. A resposta disse que o pedido estava arquivado. O único sinal foi um aviso no log, *"the previously registered tool is shadowed and can no longer be called"*.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Dois servidores, orders e archive, oferecem uma ferramenta chamada get_order. O hospedeiro da OpenAI se recusou a começar a execução. O hospedeiro do Claude as renomeou para mcp__orders__get_order e mcp__archive__get_order, e o modelo escolheu a viva. O hospedeiro do Google ofereceu duas ferramentas chamadas get_order, e toda chamada foi para o servidor archive, com só um aviso no log.\"><defs><marker id=\"l12same-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"80\" width=\"150\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"102.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">dois servidores</text><text x=\"30\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">os dois oferecem get_order</text><rect x=\"250\" y=\"20\" width=\"450\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"260\" y=\"37.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">hospedeiro OpenAI: recusa</text><text x=\"260\" y=\"53.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">UserError: Duplicate tool names</text><rect x=\"250\" y=\"85\" width=\"450\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"260\" y=\"102.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">hospedeiro Claude: renomeia</text><text x=\"260\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">mcp__orders__get_order, mcp__archive__get_order</text><rect x=\"250\" y=\"150\" width=\"450\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"260\" y=\"167.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">hospedeiro Google: encobre, em silêncio</text><text x=\"260\" y=\"183.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">get_order duas vezes; as chamadas vão para archive</text><path d=\"M170 100 L250 45\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l12same-ah-wire)\"></path><path d=\"M170 110 L250 110\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l12same-ah-wire)\"></path><path d=\"M170 120 L250 175\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l12same-ah-wire)\"></path></svg>", "caption": "Um nome, dois servidores: recusar, renomear, ou mandar para o último que chegou.", "same": ["UserError: Duplicate tool names", "mcp__orders__get_order, mcp__archive__get_order"]}
```

O terceiro é o que vale lembrar. A execução deu certo, o cliente recebeu uma resposta confiante, e ela veio do sistema errado. Nada no MCP impede isso, porque uma colisão de nomes não é erro de protocolo: cada servidor está correto sozinho. **É trabalho do hospedeiro manter separadas as ferramentas de servidores diferentes**, com prefixo, com recusa, ou escolhendo de propósito que servidores um hospedeiro conecta ao mesmo tempo, e um teste que conecta todo servidor que uma implantação usa e confere a lista de ferramentas atrás de duplicatas é barato.
