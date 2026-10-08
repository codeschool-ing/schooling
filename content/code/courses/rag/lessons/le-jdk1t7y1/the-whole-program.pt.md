---
title: O programa inteiro
version: 2
---

As aulas 4 a 8 construíram o pipeline em pedaços, cada um no seu módulo, cada um medido. Um serviço em
produção costuma ser menor do que essa coleção sugere. O `rag.py` é tudo isso num arquivo só, escrito
diretamente contra o SDK do provedor: a pergunta vira embedding pelo provedor, a busca é feita pelo
banco, a resposta é gerada pelo provedor, e há uma linha de registro para cada consulta.

```schooling-example
{
  "language": "python",
  "file": "rag.py",
  "parts": [
    {
      "code": "\"\"\"rag.py: the whole pipeline in one file, with the provider's SDK and nothing else.\n\n    python rag.py \"QUESTION\"\n\"\"\"\nimport json\nimport re\nimport sys\nimport time\n\nimport psycopg\nfrom openai import OpenAI\nfrom pgvector.psycopg import register_vector",
      "note": "Duas bibliotecas fazem o trabalho: o SDK do provedor para os dois modelos, e o psycopg para o índice. Nenhum framework, nenhum módulo das aulas anteriores."
    },
    {
      "code": "EMBED_MODEL, CHAT_MODEL = \"all-minilm\", \"llama3.2:3b\"\nK, FLOOR = 3, 0.5\nREFUSAL = \"I could not find that in our documents.\"\nSYSTEM = \"\"\"You answer questions from Marginalia's customers, using only the numbered sources.\nCite every sentence with the number of the source it comes from, like [1].\nIf the sources do not answer the question, reply: \"I could not find that in our documents.\"\nIf two sources disagree, prefer the one updated most recently, and say so.\"\"\"\n\nclient = OpenAI(max_retries=3, timeout=20)\ndb = psycopg.connect(autocommit=True)\nregister_vector(db)",
      "note": "Toda decisão que as aulas anteriores mediram é uma constante no topo: os dois modelos, o k, o piso, a recusa e as instruções. O cliente é criado uma vez com um orçamento de tentativas e um tempo limite, porque os dois têm padrões que ninguém escolheu."
    },
    {
      "code": "def retrieve(question):\n    vector = client.embeddings.create(model=EMBED_MODEL, input=[question]).data[0].embedding\n    rows = db.execute(\n        \"SELECT id, path, text, updated, 1 - (embedding <=> %s::vector) AS score FROM chunks\"\n        \" WHERE status = 'current' AND audience = 'public'\"\n        \" ORDER BY embedding <=> %s::vector LIMIT %s\", (vector, vector, K)).fetchall()\n    return [r for r in rows if r[4] >= FLOOR]",
      "note": "A pergunta vira embedding pelo provedor, pelo mesmo SDK, e o banco faz o resto: o filtro, a ordenação pela distância de cosseno, o limite. O piso é aplicado em Python, então uma pergunta sem nada acima dele recebe uma lista vazia."
    },
    {
      "code": "def generate(question, sources):\n    numbered = \"\\n\\n\".join(f\"[{n}] {path} (updated {updated})\\n{text}\"\n                           for n, (_, path, text, updated, _) in enumerate(sources, 1))\n    reply = client.chat.completions.create(model=CHAT_MODEL, max_tokens=300, temperature=0, messages=[\n        {\"role\": \"system\", \"content\": SYSTEM},\n        {\"role\": \"user\", \"content\": f\"{numbered}\\n\\nQuestion: {question}\"}])\n    return reply.choices[0].message.content, reply.usage",
      "note": "O prompt da aula 7, montado ali mesmo. O `max_tokens` limita a resposta, para uma resposta desembestada não custar mais que 300 tokens."
    },
    {
      "code": "def ask(question):\n    started = time.monotonic()\n    sources = retrieve(question)\n    reply, usage = generate(question, sources) if sources else (REFUSAL, None)\n    cited = sorted({int(n) for n in re.findall(r\"\\[(\\d+)\\]\", reply)})\n    record = {\"question\": question, \"sources\": [[s[0], round(s[4], 3)] for s in sources],\n              \"reply\": reply, \"cited\": [sources[n - 1][0] for n in cited if 0 < n <= len(sources)],\n              \"prompt_tokens\": usage.prompt_tokens if usage else 0,\n              \"completion_tokens\": usage.completion_tokens if usage else 0,\n              \"ms\": round((time.monotonic() - started) * 1000)}\n    with open(\"queries.jsonl\", \"a\") as log:\n        log.write(json.dumps(record) + \"\\n\")\n    return reply, sources, cited",
      "note": "O pipeline: recuperar, gerar só se houver de onde gerar, juntar as citações, e acrescentar uma linha ao `queries.jsonl` descrevendo tudo o que aconteceu."
    },
    {
      "code": "if __name__ == \"__main__\":\n    reply, sources, cited = ask(sys.argv[1])\n    print(reply)\n    for n in cited:\n        _, path, _, updated, _ = sources[n - 1]\n        print(f\"  [{n}] {path}, updated {updated}\")",
      "note": "A linha de comando: a resposta e uma nota por fonte citada."
    }
  ]
}
```

