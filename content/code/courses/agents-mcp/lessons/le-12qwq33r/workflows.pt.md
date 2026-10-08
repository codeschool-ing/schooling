---
title: Workflows, em que um passo dispensa modelo
version: 1
---

A aula 5 separou agentes, que decidem os próprios passos, de workflows, cujos passos são fixos no código. O ADK tem agentes de workflow para o segundo tipo, `SequentialAgent`, `ParallelAgent` e `LoopAgent`, que rodam subagentes um depois do outro, todos ao mesmo tempo ou em laço, numa ordem fixa no código. Nesta versão o primeiro deles anuncia o próprio substituto:

```
ana@lab:~/agents$ python -c 'from google.adk.agents import SequentialAgent; SequentialAgent(name="pipeline", sub_agents=[])'
<string>:1: DeprecationWarning: SequentialAgent is deprecated in favor of Workflow and will be removed in a future version. Workflow cannot yet be used as an LlmAgent sub-agent.
```

O substituto é o `Workflow`, um grafo de nós ligados por arestas, e um nó pode ser um agente **ou uma função simples**. O `adk_pipeline.py` usa um de cada:

```schooling-example
{
  "language": "python",
  "file": "adk_pipeline.py",
  "parts": [
    {
      "code": "\"\"\"A fixed two-step workflow: plain code finds the facts, then an agent writes the reply from them.\"\"\"\nimport asyncio\nimport json\nimport re\n\nfrom google.adk.agents import Agent\nfrom google.adk.models.lite_llm import LiteLlm\nfrom google.adk.runners import InMemoryRunner\nfrom google.adk.workflow import START, Workflow\nfrom google.genai.types import Content, Part\n\nimport shop\nfrom adk_show import show\n\nMODEL = LiteLlm(model=\"ollama_chat/llama3.2:3b\")\n\n\n"
    },
    {
      "code": "def find_facts(node_input: str) -> str:\n    \"\"\"No model: the order id is a pattern, and the facts are a lookup.\"\"\"\n",
      "note": "**Um nó que é uma função.** Ele recebe a saída do nó anterior, aqui a mensagem do cliente."
    },
    {
      "code": "    order = shop.get_order(re.search(r\"M-[0-9]{4}\", node_input).group(0))\n    return json.dumps({k: order[k] for k in (\"id\", \"status\", \"delivered_on\")})\n\n\n",
      "note": "**Sem modelo**: o id do pedido é um padrão e os fatos são uma consulta, então o código faz isso, sempre do mesmo jeito."
    },
    {
      "code": "writer = Agent(name=\"writer\", model=MODEL,\n               instruction=\"You write the customer's reply in the Google ADK lesson, from the facts you are given.\")\n",
      "note": "**Um nó que é um agente**, que escreve a resposta."
    },
    {
      "code": "pipeline = Workflow(name=\"pipeline\", edges=[(START, find_facts, writer)])",
      "note": "**O grafo**: do início para a função, da função para o agente."
    },
    {
      "code": "\n\n\nasync def main():\n    runner = InMemoryRunner(agent=pipeline, app_name=\"marginalia\")\n    session = await runner.session_service.create_session(app_name=\"marginalia\", user_id=\"bia\")\n    async for event in runner.run_async(user_id=\"bia\", session_id=session.id,\n                                        new_message=Content(role=\"user\", parts=[Part(text=\"When was M-1042 delivered?\")])):\n        show(event)\n\n\nasyncio.run(main())"
    }
  ]
}
```

```
ana@lab:~/agents$ python adk_pipeline.py 2> /dev/null
pipeline output  {"id": "M-1042", "status": "delivered", "delivered_on": "2026-09-24"}
writer   text    Your order M-1042 was delivered on 24 September 2026. If anything is wrong with it, reply to this email and we will help.
ana@lab:~/agents$ python -c 'import json; [print(json.dumps(c, ensure_ascii=False)) for l in open("/var/log/labllm/requests.jsonl") for c in json.loads(l)["request"]["contents"]]'
{"parts": [{"text": "{\"id\": \"M-1042\", \"status\": \"delivered\", \"delivered_on\": \"2026-09-24\"}"}], "role": "user"}
```

A saída da função aparece como evento do workflow, e o escritor respondeu a partir dela. O segundo comando imprime tudo o que o modelo recebeu no único pedido da execução: **uma mensagem de usuário, os fatos em JSON**. Não a pergunta do cliente, nem instrução nenhuma para consultar coisa alguma. Achar um pedido não precisava de modelo, então nenhum modelo foi consultado, e o modelo que escreveu a resposta só podia usar os fatos que recebeu, que é o argumento da aula 5 para pôr os passos fixos no código. Isso também corta para os dois lados: se a resposta precisasse das palavras do próprio cliente, a função teria de passá-las adiante, porque cada nó recebe só o que o anterior produziu.
