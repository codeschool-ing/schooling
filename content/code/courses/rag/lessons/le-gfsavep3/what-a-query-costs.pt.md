---
title: Quanto custa uma consulta
version: 1
---

Um provedor cobra por token: tokens que viram embedding, tokens mandados ao modelo, tokens que o modelo
escreve, muitas vezes com preço diferente para cada um, e os preços mudam. Então esta aula conta tokens e
deixa a multiplicação para a tabela de preços atual de quem lê, que é o único preço que vai estar certo
no dia em que a pessoa ler.

O `data/querylog.jsonl` é uma semana de perguntas feitas ao assistente de ajuda, 500 delas, geradas pelo
`lab/querylog.py` a partir de redações que o curso escreveu. O `priced.py` roda cada pergunta distinta
pelo pipeline da aula 7 uma vez, registra quanto custou, e soma a semana:

```schooling-example
{
  "language": "python",
  "file": "priced.py",
  "parts": [
    {
      "code": "import json\n\nimport tiktoken\nfrom answer import SYSTEM, prompt, sources_for\nfrom openai import OpenAI",
      "note": "O pipeline da aula 7, as instruções e o prompt dele, e o registro da semana."
    },
    {
      "code": "client = OpenAI()\nenc = tiktoken.get_encoding(\"cl100k_base\")\nLOG = [json.loads(line) for line in open(\"data/querylog.jsonl\")]",
      "note": "O cliente do provedor, e o tiktoken para contar o que o provedor não informa."
    },
    {
      "code": "def run(question):\n    \"\"\"What answering one question costs, in tokens, through lesson 7's pipeline.\"\"\"\n    sources = sources_for(question)\n    cost = {\"embedding\": len(enc.encode(question)), \"input\": 0, \"output\": 0, \"instructions\": 0, \"sources\": 0}\n    if sources:\n        user = prompt(question, sources)\n        reply = client.chat.completions.create(model=\"extract-1\", messages=[\n            {\"role\": \"system\", \"content\": SYSTEM}, {\"role\": \"user\", \"content\": user}])\n        cost.update(input=reply.usage.prompt_tokens, output=reply.usage.completion_tokens,\n                    instructions=len(enc.encode(SYSTEM)), sources=len(enc.encode(user)) - len(enc.encode(f\"Question: {question}\")))\n    return cost",
      "note": "Uma pergunta com preço: os tokens que viraram embedding para a busca, e, se alguma fonte passou do piso, os tokens do prompt e da resposta como o labgen os informa. Uma pergunta recusada antes do modelo custa só o embedding."
    },
    {
      "code": "if __name__ == \"__main__\":\n    costs = {text: run(text) for text in sorted({q[\"text\"] for q in LOG})}\n    json.dump(costs, open(\"costs.json\", \"w\"), indent=1)\n    total = {k: sum(costs[q[\"text\"]][k] for q in LOG) for k in (\"embedding\", \"input\", \"output\")}\n    calls = sum(1 for q in LOG if costs[q[\"text\"]][\"input\"])\n    print(f\"{len(LOG)} questions, {calls} model calls, {len(LOG) - calls} refused before the model\")\n    print(f\"embedding {total['embedding']:6} tokens\")\n    print(f\"input     {total['input']:6} tokens   {total['input'] / calls:.0f} per call\")\n    print(f\"output    {total['output']:6} tokens   {total['output'] / calls:.0f} per call\")",
      "note": "Cada pergunta distinta tem o preço calculado uma vez, e a semana é a soma sobre o registro. A mesma pergunta custa o mesmo toda vez que é feita, que é o que um cache vai aproveitar."
    }
  ]
}
```

```
ana@lab:~/rag$ python priced.py
500 questions, 486 model calls, 14 refused before the model
embedding   3551 tokens
input     145119 tokens   299 per call
output     22563 tokens   46 per call
```

**486 chamadas ao modelo para 500 perguntas.** Catorze foram recusadas antes do modelo, porque nenhuma
fonte passou do piso, e custaram só os poucos tokens do embedding delas; é a recusa da aula 7 se pagando.
As chamadas feitas custaram em média 299 tokens de entrada e 46 de saída, 145.119 e 22.563 na semana. Os
3.551 tokens de embedding são pouco perto disso, que é o formato de costume: é na geração que vai o
dinheiro de um pipeline de RAG, e gerar o embedding da pergunta quase não custa nada.

Duas coisas a tirar do formato antes de qualquer número. **A entrada é a maior parte**, uns seis tokens
de entrada para cada um de saída, porque um prompt de RAG leva fontes e uma resposta de atendimento é
curta. E **toda pergunta paga o preço inteiro** toda vez que é feita, mesmo quando a mesma pergunta foi
respondida um minuto antes. O resto da aula é sobre esses dois fatos.