Cada número nele veio de uma medição anterior do curso. Os pedaços que ele busca são os pedaços
estruturados de 60 palavras da aula 5, com os caminhos de títulos. O k é 3 porque a aula 6 não achou mais
nada a ganhar além disso neste corpus. O piso é 0,5 por causa da lista de notas da aula 6 e da comparação
da aula 8. As instruções são as da aula 7. **Esse é o argumento para escrevê-lo à mão: cada linha é uma
decisão para a qual alguém pode apontar uma medição.**

## Rodando

```
ana@vm:~/rag$ python rag.py "How long after my return arrives will I get the refund?"
According to [1], the money goes back to the card or account you paid with, and your bank may take another five to ten days to show it. This means that the refund processing time is at least 5-10 days after the return reaches the warehouse.

However, [2] states that the return window starts on the day the carrier records the parcel as delivered, not on the day you placed the order. This implies that the refund processing time may be shorter than 5-10 days, as it depends on when the carrier records the parcel as delivered.

To clarify, I would recommend checking the seller's policy, as mentioned in [3], as they may have a different return window and refund processing time.
  [1] Returns and refunds policy > Refunds, updated 2026-02-02
  [2] Returns and refunds policy > The return window, updated 2026-02-02
  [3] Returns and refunds policy > Items sold by marketplace sellers, updated 2026-02-02
ana@vm:~/rag$ python rag.py "Can I place an order by phone?"
I could not find that in our documents.
```

A mesma resposta do `answer.py` da aula 7, palavra por palavra, com os mesmos defeitos: o prazo do banco
citado, os três dias úteis deixados de fora, uma conclusão que nenhuma fonte tira, e duas fontes citadas
que não têm nada a ver com um reembolso. E a mesma recusa, decidida antes de o modelo ser chamado. Por
baixo também nada mudou, o mesmo modelo de embeddings e o mesmo gerador pelo mesmo endpoint. O que mudou
foi a forma: um arquivo que depende de um SDK e de um driver de banco, e que qualquer pessoa lê de cima a
baixo.

## O que ele não faz, de propósito

**Nenhuma reordenação**, porque a aula 6 mediu a que esta máquina consegue rodar, o próprio modelo dando
nota a cada pedaço: uma posição ganha nas perguntas de clientes, todos os primeiros lugares perdidos nos
identificadores, e vinte chamadas por pergunta.

**Nenhuma busca híbrida**, porque estas perguntas são de clientes e a aula 6 mediu que a busca lexical só
ajuda perguntas de identificador. Um assistente para desenvolvedores sobre a referência da API a
acrescentaria.

**Nenhum cache, nenhuma compactação, nenhuma memória.** As aulas 13 a 17 acrescentam cada uma dessas
coisas onde uma medição diz que é preciso, não antes.

Essa é a forma que vale copiar. Um pipeline cresce acrescentando um passo que uma medição pediu, com a
medição guardada ao lado da mudança. Começado do jeito oposto, com toda técnica que um tutorial menciona,
ele vira um sistema que ninguém consegue explicar e ninguém se atreve a mudar.

## Trocando o provedor

A `OPENAI_BASE_URL`, a chave e os dois nomes de modelo são as únicas coisas que prendem o `rag.py` ao
Ollama. Apontado para um provedor real, ele roda sem mudança: o modelo de embeddings tem de ser o
que construiu o índice, e o modelo de chat pode ser qualquer um que o provedor ofereça. A maioria dos
provedores e muitos servidores de código aberto falam esse mesmo formato Chat Completions, e por isso é o
formato contra o qual escrever quando nada obriga a outro. A próxima seção usa um que é diferente de um
jeito útil.
