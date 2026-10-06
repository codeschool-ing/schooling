---
title: Um orquestrador e dois especialistas
version: 1
---

O `multi.py` monta os três desenhos que esta aula compara a partir de uma função, `loop`, que é o laço de agente da aula 4 tornado reutilizável: um nome, um prompt de sistema, um conjunto de ferramentas e uma conversa. **As decisões e as palavras dos agentes foram escritas pelo curso** como regras para o substituto; a delegação, os laços separados, as ferramentas e seus resultados são reais.

```schooling-example
{
  "language": "python",
  "file": "multi.py",
  "parts": [
    {
      "code": "\"\"\"Several agents: an orchestrator that delegates to specialists, a triage agent that hands over, or one agent alone.\"\"\"\nimport json\nimport sys\n\nimport anthropic\n\nimport shop\nfrom tools import TOOLS as SHOP_TOOLS, run_tool\n\nclient = anthropic.Anthropic()\nBY_NAME = {t[\"name\"]: t for t in SHOP_TOOLS}\n"
    },
    {
      "code": "SEARCH_HELP = {\"name\": \"search_help\", \"description\": \"Search Marginalia's help centre and return the three closest articles.\",\n               \"input_schema\": {\"type\": \"object\", \"additionalProperties\": False, \"required\": [\"query\"],\n                                \"properties\": {\"query\": {\"type\": \"string\"}}}}\nQUESTION = {\"type\": \"object\", \"additionalProperties\": False, \"required\": [\"question\"],\n            \"properties\": {\"question\": {\"type\": \"string\"}}}\n",
      "note": "**Uma definição de ferramenta** para a busca na central de ajuda, que o `tools.py` da aula 4 não traz."
    },
    {
      "code": "EVIDENCE = \"--evidence\" in sys.argv\n\n\ndef shop_tool(name, args):\n    if name == \"search_help\":\n        return json.dumps([{\"title\": a[\"title\"], \"body\": a[\"body\"]} for a in shop.search_help(args[\"query\"])]), False\n    return run_tool(name, args)\n\n\n",
      "note": "**Uma chave para a seção 08.**"
    },
    {
      "code": "def loop(name, system, tools, messages, run, depth=0):\n    \"\"\"One agent: its own system prompt, its own tools, its own conversation. Returns (answer, evidence).\"\"\"\n    pad, evidence = \"    \" * depth, []\n    for step in range(1, 6):\n        reply = client.messages.create(model=\"scripted-1\", max_tokens=1024, system=system,\n                                       tools=tools, messages=messages)\n        messages.append({\"role\": \"assistant\", \"content\": reply.content})\n        calls = [b for b in reply.content if b.type == \"tool_use\"]\n        if not calls:\n            answer = \" \".join(b.text for b in reply.content if b.type == \"text\")\n            print(f\"{pad}{name}: {answer}\")\n            return answer, evidence\n        results = []\n        for b in calls:\n            print(f\"{pad}{name} -> {b.name}({json.dumps(b.input)})\")\n            text, is_error = run(b.name, b.input, depth)\n",
      "note": "**Um agente.** O próprio prompt de sistema, as próprias ferramentas, as próprias `messages`. O `depth` só indenta a saída, para você ver quem está falando."
    },
    {
      "code": "            evidence.append(f\"{b.name} {json.dumps(b.input)} -> {text[:110]}\")\n            results.append({\"type\": \"tool_result\", \"tool_use_id\": b.id, \"content\": text, \"is_error\": is_error})\n        messages.append({\"role\": \"user\", \"content\": results})\n    return f\"{name} stopped after 5 steps\", evidence\n\n\n",
      "note": "**Toda chamada e o começo do resultado dela ficam guardados**, alguém peça ou não."
    },
    {
      "code": "SPECIALISTS = {\n    \"orders\": (\"You are Marginalia's orders specialist. Answer the question about orders with your tools, \"\n               \"in two sentences at most.\", [BY_NAME[\"get_order\"], SEARCH_HELP]),\n    \"catalogue\": (\"You are Marginalia's catalogue specialist. Answer the question about books with your tools, \"\n                  \"in two sentences at most.\", [BY_NAME[\"find_books\"]]),\n}\n\n\n",
      "note": "**Dois especialistas, cada um só com as suas ferramentas.** Pedidos recebe `get_order` e a central de ajuda; catálogo recebe `find_books` e mais nada."
    },
    {
      "code": "def ask(specialist, question, depth):\n    \"\"\"A specialist used as a tool: it gets the question only, and its answer is the tool's result.\"\"\"\n    system, tools = SPECIALISTS[specialist]\n    answer, evidence = loop(specialist, system, tools, [{\"role\": \"user\", \"content\": question}],\n                            lambda n, a, d: shop_tool(n, a), depth + 1)\n    if EVIDENCE:\n        answer += \"\\nEvidence:\\n\" + \"\\n\".join(evidence)\n    return answer, False\n\n\n",
      "note": "**Um especialista usado como ferramenta.** Ele começa uma conversa nova só com a pergunta, e a resposta dele vira o resultado da ferramenta."
    },
    {
      "code": "def orchestrate(task):\n    tools = [{\"name\": \"ask_orders\", \"description\": \"Ask the orders specialist one question about orders.\",\n              \"input_schema\": QUESTION},\n             {\"name\": \"ask_catalogue\", \"description\": \"Ask the catalogue specialist one question about books.\",\n              \"input_schema\": QUESTION}]\n    system = (\"You are Marginalia's support orchestrator. Delegate: ask_orders for anything about an order, \"\n              \"ask_catalogue for books. Then answer the customer.\")\n    loop(\"orchestrator\", system, tools, [{\"role\": \"user\", \"content\": task}],\n         lambda n, a, d: ask(n.removeprefix(\"ask_\"), a[\"question\"], d))\n\n\n",
      "note": "**As ferramentas do orquestrador são os especialistas**: `ask_orders` e `ask_catalogue`, cada uma recebendo uma pergunta."
    },
    {
      "code": "def triage(task):\n    \"\"\"Handoff: the triage agent transfers control, and the specialist answers the customer itself.\"\"\"\n    messages = [{\"role\": \"user\", \"content\": task}]\n    tools = [{\"name\": f\"transfer_to_{s}\", \"description\": f\"Hand this conversation to the {s} specialist.\",\n              \"input_schema\": {\"type\": \"object\", \"properties\": {}}} for s in SPECIALISTS]\n    reply = client.messages.create(model=\"scripted-1\", max_tokens=200, tools=tools, messages=messages,\n                                   system=\"You are Marginalia's triage agent. Transfer the conversation to the right specialist.\")\n    call = next(b for b in reply.content if b.type == \"tool_use\")\n    target = call.name.removeprefix(\"transfer_to_\")\n    print(f\"triage hands the conversation to {target}\")\n    system, specialist_tools = SPECIALISTS[target]\n    loop(target, system, specialist_tools, [{\"role\": \"user\", \"content\": task}], lambda n, a, d: shop_tool(n, a))\n\n\n",
      "note": "**Passagem**: um pedido para decidir, depois o laço do especialista roda sobre a mensagem do cliente e a responde."
    },
    {
      "code": "def alone(task):\n    tools = [BY_NAME[\"get_order\"], SEARCH_HELP, BY_NAME[\"find_books\"]]\n    loop(\"agent\", \"You are Marginalia's support agent, working alone. Use the tools, then answer.\", tools,\n         [{\"role\": \"user\", \"content\": task}], lambda n, a, d: shop_tool(n, a))\n\n\nif __name__ == \"__main__\":\n    mode = \"--handoff\" in sys.argv and triage or \"--single\" in sys.argv and alone or orchestrate\n    mode(sys.argv[1])",
      "note": "**A linha de base**: um agente com as três ferramentas."
    }
  ]
}
```

