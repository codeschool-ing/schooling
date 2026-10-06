---
title: O laço, com suas guardas
version: 1
---

O `Agent.run` é o laço da aula 1 com o orçamento da aula 5 e a contabilidade de que uma execução real precisa. Leia-o contra as versões anteriores: nada nele é novo, e tudo está num lugar só.

```schooling-example
{
  "language": "python",
  "file": "minagent.py",
  "parts": [
    {
      "code": "# ---------------------------------------------------------------- the loop\n\n@dataclass\n"
    },
    {
      "code": "class Outcome:\n    status: str  # \"answered\" or \"stopped\"\n    answer: str | None\n    reason: str | None\n    steps: int\n    tokens: int\n    trace: list = field(repr=False)\n\n\n",
      "note": "**Toda execução termina num destes**: respondida ou parada, a resposta ou o motivo, os passos, os tokens e o rastro."
    },
    {
      "code": "class Agent:\n    def __init__(self, model, system, tools, max_steps=8, max_tokens=20000, max_seconds=60,\n                 confirm=None, trace_path=None):\n        self.model, self.system = model, system\n        self.tools = {t.name: t for t in tools}\n",
      "note": "**O agente é configuração**: um modelo, um prompt de sistema, ferramentas, três limites, um callback de confirmação e um arquivo de rastro. Nada nele muda durante uma execução, a não ser a conversa."
    },
    {
      "code": "        self.validators = {t.name: Draft202012Validator(t.schema) for t in tools}\n        self.max_steps, self.max_tokens, self.max_seconds = max_steps, max_tokens, max_seconds\n        self.confirm, self.trace_path = confirm, trace_path\n\n",
      "note": "**Os validadores são montados uma vez por ferramenta**, não uma vez por chamada."
    },
    {
      "code": "    def run(self, task):\n        messages, trace, seen = [{\"role\": \"user\", \"content\": task}], [], set()\n        used, started, failing = 0, time.monotonic(), 0\n        definitions = [t.definition() for t in self.tools.values()]\n        for step in range(1, self.max_steps + 1):\n",
      "note": "**O estado de uma execução é local**: a conversa, o rastro, as chamadas já feitas, os tokens usados, o relógio e uma contagem de passos que falharam."
    },
    {
      "code": "            if used >= self.max_tokens:\n                return self.stop(f\"token budget: {used} of {self.max_tokens}\", step - 1, used, trace)\n            if time.monotonic() - started >= self.max_seconds:\n                return self.stop(f\"time budget: {self.max_seconds} s\", step - 1, used, trace)\n",
      "note": "**Os três limites, conferidos antes de cada pedido**, então uma execução estoura no máximo um passo (aula 5)."
    },
    {
      "code": "            if failing >= 3:\n                return self.stop(\"no progress: 3 steps in a row with only errors\", step - 1, used, trace)\n",
      "note": "**Uma quarta parada: falta de progresso.** Três passos seguidos em que toda chamada falhou quer dizer que o modelo travou, diga o limite de passos o que disser."
    },
    {
      "code": "            t0 = time.monotonic()\n            reply = self.model.complete(self.system, messages, definitions)\n            used += reply.tokens_in + reply.tokens_out\n            record = {\"step\": step, \"stop\": reply.stop, \"tokens_in\": reply.tokens_in,\n                      \"tokens_out\": reply.tokens_out, \"model_ms\": int((time.monotonic() - t0) * 1000),\n                      \"text\": reply.text, \"calls\": []}\n            messages.append({\"role\": \"assistant\", \"content\": reply.content})\n",
      "note": "**Cada passo é cronometrado**, e o registro dele começa aqui."
    },
    {
      "code": "            if not reply.calls:\n                self.record(trace, record)\n                return Outcome(\"answered\", reply.text, None, step, used, trace)\n            results = []\n",
      "note": "**Nenhuma chamada de ferramenta quer dizer resposta.** O `minagent` mantém a convenção da aula 1 em vez da ferramenta `finish` da aula 5, para continuar pequeno; acrescentar `finish` é uma ferramenta e um `if`."
    },
    {
      "code": "            for call in reply.calls:\n                t1 = time.monotonic()\n                content, is_error = self.call(call, seen)\n                record[\"calls\"].append({\"tool\": call.name, \"args\": call.args, \"error\": is_error,\n                                        \"ms\": int((time.monotonic() - t1) * 1000), \"result\": content[:120]})\n                results.append({\"type\": \"tool_result\", \"tool_use_id\": call.id, \"content\": content,\n                                \"is_error\": is_error})\n",
      "note": "**Toda chamada passa pelo `call`**, que nunca levanta erro numa falha que o modelo poderia corrigir. Cada uma é cronometrada e registrada."
    },
    {
      "code": "            failing = failing + 1 if all(c[\"error\"] for c in record[\"calls\"]) else 0\n            self.record(trace, record)\n            messages.append({\"role\": \"user\", \"content\": results})\n        return self.stop(f\"step limit: {self.max_steps}\", self.max_steps, used, trace)\n",
      "note": "**O contador de progresso** zera no momento em que qualquer chamada de um passo dá certo."
    }
  ]
}
```

## Para onde foi cada aula

| aula | ideia | no `run` |
|---|---|---|
| 1 | a conversa é o estado; o laço a manda inteira a cada vez | `messages`, anexada duas vezes por passo |
| 3 | registrar cada passo; proteger contra repetição | `record`, `seen` |
| 4 | validar antes de rodar; erros são resultados | `self.validators`, `call` |
| 5 | orçamentos conferidos antes do pedido; dizer por que parou | os três `if`s do começo, `stop` |
| 6 | um agente é um laço com as próprias ferramentas e o próprio prompt | o `Agent` é esse laço como objeto, para que um orquestrador possa ter vários |

Os desenhos multiagente da aula 6 encaixam direto nisto. Um especialista é um `Agent`; consultá-lo é uma `@tool` cuja função chama `specialist.run(question)` e devolve a resposta, ou a resposta e os resultados do rastro como evidência.
