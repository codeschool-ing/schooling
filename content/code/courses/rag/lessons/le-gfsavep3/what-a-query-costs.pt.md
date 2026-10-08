---
title: Quanto custa uma consulta
version: 2
---

Um provedor cobra por token: tokens que viram embedding, tokens mandados ao modelo, tokens que o modelo
escreve, muitas vezes com preço diferente para cada um, e os preços mudam. Então esta aula conta tokens e
deixa a multiplicação para a tabela de preços atual de quem lê, que é o único preço que vai estar certo
no dia em que a pessoa ler.

O `data/querylog.jsonl` é uma semana de perguntas feitas ao assistente de ajuda, 500 delas, geradas a partir de
redações que o curso escreveu. Salve o gerador como `~/rag/querylog.py` e rode-o:

```schooling-example
{
  "language": "python",
  "file": "querylog.py",
  "parts": [
    {
      "code": "\"\"\"querylog: writes data/querylog.jsonl, a week of questions asked of the help assistant.\n\nTHE LOG IS GENERATED, NOT RECORDED, and nothing about it is measured from a\nreal shop. It is drawn with a fixed seed from PHRASINGS below, which were\nwritten by the course: each topic has a few ways people say it, and topics\nare drawn with Zipf-like weights (the first is asked most), because that is\nthe shape a support queue has. Lesson 17 measures caches against it, and\nwhat it measures is the cache, not Marginalia's customers.\n\"\"\"\nimport json\nimport random\nfrom datetime import datetime, timedelta\n\nPHRASINGS = [\n    [\"How many days do I have to return a printed book?\", \"how many days do I have to return a printed book?\",\n     \"how long do I have to return a book\", \"return window for books\", \"Can I still return a book I got 3 weeks ago?\"],\n    [\"How much is express delivery?\", \"how much is express delivery\", \"express shipping price\", \"what does next day delivery cost\"],\n    [\"How long after my return arrives will I get the refund?\", \"when do I get my refund\",\n     \"how long does a refund take\", \"refund timing after return\"],\n    [\"Above what order value is standard delivery free?\", \"free delivery threshold\", \"when is shipping free\"],\n    [\"On how many devices can I read my e-books?\", \"how many devices for ebooks\", \"ebook device limit\"],\n    [\"Can I cancel my order?\", \"how do I cancel an order\", \"cancel order\"],\n    [\"Can I cancel a pre-order?\", \"how do I cancel a pre-order\", \"cancel preorder\"],\n    [\"How long is a gift card valid?\", \"gift card expiry\", \"do gift cards expire\"],\n    [\"Will my e-books open on a Kindle?\", \"kindle ebooks\", \"can I read on kindle\"],\n    [\"Can I pay in instalments?\", \"pay in instalments\", \"split payment in three\"],\n    [\"When is a standard parcel considered lost?\", \"my parcel is lost\", \"parcel not arrived after two weeks\"],\n    [\"Who pays for the return postage?\", \"is returning free\", \"return shipping cost\"],\n]",
      "note": "Doze assuntos, cada um com os jeitos de perguntá-lo que o curso escreveu. O registro é gerado, não gravado: o que a aula 17 mede com ele é o cache, não os clientes da Marginalia."
    },
    {
      "code": "def main(out, n=500, seed=11):\n    rng = random.Random(seed)\n    weights = [1 / (k + 1) for k in range(len(PHRASINGS))]\n    users = [f\"u{i:03d}\" for i in range(1, 61)]\n    start = datetime(2026, 9, 21, 8, 0)\n    with open(out, \"w\") as f:\n        for i in range(n):\n            topic = rng.choices(range(len(PHRASINGS)), weights)[0]\n            text = rng.choice(PHRASINGS[topic])\n            at = start + timedelta(minutes=int(i * 7 * 24 * 60 / n) + rng.randrange(0, 15))\n            f.write(json.dumps({\"at\": at.strftime(\"%Y-%m-%dT%H:%M\"), \"user\": rng.choice(users),\n                                \"topic\": topic + 1, \"text\": text}) + \"\\n\")",
      "note": "Quinhentas perguntas ao longo de uma semana, sorteadas com uma semente fixa para que toda execução escreva o mesmo arquivo: assuntos com pesos que caem como os de uma fila de atendimento, uma redação, um horário e um de sessenta clientes."
    },
    {
      "code": "if __name__ == \"__main__\":\n    main(\"data/querylog.jsonl\")"
    }
  ]
}
```
```
ana@vm:~/rag$ python querylog.py
ana@vm:~/rag$ wc -l data/querylog.jsonl
500 data/querylog.jsonl
ana@vm:~/rag$ head -n 2 data/querylog.jsonl
{"at": "2026-09-21T08:07", "user": "u033", "topic": 2, "text": "what does next day delivery cost"}
{"at": "2026-09-21T08:22", "user": "u052", "topic": 8, "text": "How long is a gift card valid?"}
```
O `priced.py` roda cada pergunta distinta pelo pipeline da aula 7 uma vez, registra quanto custou, e
soma a semana:

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
      "code": "def run(question):\n    \"\"\"What answering one question costs, in tokens, through lesson 7's pipeline.\"\"\"\n    sources = sources_for(question)\n    cost = {\"embedding\": len(enc.encode(question)), \"input\": 0, \"output\": 0, \"instructions\": 0, \"sources\": 0}\n    if sources:\n        user = prompt(question, sources)\n        reply = client.chat.completions.create(model=\"llama3.2:3b\", temperature=0, messages=[\n            {\"role\": \"system\", \"content\": SYSTEM}, {\"role\": \"user\", \"content\": user}])\n        cost.update(input=reply.usage.prompt_tokens, output=reply.usage.completion_tokens,\n                    instructions=len(enc.encode(SYSTEM)), sources=len(enc.encode(user)) - len(enc.encode(f\"Question: {question}\")))\n    return cost",
      "note": "Uma pergunta com preço: os tokens que viraram embedding para a busca, e, se alguma fonte passou do piso, os tokens do prompt e da resposta como o Ollama os informa. Uma pergunta recusada antes do modelo custa só o embedding."
    },
    {
      "code": "if __name__ == \"__main__\":\n    costs = {text: run(text) for text in sorted({q[\"text\"] for q in LOG})}\n    json.dump(costs, open(\"costs.json\", \"w\"), indent=1)\n    total = {k: sum(costs[q[\"text\"]][k] for q in LOG) for k in (\"embedding\", \"input\", \"output\")}\n    calls = sum(1 for q in LOG if costs[q[\"text\"]][\"input\"])\n    print(f\"{len(LOG)} questions, {calls} model calls, {len(LOG) - calls} refused before the model\")\n    print(f\"embedding {total['embedding']:6} tokens\")\n    print(f\"input     {total['input']:6} tokens   {total['input'] / calls:.0f} per call\")\n    print(f\"output    {total['output']:6} tokens   {total['output'] / calls:.0f} per call\")",
      "note": "Cada pergunta distinta tem o preço calculado uma vez, e a semana é a soma sobre o registro. A mesma pergunta custa o mesmo toda vez que é feita, que é o que um cache vai aproveitar."
    }
  ]
}
```

```
ana@vm:~/rag$ python priced.py
500 questions, 486 model calls, 14 refused before the model
embedding   3551 tokens
input     155811 tokens   321 per call
output     26677 tokens   55 per call
```

**486 chamadas ao modelo para 500 perguntas.** Catorze foram recusadas antes do modelo, porque nenhuma
fonte passou do piso, e custaram só os poucos tokens do embedding delas; é a recusa da aula 7 se pagando.
As chamadas feitas custaram em média 321 tokens de entrada e 55 de saída, 155.811 e 26.677 na
semana. Os 3.551 tokens de embedding são pouco perto disso, que é o formato de costume: é na geração
que vai o dinheiro de um pipeline de RAG, e gerar o embedding da pergunta quase não custa nada.

Duas coisas a tirar do formato antes de qualquer número. **A entrada é a maior parte**, uns seis tokens
de entrada para cada um de saída, porque um prompt de RAG leva fontes e uma resposta de atendimento é
curta. E **toda pergunta paga o preço inteiro** toda vez que é feita, mesmo quando a mesma pergunta foi
respondida um minuto antes. O resto da aula é sobre esses dois fatos.
