---
title: A janela é um orçamento
version: 2
---

Todas as aulas até aqui foram sobre achar o texto certo. Esta e as quatro seguintes tratam de outra
pergunta: **de tudo o que poderia ir para a frente do modelo, o que deve ir?** É isso que passou a se
chamar engenharia de contexto. A janela de contexto é tudo o que o modelo lê numa chamada: as
instruções, as fontes, os turnos anteriores da conversa, a pergunta e o espaço que sobra para a
resposta. Ela tem um limite rígido, e bem antes do limite ela tem um preço.

As decisões desta aula moram num módulo só, o `context.py`, que as seções seguintes desmontam uma
função de cada vez. Salve-o agora, porque todo programa da aula o importa:

```schooling-example
{
  "language": "python",
  "file": "context.py",
  "parts": [
    {
      "code": "\"\"\"What goes into the window, and in what order: lesson 12's decisions in one place.\"\"\"\nimport re\n\nimport tiktoken\nfrom answer import FLOOR, REFUSAL, ask\nfrom vectors import embed\nfrom search import conn, vector\n\nenc = tiktoken.get_encoding(\"cl100k_base\")\nSAME = 0.9      # two sources this similar say the same thing\nKEEP = 0.45     # a sentence this similar to the question stays in its source\nBUDGET = 200    # tokens of sources, headers included\n\n\ndef tokens(text):\n    return len(enc.encode(text))",
      "note": "As decisões desta aula, como constantes: o quanto duas fontes precisam ser parecidas para contar como uma, o quanto uma frase precisa estar perto da pergunta para ficar, e quantos tokens de fontes um prompt pode levar. O `tokens` conta com o tiktoken, como a aula 1 fez."
    },
    {
      "code": "def candidates(question, k=10, where=\"status = %s AND audience = %s\", params=(\"current\", \"public\")):\n    \"\"\"Up to K chunks above the floor, best first, with what a source header needs.\"\"\"\n    found = [r for r in vector(question, k, where, params) if r[3] >= FLOOR]\n    meta = {i: (u, v) for i, u, v in conn.execute(\n        \"SELECT id, updated, doc_version FROM chunks WHERE id = ANY(%s)\", ([r[0] for r in found],))}\n    return [{\"id\": i, \"path\": p, \"text\": t, \"score\": s, \"updated\": meta[i][0], \"version\": meta[i][1]}\n            for i, p, t, s in found]",
      "note": "Até k pedaços acima do piso da aula 7, com o que o cabeçalho de uma fonte precisa: a data e a versão."
    },
    {
      "code": "def dedupe(sources, same=SAME):\n    \"\"\"Drop a source that says what a better one already said.\"\"\"\n    if not sources:\n        return []\n    v = embed([s[\"text\"] for s in sources])\n    kept = []\n    for i in range(len(sources)):\n        if all(v[i] @ v[j] < same for j in kept):\n            kept.append(i)\n    return [sources[i] for i in kept]",
      "note": "A seção sobre duplicatas explica esta."
    },
    {
      "code": "def sentences(text):\n    return [s for s in re.split(r\"(?<=[.!?])\\s+(?=[A-Z0-9])|\\n(?=- )|\\n\\n\", text) if s.strip()]\n\n\ndef compress(question, source, keep=KEEP):\n    \"\"\"Keep the sentences of a source that are about the question, in their order, and always its best.\"\"\"\n    parts = sentences(source[\"text\"])\n    scores = embed(parts) @ embed(question)[0]\n    chosen = [p for p, s in zip(parts, scores) if s >= keep or s == scores.max()]\n    return {**source, \"text\": \" \".join(\" \".join(p.split()) for p in chosen)}",
      "note": "A seção sobre compressão das fontes explica estas."
    },
    {
      "code": "def ends(sources):\n    \"\"\"Best first, second best last, the weakest in the middle.\"\"\"\n    return sources[0::2] + sources[1::2][::-1]\n\ndef header(n, source):\n    return f\"[{n}] {source['path']} (updated {source['updated']})\\n\"",
      "note": "As seções sobre posição e cabeçalhos explicam estas."
    },
    {
      "code": "def pack(question, budget=BUDGET, k=10, **filters):\n    \"\"\"Floor, then duplicates out, then each source cut to what is about the question, then as many\n    as fit the budget, best first, and finally the strongest two at the two ends.\"\"\"\n    kept, used = [], 0\n    for s in dedupe(candidates(question, k, **filters)):\n        s = compress(question, s)\n        cost = tokens(header(0, s) + s[\"text\"])\n        if used + cost <= budget:\n            kept.append(s)\n            used += cost\n    return ends(kept)",
      "note": "A seção sobre empacotamento explica esta, e a última."
    },
    {
      "code": "def answer(question, **filters):\n    sources = pack(question, **filters)\n    if not sources:\n        return REFUSAL, []\n    return ask(question, sources), sources"
    }
  ]
}
```
O `window.py` pergunta a ele qual o tamanho do prompt da aula 7 para uma pergunta sobre
cartão-presente, parte por parte:

