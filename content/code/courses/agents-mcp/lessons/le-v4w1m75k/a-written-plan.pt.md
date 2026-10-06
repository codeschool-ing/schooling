---
title: Um plano que o hospedeiro lê
version: 1
---

O `agent.py` desta aula acrescenta duas ferramentas às da aula 4: `update_plan`, que recebe a lista inteira de passos com um status para cada um, e `finish`, que recebe a resposta final e as chamadas de ferramenta em que ela se apoia. Ele também roda cada pedido dentro de um orçamento, que a seção 04 explica. **Os planos, as chamadas e as respostas desta seção foram escritos pelo curso** como regras para o substituto; o tratamento que o hospedeiro dá a eles é real.

```schooling-example
{
  "language": "python",
  "file": "agent.py",
  "parts": [
    {
      "code": "\"\"\"An agent that keeps a written plan, answers through finish, and runs inside a budget set by the host.\"\"\"\nimport argparse\nimport json\nimport time\n\nimport anthropic\n\nfrom tools import TOOLS as SHOP_TOOLS, run_tool\n\n"
    },
    {
      "code": "PLAN_TOOLS = [\n    {\"name\": \"update_plan\",\n     \"description\": \"Write or rewrite your plan: the whole list of steps, each with a status.\",\n     \"input_schema\": {\"type\": \"object\", \"additionalProperties\": False, \"required\": [\"steps\"],\n                      \"properties\": {\"steps\": {\"type\": \"array\", \"minItems\": 1, \"maxItems\": 8, \"items\": {\n                          \"type\": \"object\", \"additionalProperties\": False, \"required\": [\"step\", \"status\"],\n                          \"properties\": {\"step\": {\"type\": \"string\"},\n                                         \"status\": {\"enum\": [\"todo\", \"done\", \"dropped\"]}}}}}}},\n",
      "note": "**O plano como esquema**: até oito passos, cada um `todo`, `done` ou `dropped`. Nada mais é status válido, então um plano é sempre legível pelo código."
    },
    {
      "code": "    {\"name\": \"finish\",\n     \"description\": \"Give the final answer to the customer, and list the tool calls it rests on.\",\n     \"input_schema\": {\"type\": \"object\", \"additionalProperties\": False, \"required\": [\"answer\", \"sources\"],\n                      \"properties\": {\"answer\": {\"type\": \"string\", \"minLength\": 1},\n                                     \"sources\": {\"type\": \"array\", \"items\": {\"type\": \"string\"}}}}},\n]\n",
      "note": "**A resposta como chamada de ferramenta.** A execução acaba quando o modelo chama isto, com uma resposta e suas fontes, não quando ele por acaso para de escrever."
    },
    {
      "code": "TOOLS = [t for t in SHOP_TOOLS if t[\"name\"] != \"issue_refund\"] + PLAN_TOOLS\n",
      "note": "**As ferramentas da aula 4 menos o `issue_refund`**, mais as duas acima. Um agente recebe só o que a tarefa dele precisa."
    },
    {
      "code": "SYSTEM = (\"You are Marginalia's support agent. Keep a plan with update_plan before you start and whenever \"\n          \"it changes. Use the tools to find facts. When you know the answer, call finish.\")\nMARKS = {\"todo\": \" \", \"done\": \"x\", \"dropped\": \"-\"}\n\n\n",
      "note": "**A instrução de planejar**: antes de começar, e sempre que o plano mudar."
    },
    {
      "code": "def stopped(reason, plan):\n    \"\"\"A run that did not finish still returns something a person can pick up.\"\"\"\n    done = [s[\"step\"] for s in plan if s[\"status\"] == \"done\"]\n    todo = [s[\"step\"] for s in plan if s[\"status\"] == \"todo\"]\n    return {\"status\": \"stopped\", \"reason\": reason, \"done\": done, \"not_done\": todo,\n            \"handoff\": \"Passed to a person. \" + (f\"Done: {'; '.join(done)}. \" if done else \"\")\n                       + (f\"Not done: {'; '.join(todo)}.\" if todo else \"No plan was written.\")}\n\n\n",
      "note": "**O que uma execução que não terminou devolve**: o que foi feito, o que não foi, e uma frase para uma pessoa. Seção 06."
    },
    {
      "code": "def run(task, max_steps, max_tokens, max_seconds):\n    client = anthropic.Anthropic()\n    messages = [{\"role\": \"user\", \"content\": task}]\n    plan, used, started = [], 0, time.monotonic()\n    for step in range(1, max_steps + 1):\n",
      "note": "**Os três contadores do orçamento**: passos, tokens e segundos."
    },
    {
      "code": "        if used >= max_tokens:\n            return stopped(f\"token budget: {used} of {max_tokens} used\", plan)\n        if time.monotonic() - started >= max_seconds:\n            return stopped(f\"time budget: {max_seconds} s\", plan)\n        reply = client.messages.create(model=\"scripted-1\", max_tokens=1024, system=SYSTEM,\n                                       tools=TOOLS, messages=messages)\n        used += reply.usage.input_tokens + reply.usage.output_tokens\n        messages.append({\"role\": \"assistant\", \"content\": reply.content})\n        results = []\n        for block in reply.content:\n            if block.type != \"tool_use\":\n                continue\n",
      "note": "**Conferido antes de cada pedido**, nunca depois. A seção 04 diz por que a ordem importa."
    },
    {
      "code": "            if block.name == \"finish\":\n                return {\"status\": \"answered\", \"steps\": step, \"tokens\": used,\n                        \"answer\": block.input[\"answer\"], \"sources\": block.input[\"sources\"]}\n",
      "note": "**O único caminho para um resultado `answered`.**"
    },
    {
      "code": "            if block.name == \"update_plan\":\n                plan = block.input[\"steps\"]\n                print(f\"[{step}] plan\")\n                for s in plan:\n                    print(f\"      [{MARKS[s['status']]}] {s['step']}\")\n                text, is_error = \"plan recorded\", False\n            else:\n                text, is_error = run_tool(block.name, block.input)\n                print(f\"[{step}] {block.name}({json.dumps(block.input)}) -> {'ERROR ' if is_error else ''}{text[:60]}\")\n            results.append({\"type\": \"tool_result\", \"tool_use_id\": block.id, \"content\": text, \"is_error\": is_error})\n",
      "note": "**O hospedeiro guarda o plano e o imprime.** O resultado da ferramenta é um recibo, `plan recorded`."
    },
    {
      "code": "        if not results:\n            return stopped(\"replied without calling finish\", plan)\n        messages.append({\"role\": \"user\", \"content\": results})\n    return stopped(f\"step limit: {max_steps}\", plan)\n\n\nif __name__ == \"__main__\":\n    p = argparse.ArgumentParser()\n    p.add_argument(\"task\")\n    p.add_argument(\"--max-steps\", type=int, default=8)\n    p.add_argument(\"--max-tokens\", type=int, default=20000)\n    p.add_argument(\"--max-seconds\", type=float, default=60)\n    a = p.parse_args()\n    print(json.dumps(run(a.task, a.max_steps, a.max_tokens, a.max_seconds), indent=1, ensure_ascii=False))",
      "note": "**Uma resposta sem chamada de ferramenta é uma parada**, não uma resposta: o modelo foi instruído a responder por `finish`."
    }
  ]
}
```

