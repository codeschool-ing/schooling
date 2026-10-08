---
title: O laço em código
version: 2
---

O host é curto. Ele se conecta ao servidor MCP da loja (aula 7 seção 06), transforma as ferramentas
que o servidor lista nas definições de ferramenta que a API do modelo espera, e roda o laço com um
limite de passos. Toda decisão nesta aula, que ferramenta chamar e o que responder, é do
`llama3.2:3b`.

```schooling-example
{
  "language": "python",
  "file": "agent.py",
  "parts": [
    {
      "code": "\"\"\"A host: it starts the shop's MCP server, offers its tools to the model, and runs the loop.\"\"\"\nimport asyncio\nimport json\nimport sys\nfrom datetime import date\n\nimport anthropic\nfrom mcp import Client, StdioServerParameters\n\n"
    },
    {
      "code": "MAX_STEPS = 5\nRULES = (f\"Today is {date.today():%d %B %Y}. Answer questions about the shop with its tools. \"\n         \"Every fact in your answer must come from a tool result; if the tools cannot give \"\n         \"the answer, say that you could not find it.\")\nREMIND = \"Call another tool if you need one; otherwise answer.\"\nmodel = anthropic.Anthropic()\nsent = []  # input tokens of each request, reused prefix included (lesson 2 section 07)\n\n\n",
      "note": "**As guardas são constantes no host**, onde o modelo não consegue mudá-las. Mais duas coisas que o host pode acrescentar, cada uma só quando pedida: `--rules` põe `RULES` num prompt de sistema, a data de hoje, que nenhuma ferramenta dá, e a regra de que todo fato precisa de um resultado de ferramenta por trás; `--remind` põe `REMIND` depois de cada lote de resultados. A aula 7 seção 09 roda as duas."
    },
    {
      "code": "def approve(name, args):\n    try:\n        answer = input(f\"allow {name}({json.dumps(args)})? [y/N] \")\n    except EOFError:  # nobody at the keyboard is a no\n        answer = \"\"\n    print(answer)\n    return answer.strip().lower() == \"y\"\n\n\n",
      "note": "**Uma pessoa aprova uma chamada que muda alguma coisa**, vendo os argumentos exatos. Ninguém no teclado conta como não."
    },
    {
      "code": "async def run(question, rules, remind):\n    async with Client(StdioServerParameters(command=\"python\", args=[\"mcp_shop.py\"])) as shop:\n        listed = (await shop.list_tools()).tools\n        tools = [{\"name\": t.name, \"description\": t.description, \"input_schema\": t.input_schema} for t in listed]\n        read_only = {t.name for t in listed if t.annotations and t.annotations.read_only_hint}\n        messages = [{\"role\": \"user\", \"content\": question}]\n        extra = {\"system\": RULES} if rules else {}\n        seen = set()\n",
      "note": "**As ferramentas do servidor viram as ferramentas do modelo.** Os nomes, as descrições e os esquemas vêm do `tools/list`, e o host guarda quais dizem que só leem."
    },
    {
      "code": "        for step in range(1, MAX_STEPS + 1):\n            r = model.messages.create(model=\"llama3.2:3b\", max_tokens=500, tools=tools, messages=messages,\n                                      extra_body={\"temperature\": 0}, **extra)\n            sent.append(r.usage.input_tokens + (r.usage.cache_read_input_tokens or 0))\n            messages.append({\"role\": \"assistant\", \"content\": [b.model_dump(exclude_none=True) for b in r.content]})\n            for b in r.content:\n                if b.type == \"text\":\n                    print(f\"[{step}] model:  {b.text}\")\n            if r.stop_reason != \"tool_use\":\n                return\n",
      "note": "**Um passo é uma requisição**: o modelo vê tudo até ali e ou responde ou pede ferramentas. Sem `tool_use` quer dizer que respondeu, e o laço termina. Temperatura 0, como na aula 6, para uma nova rodada quase sempre seguir o mesmo caminho, e os tokens de entrada de cada requisição são guardados para a última linha."
    },
    {
      "code": "            results = []\n            for b in r.content:\n                if b.type != \"tool_use\":\n                    continue\n                print(f\"[{step}] call:   {b.name}({json.dumps(b.input)})\")\n                call = (b.name, json.dumps(b.input, sort_keys=True))\n                if call in seen:\n                    print(f\"[{step}] host:   the same call twice in one task; stopping\")\n                    return\n                seen.add(call)\n                if b.name not in read_only and not approve(b.name, b.input):\n                    text, error = \"refused by the operator\", True\n                else:\n                    result = await shop.call_tool(b.name, b.input)\n                    text, error = result.content[0].text, result.is_error\n                print(f\"[{step}] result: {' '.join(text.split())[:72]}\")\n                results.append({\"type\": \"tool_result\", \"tool_use_id\": b.id, \"content\": text, \"is_error\": error})\n            if remind:\n                results.append({\"type\": \"text\", \"text\": REMIND})\n            messages.append({\"role\": \"user\", \"content\": results})\n",
      "note": "**Cada chamada passa pelas guardas**: recusada se repetida, segurada para aprovação se muda alguma coisa, senão feita pelo MCP. O resultado, erro ou não, volta ao modelo como um `tool_result`, todos os resultados de um passo numa mensagem só."
    },
    {
      "code": "        print(f\"host: stopped after {MAX_STEPS} steps without an answer\")\n\n\n",
      "note": "**Ficar sem passos é informado**, não escondido atrás de uma resposta inventada."
    },
    {
      "code": "question = [a for a in sys.argv[1:] if not a.startswith(\"--\")][0]\nasyncio.run(run(question, \"--rules\" in sys.argv, \"--remind\" in sys.argv))\nprint(f\"host: {len(sent)} requests, {sum(sent)} input tokens: {sent}\")\n",
      "note": "**Quanto a tarefa custou**, em requisições e tokens de entrada, impresso como quer que ela tenha terminado."
    }
  ]
}
```