```schooling-example
{
  "language": "python",
  "file": "window.py",
  "parts": [
    {
      "code": "import sys\n\nfrom answer import SYSTEM, prompt, sources_for\nfrom context import header, tokens\n\nquestion = sys.argv[1]\nsources = sources_for(question)\nprint(f\"{tokens(SYSTEM):5}  instructions\")\nfor n, s in enumerate(sources, 1):\n    print(f\"{tokens(header(n, s)):5}  header [{n}]\")\n    print(f\"{tokens(s['text']):5}  text   [{n}] {s['path']}\")\nprint(f\"{tokens('Question: ' + question):5}  question\")\ntotal = tokens(SYSTEM) + tokens(prompt(question, sources))\nprint(f\"{total:5}  sent, of a window of 4096\")",
      "note": "Cada parte do prompt que o `answer.py` da aula 7 mandaria para uma pergunta, contada em tokens: as instruções, o cabeçalho e o texto de cada fonte, e a pergunta, contra os 4.096 tokens que o Ollama dá ao llama3.2:3b."
    }
  ]
}
```
```
ana@vm:~/rag$ python window.py "How long is a gift card valid?"
   71  instructions
   19  header [1]
   39  text   [1] Gift card terms > Validity
   22  header [2]
   69  text   [2] Payments, invoices and gift cards > Gift cards
   22  header [3]
   59  text   [3] Payments, invoices and gift cards > Gift cards
   10  question
  311  sent, of a window of 4096
```

**311 tokens, de uma janela de 4.096.** Parece um problema que ainda não existe, e três coisas o
tornam um problema mesmo assim.

- **Todo token é pago**, em toda consulta, e a aula 17 multiplica isso por uma semana de tráfego. Um
  prompt com o dobro do tamanho é o dobro da conta da entrada.
- **Todo token é lido antes de a primeira palavra voltar.** O streaming da aula 9 escondia o tempo de
  escrever a resposta; nada esconde o tempo de ler o prompt, e ele cresce com o tamanho.
- **Todo token disputa a atenção do modelo.** Essa é a que este curso mede pior, com um modelo
  pequeno e trinta perguntas, e a seção depois da próxima cita a pesquisa que a mediu.

E os 311 são o menor tamanho que ele vai ter. A aula 13 acrescenta a conversa até ali, um assistente
de atendimento pode acrescentar os dados da conta do cliente, um agente em `agents-mcp` acrescenta as
descrições das suas ferramentas, e cada um chega com um motivo para estar ali. **Uma janela nunca é
preenchida por uma decisão; é preenchida por muitas decisões razoáveis**, e a soma não é escolha de
ninguém, a menos que alguém a torne uma.

A anatomia acima também é a pauta desta aula. As instruções, 71 tokens, são fixas. A pergunta é do
cliente. Todo o resto é decisão: quantas fontes (as duas próximas seções), quais (duplicatas), quanto
de cada uma (compressão), em que ordem (posicionamento) e com o que em volta (cabeçalhos). A última
seção junta as decisões numa função, `pack`, e a mede contra o prompt da aula 7.