Um cliente pergunta duas coisas de uma vez: um presente para um sobrinho que gosta de histórias de aventura, e se o pedido M-1045 está a caminho.

```
ana@lab:~/agents$ python agent.py "I need a gift for my nephew, who loves adventure stories. And is my order M-1045 on its way?"
[1] plan
      [ ] Look up order M-1045
      [ ] Find adventure books in stock
      [ ] Answer both questions
[2] get_order({"order_id": "M-1045"}) -> {"id": "M-1045", "customer_id": "c-104", "placed_on": "2026-
[3] plan
      [x] Look up order M-1045
      [ ] Find adventure books in stock
      [ ] Answer both questions
[3] find_books({"genre": "adventure"}) -> [{"id": "b31", "title": "Moby-Dick", "author": "Herman Melvi
{
 "status": "answered",
 "steps": 4,
 "tokens": 2806,
 "answer": "Your order M-1045 is packed and will leave our warehouse soon; the tracking link comes by email when it ships. For a nephew who likes adventure, we have Moby-Dick by Herman Melville at 49.90 and The Count of Monte Cristo by Alexandre Dumas at 59.90 in stock.",
 "sources": [
  "get_order M-1045",
  "find_books adventure"
 ]
}
```

Quatro passos. O passo 1 escreveu um plano de três itens; o passo 2 fez o primeiro item; o passo 3 atualizou o plano **e** buscou livros na mesma resposta; o passo 4 chamou `finish`. O resultado é um objeto JSON que o hospedeiro montou, `"status": "answered"`, com a resposta e as duas fontes que o modelo citou. As duas metades do pedido foram respondidas, e o plano é o motivo de a segunda metade não ter sido esquecida depois da primeira.

A resposta diz que o M-1045 está embalado e lista Moby-Dick a 49,90 e O Conde de Monte Cristo a 59,90; os dois fatos estão nos resultados de `get_order` e `find_books`, que o rastro mostra sendo chamados. O `sources` deixa um revisor, ou um teste, conferir isso sem ler a conversa inteira.