Um cliente pergunta duas coisas sem relação de uma vez:

```
ana@lab:~/agents$ python multi.py "Did my order M-1043 ship yet? Also, can you suggest a science fiction book you have in stock?"
orchestrator -> ask_orders({"question": "Has order M-1043 shipped?"})
    orders -> get_order({"order_id": "M-1043"})
    orders: Yes, M-1043 has shipped and is not delivered yet. Its tracking code is BR5512340003.
orchestrator -> ask_catalogue({"question": "Which science fiction books are in stock?"})
    catalogue -> find_books({"genre": "science fiction"})
    catalogue: In stock: The Time Machine by H. G. Wells at 24.90 and The War of the Worlds by H. G. Wells at 25.90.
orchestrator: Yes, order M-1043 has shipped; its tracking code is BR5512340003. For science fiction, we have The Time Machine (24.90) and The War of the Worlds (25.90), both by H. G. Wells, in stock.
```

A indentação é a delegação. O orquestrador consultou os dois especialistas numa resposta, como o agente da aula 4 pediu dois pedidos de uma vez. Cada especialista rodou o próprio laço: uma chamada de ferramenta, uma resposta. O orquestrador leu as duas respostas como resultados de ferramenta e escreveu a resposta ao cliente.

Repare no que cada especialista recebeu: *"Has order M-1043 shipped?"* e *"Which science fiction books are in stock?"* Nenhum dos dois viu a mensagem do cliente. **O orquestrador reescreveu a tarefa em duas perguntas**, e todo o conhecimento de cada especialista sobre a conversa é essa frase. A seção 07 é sobre essa fronteira.