## Uma pergunta que precisa de duas ferramentas

Saber se um cliente ainda pode devolver o pedido 1042 exige dois fatos: quando o pedido foi entregue,
que o `get_order` sabe, e quanto dura o prazo de devolução, que a página de devoluções diz.

```
ana@dev:~/shop$ python agent.py "Can the customer of order 1042 still return it?"
[1] call:   get_order({"order_id": "1042"})
[1] result: { "status": "delivered", "delivered_on": "2026-09-28", "lines": [ { "sku
[2] model:  Unfortunately, the customer of order 1042 is no longer able to return the order. According to the order status, the order was delivered on September 28, 2026, which means that the return window has expired. If you have any further questions or concerns, please let me know.
host: 2 requests, 455 input tokens: [289, 166]
```

Dois passos. **Passo 1**: o modelo pede o pedido. **Passo 2**: com a data de entrega na conversa, ele
responde, e o `stop_reason` não é mais `tool_use`, então o laço termina.

Leia a resposta contra os resultados das ferramentas. A data de entrega, 28 de setembro, veio do
`get_order`. Que o prazo "has expired" não veio de lugar nenhum: o modelo nunca leu a página de
devoluções, então não sabe que o prazo é de 30 dias, e nada lhe disse que dia é hoje, então não teria
como contar até 30 de qualquer jeito. A gravação foi feita em 7 de outubro, nove dias depois da
entrega; a resposta está errada. **Todo fato na resposta de um agente deveria ter um resultado de
ferramenta por trás**, que é o que torna a resposta conferível do mesmo jeito que a aula 6 seção 08
conferiu citações, e esta tem um de três.

Há um motivo para ele não ter seguido até a página de devoluções, e não está no modelo. Veja a última
linha: a segunda requisição levou 166 tokens de entrada, menos que a primeira, embora leve tudo o que
a primeira levava mais o pedido. Alguma coisa saiu. O Ollama transforma a conversa num prompt longo
com um **template** que pertence ao modelo, e o do `llama3.2:3b` põe as definições das ferramentas
num lugar só:

```
ana@dev:~/shop$ ollama show llama3.2:3b --template | sed -n 13,25p
{{- if eq .Role "user" }}<|start_header_id|>user<|end_header_id|>
{{- if and $.Tools $last }}

Given the following functions, please respond with a JSON for a function call with its proper arguments that best answers the given prompt.

Respond in the format {"name": function name, "parameters": dictionary of argument name and its value}. Do not use variables.

{{ range $.Tools }}
{{- . }}
{{ end }}
{{ .Content }}<|eot_id|>
{{- else }}
```

`if and $.Tools $last`: **as ferramentas só são listadas dentro da última mensagem, e só quando essa
mensagem é do usuário.** Depois de um resultado de ferramenta a última mensagem é o resultado, então
no passo 2 o modelo não viu ferramenta nenhuma. Só podia responder. Toda requisição deste host tem o
mesmo formato, então com este modelo neste servidor um agente tem uma rodada de ferramentas, e o que
ele pedir nessa rodada é tudo o que vai ter. A aula 7 seção 09 mostra o que acontece quando o host
põe as ferramentas de volta na frente dele.

Então a ana nomeia os dois passos na pergunta, e o modelo pede tudo de uma vez:

```
ana@dev:~/shop$ python agent.py "Look up order 1042 and the returns page of the handbook, then tell me whether the customer can still return it."
[1] call:   get_order({"order_id": "1042"})
[1] result: { "status": "delivered", "delivered_on": "2026-09-28", "lines": [ { "sku
[1] call:   read_handbook({"name": "returns"})
[1] result: # Returns and refunds A customer may return any item within 30 days of d
[1] call:   issue_refund({"order_id": "1042", "cents": "0"})
allow issue_refund({"order_id": "1042", "cents": "0"})? [y/N] 
[1] result: refused by the operator
[2] model:  It seems like the tool call was refused by the operator. The output indicates that the customer is no longer eligible for a return, as it has been 30 days since delivery. However, if the item is faulty, it may still be covered by the warranty.
host: 2 requests, 696 input tokens: [302, 394]
```

**Três chamadas num passo só**, o que a API permite e o laço trata: todo bloco `tool_use` da resposta
é executado, e todos os resultados voltam juntos. É também o único jeito de este modelo usar duas
ferramentas, dada a rodada única dele. Duas são as que ela pediu. A terceira é `issue_refund`, num
valor de `"0"`, que ninguém pediu. Ela não é só leitura, então o host a segurou para aprovação;
ninguém estava no teclado, e o host leu isso como não. A resposta que vem depois está errada de novo,
pelo mesmo motivo da primeira: agora tem os 30 dias e continua sem o hoje, e diz que 30 dias se
passaram.

Duas coisas de duas rodadas. **O host é o que ficou entre uma pergunta e um reembolso**, que é o
assunto da aula 7 seção 08. E um fato de que o modelo precisa e que nenhuma ferramenta dá, como a
data, tem de vir do host; a aula 7 seção 09 o acrescenta.

## O que o código faz e o modelo não consegue

- **Ele para.** O `MAX_STEPS` é um limite rígido, imposto por um laço `for` e não pedido num prompt.
- **Ele recusa repetições.** A mesma chamada duas vezes na mesma tarefa quase sempre é um laço de que
  o modelo não sai sozinho; a aula 7 seção 09 mostra a guarda disparando.
- **Ele pergunta antes de agir.** Uma ferramenta não marcada como só leitura não é chamada até uma
  pessoa dizer sim, e acima ela não foi chamada; a aula 7 seção 08 mostra as duas respostas.
- **Ele informa erros como resultados.** Uma ferramenta que falha devolve `is_error` ao modelo, que
  pode tentar outra coisa, em vez de derrubar o host.
