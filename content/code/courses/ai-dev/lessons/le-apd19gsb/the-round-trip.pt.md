---
title: Uma chamada, ida e volta
version: 1
---

A aula 7 usou ferramentas dentro de um agente, com o MCP no meio. Esta aula tira o protocolo e olha
para a troca da qual todo o resto é feito: **o modelo pede uma função, o seu código a roda, e o
resultado volta como parte da conversa**. As respostas do modelo nesta aula foram escritas pelo
curso, como regras do `scripted-1`; o SDK, as requisições e todos os resultados são reais.

## A ferramenta, como o modelo a vê

Uma ferramenta são três coisas na requisição: um `name`, uma `description` e um `input_schema`, que
é um JSON Schema dos argumentos. O modelo nunca vê a sua função. Ele vê isto, e decide só pela
descrição se a ferramenta serve para a pergunta.

```python
def get_stock(sku):
    stock = json.loads(Path("data/stock.json").read_text())
    if sku not in stock:
        raise ShopError(f"no product {sku}; SKUs look like MUG-01")
    return stock[sku]
```

A função é Python comum. A definição ao lado dela, em `TOOLS`, é o que viaja:

```python
    {
        "name": "get_stock",
        "description": "Units in stock and unit price in cents for one product, by its SKU.",
        "input_schema": {
            "type": "object",
            "properties": {"sku": {"type": "string", "description": "The product's SKU, such as MUG-01."}},
            "required": ["sku"],
        },
    },
```

## O laço que imprime tudo

```schooling-example
{
  "language": "python",
  "file": "stock.py",
  "parts": [
    {
      "code": "\"\"\"One question, with tools: every request and reply of the round trip, printed.\"\"\"\nimport json\nimport sys\n\nimport anthropic\n\n"
    },
    {
      "code": "from shop_tools import FUNCTIONS, TOOLS\n\nmodel = anthropic.Anthropic()\nmessages = [{\"role\": \"user\", \"content\": sys.argv[1]}]\n",
      "note": "**As ferramentas vêm de um módulo**, junto com as funções que fazem o trabalho."
    },
    {
      "code": "while True:\n    r = model.messages.create(model=\"scripted-1\", max_tokens=300, tools=TOOLS, messages=messages)\n    print(\"<- stop_reason:\", r.stop_reason)\n    for b in r.content:\n        print(\"  \", json.dumps(b.model_dump(exclude_none=True)))\n",
      "note": "**Uma requisição por vez**, levando as ferramentas e a conversa inteira até ali. Cada bloco da resposta é impresso como chegou."
    },
    {
      "code": "    messages.append({\"role\": \"assistant\", \"content\": r.content})\n    if r.stop_reason != \"tool_use\":\n        break\n",
      "note": "**A resposta entra na conversa como veio**, e uma resposta que não pede ferramenta é a resposta final."
    },
    {
      "code": "    results = []\n    for b in r.content:\n        if b.type == \"tool_use\":\n            out = FUNCTIONS[b.name](**b.input)\n            results.append({\"type\": \"tool_result\", \"tool_use_id\": b.id, \"content\": json.dumps(out)})\n",
      "note": "**Só aqui algo roda.** O modelo deu o nome de uma função e os argumentos; o host procura o nome na própria tabela e chama."
    },
    {
      "code": "    print(\"-> user:\")\n    for x in results:\n        print(\"  \", json.dumps(x))\n    messages.append({\"role\": \"user\", \"content\": results})",
      "note": "**Todos os resultados voltam numa só mensagem de usuário**, cada um ligado à sua chamada pelo `tool_use_id`."
    }
  ]
}
```

## O que passou pelo fio

```
ana@dev:~/shop$ python stock.py "Is LAMP-02 in stock?"
<- stop_reason: tool_use
   {"id": "toolu_lab_0001_1", "input": {"sku": "LAMP-02"}, "name": "get_stock", "type": "tool_use"}
-> user:
   {"type": "tool_result", "tool_use_id": "toolu_lab_0001_1", "content": "{\"in_stock\": 4, \"unit_price\": 21000}"}
<- stop_reason: end_turn
   {"text": "Yes. LAMP-02 is in stock, 4 units, at 210.00.", "type": "text"}
```

Leia de cima para baixo. **A primeira resposta não é uma resposta.** O `stop_reason` dela é
`tool_use`, e o conteúdo é um bloco com o nome da ferramenta e os argumentos, com um `id` que a API
atribuiu: `toolu_lab_0001_1`. O modelo parou e está esperando.

**A resposta do host é uma mensagem `user`**, porque uma conversa alterna entre dois papéis e a
saída da ferramenta fica do lado do usuário. Ela leva um `tool_result` cujo `tool_use_id` é aquele
mesmo id. O id é a ligação: com duas chamadas em andamento, ele diz qual resultado responde a qual.

A segunda resposta é texto, e o `stop_reason` é `end_turn`. O 210.00 nela são os `21000` centavos
do resultado da ferramenta, divididos por cem pelo modelo. **Essa divisão é do modelo, não do seu
código**, e a aula 8 seção 07 volta ao que isso quer dizer quando o número importa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A ida e volta de uma chamada de ferramenta. O host manda a pergunta e as definições de ferramentas. O modelo responde com um bloco tool_use com um id e para. O host roda a função e manda um tool_result com o mesmo id. O modelo responde com a resposta e end_turn.\"><defs><marker id=\"rt-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"15\" y=\"14\" width=\"190\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o modelo</text><path d=\"M110 48 L110 288\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><rect x=\"275\" y=\"14\" width=\"190\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"370.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">seu código (o host)</text><path d=\"M370 48 L370 288\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><rect x=\"525\" y=\"14\" width=\"190\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a função</text><path d=\"M620 48 L620 288\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M366 74 L114 74\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rt-ah)\"></path><text x=\"240.0\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pergunta + definições de ferramentas</text><path d=\"M114 114 L366 114\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rt-ah)\"></path><text x=\"240.0\" y=\"103\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">tool_use  id=toolu_…_1  get_stock {&quot;sku&quot;: &quot;LAMP-02&quot;}</text><path d=\"M374 154 L616 154\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rt-ah)\"></path><text x=\"495.0\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">get_stock(sku=&quot;LAMP-02&quot;)</text><path d=\"M616 194 L374 194\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rt-ah)\"></path><text x=\"495.0\" y=\"183\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">{&quot;in_stock&quot;: 4, &quot;unit_price&quot;: 21000}</text><path d=\"M366 234 L114 234\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rt-ah)\"></path><text x=\"240.0\" y=\"223\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">tool_result  tool_use_id=toolu_…_1</text><path d=\"M114 274 L366 274\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rt-ah)\"></path><text x=\"240.0\" y=\"263\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a resposta, end_turn</text></svg>", "caption": "O modelo propõe uma chamada e espera. Só o host roda algo, e o id liga cada resultado à sua chamada."}
```

## Três coisas que isto mostra

- **O modelo só propõe.** Nada rodou até o `FUNCTIONS[b.name](**b.input)` no host. Um modelo que
  pede uma ferramenta que você nunca ligou não recebe nada, e esse é o modelo de segurança inteiro
  da chamada de funções numa linha.
- **A conversa é o estado.** A segunda requisição leva a pergunta, a chamada e o resultado. Tire
  qualquer um e o modelo está respondendo a outra conversa.
- **Cada passo é uma requisição completa.** Duas idas e voltas custam duas requisições, cada uma
  cobrada por tudo o que leva, que é a conta da aula 2 aplicada a ferramentas.
