---
title: Validar antes de rodar
version: 1
---

O `agent.py` desta aula é o laço da aula 1 com uma mudança: toda chamada passa pelo `run_tool`, que valida os argumentos contra o esquema da ferramenta antes de a função rodar, e todo desfecho volta ao modelo como um `tool_result`, marcado com `is_error` quando falhou.

```schooling-example
{
  "language": "python",
  "file": "agent.py",
  "parts": [
    {
      "code": "\"\"\"The lesson 1 loop, with the tools of tools.py: every call validated, every failure returned as an error.\"\"\"\nimport json\nimport sys\n\nimport anthropic\n\n"
    },
    {
      "code": "from tools import TOOLS, run_tool\n\n",
      "note": "**As ferramentas e o portão vêm do `tools.py`**; o laço não sabe nada de pedidos nem de livros."
    },
    {
      "code": "SYSTEM = (\"You are Marginalia's support agent. Use the tools to find facts; \"\n          \"if a tool returns an error, read it and correct the call.\")\n",
      "note": "**Uma frase sobre erros**: lê-los e corrigir a chamada."
    },
    {
      "code": "DROP_ONE = \"--drop-one\" in sys.argv\n\nclient = anthropic.Anthropic()\nmessages = [{\"role\": \"user\", \"content\": sys.argv[1]}]\n",
      "note": "**Um bug deliberado para a seção 08**, ligado com uma flag."
    },
    {
      "code": "for step in range(1, 6):\n    reply = client.messages.create(model=\"scripted-1\", max_tokens=1024, system=SYSTEM,\n                                   tools=TOOLS, messages=messages)\n    messages.append({\"role\": \"assistant\", \"content\": reply.content})\n    if reply.stop_reason != \"tool_use\":\n        print(f\"[{step}] answer: {reply.content[-1].text}\")\n        break\n    results = []\n    for block in reply.content:\n        if block.type == \"tool_use\":\n",
      "note": "**O mesmo laço da aula 1.**"
    },
    {
      "code": "            text, is_error = run_tool(block.name, block.input)\n            print(f\"[{step}] {block.name}({json.dumps(block.input)}) -> {'ERROR ' if is_error else ''}{text[:70]}\")\n",
      "note": "**Toda chamada passa pelo portão.** Nada chega ao `shop.py` com argumentos que o esquema recusou."
    },
    {
      "code": "            results.append({\"type\": \"tool_result\", \"tool_use_id\": block.id, \"content\": text, \"is_error\": is_error})\n    if DROP_ONE:\n        results = results[:1]\n    messages.append({\"role\": \"user\", \"content\": results})",
      "note": "**O `is_error` viaja com o resultado**, para o modelo saber que este conteúdo descreve uma falha e não um dado."
    }
  ]
}
```

O substituto foi roteirizado para cometer dois erros que um modelo real comete: tirar o prefixo de um id que o cliente escreveu sem ele, e escrever um número por extenso. **As chamadas dele foram escritas pelo curso; as recusas são as mensagens do próprio validador.**

```
ana@lab:~/agents$ python agent.py "Where is my order 1043?"
[1] get_order({"order_id": "1043"}) -> ERROR invalid arguments: order_id: '1043' does not match '^M-[0-9]{4}$'
[2] get_order({"order_id": "M-1043"}) -> {"id": "M-1043", "customer_id": "c-102", "placed_on": "2026-09-28", "s
[3] answer: Order M-1043 has shipped and is on its way, with tracking code BR5512340003. It has not been delivered yet.
```

```
ana@lab:~/agents$ python agent.py "Which mystery novels do you have in stock?"
[1] find_books({"genre": "mystery", "max_results": "five"}) -> ERROR invalid arguments: max_results: 'five' is not of type 'integer'
[2] find_books({"genre": "mystery", "max_results": 5}) -> [{"id": "b11", "title": "The Mysterious Affair at Styles", "author": "
[3] answer: Right now we have one mystery in stock: The Mysterious Affair at Styles by Agatha Christie, at 31.90.
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"O portão de validação. Uma chamada de ferramenta do modelo vai primeiro para a checagem do esquema. Se os argumentos falham, um erro descrevendo a falha volta ao modelo como resultado da ferramenta, e nenhuma função roda. Se passam, a função roda; se ela levanta um erro conhecido, esse erro volta do mesmo jeito; senão, volta o resultado.\"><defs><marker id=\"l4gate-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l4gate-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"90\" width=\"130\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"107.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">chamada</text><text x=\"30\" y=\"123.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">do modelo</text><rect x=\"200\" y=\"90\" width=\"140\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"210\" y=\"107.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">checar esquema</text><text x=\"210\" y=\"123.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">jsonschema</text><rect x=\"400\" y=\"90\" width=\"130\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"410\" y=\"107.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a função</text><text x=\"410\" y=\"123.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">shop.py</text><rect x=\"580\" y=\"20\" width=\"120\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"590\" y=\"37.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">is_error: true</text><text x=\"590\" y=\"53.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o que falhou</text><rect x=\"580\" y=\"160\" width=\"120\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"590\" y=\"177.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">is_error: false</text><text x=\"590\" y=\"193.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o resultado</text><path d=\"M150 115 L200 115\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l4gate-ah-amber)\"></path><path d=\"M340 115 L400 115\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l4gate-ah-phosphor)\"></path><text x=\"370\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">passa</text><path d=\"M270 90 L270 45 L580 45\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l4gate-ah-amber)\"></path><text x=\"330\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">falha</text><path d=\"M465 90 L465 60 L580 60\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l4gate-ah-amber)\"></path><text x=\"520\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">levanta</text><path d=\"M465 140 L465 185 L580 185\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l4gate-ah-phosphor)\"></path><text x=\"520\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">devolve</text></svg>", "caption": "Todo caminho acaba num resultado de ferramenta. Nenhum acaba numa queda.", "same": ["jsonschema", "shop.py"]}
```

Nas duas execuções a chamada ruim custou um passo e mais nada. O validador a recusou, a mensagem voltou como erro, e a chamada seguinte veio certa. Sem o portão, `get_order("1043")` teria levantado um `LookupError` dentro do hospedeiro, que é o caso melhor; `find_books(max_results="five")` teria chegado ao `stocked[:max_results]` e caído com um `TypeError`, que é uma falha do hospedeiro em vez de um erro do modelo que dá para corrigir.

**É o acúmulo da aula 2 sendo interrompido.** Um passo errado que vira um erro que o modelo lê é um passo que se corrige em vez de servir de base. O custo é um pedido a mais, e o rastro mostra exatamente onde aconteceu.

Repare também no que a segunda execução devolveu: um livro, embora cinco tenham sido pedidos. O `find_books` lista só o que está em estoque, e dois dos três mistérios que a Marginalia tem com preço estão esgotados. O modelo informou um, porque voltou um. Uma ferramenta que responde com honestidade, mesmo quando a resposta é pequena, vale mais que uma que enche.
