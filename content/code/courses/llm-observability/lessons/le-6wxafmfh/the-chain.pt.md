---
title: Uma cadeia de chamadas
version: 1
---

Uma chamada raramente é a resposta inteira. O assistente da Marginalia faz quatro coisas para cada
pergunta: transforma a pergunta num vetor, busca nos documentos com ele, pede ao modelo que responda
a partir do que achou, e verifica as citações da resposta. Duas delas são chamadas a um fornecedor,
uma é uma consulta ao banco, e uma é Python puro. Um trace do pedido dá a cada uma o seu próprio span
e as aninha sob uma raiz, para que uma resposta lenta ou que falhou possa ser desmontada.

O `assistant.py` é o `rag.py` da aula 9 do `rag` com isso feito nele. Todo span é aberto por uma
pequena função do `telemetry.py`:

```schooling-example
{
  "language": "python",
  "file": "telemetry.py",
  "parts": [
    {
      "code": "@contextlib.contextmanager\ndef span(name, **attributes):\n    \"\"\"A span stamped with the lab's clock, marked as an error if the block raises.\"\"\"\n    s = tracer.start_span(name, attributes=attributes or None, start_time=now_ns())\n    with trace.use_span(s, end_on_exit=False):\n        try:\n            yield s\n        except BaseException as e:\n            s.set_status(Status(StatusCode.ERROR, f\"{type(e).__name__}: {e}\"))\n            s.record_exception(e, timestamp=now_ns())\n            raise\n        finally:\n            s.end(end_time=now_ns())",
      "note": "`span()` é o único jeito de o assistente abrir um span. Ele carimba o início e o fim com o relógio do laboratório, de que a aula 3 precisa, e, se o bloco lança uma exceção, marca o span como erro e registra a exceção antes de deixá-la passar."
    }
  ]
}
```

E estas são as partes do assistente que os abrem:

```schooling-example
{
  "language": "python",
  "file": "assistant.py",
  "parts": [
    {
      "code": "def retrieve(question, cfg):\n    with span(\"embed\", **{\"gen_ai.operation.name\": \"embeddings\", \"gen_ai.request.model\": \"lab-minilm\"}) as s:\n        r = client.embeddings.create(model=\"lab-minilm\", input=[question])\n        s.set_attribute(\"gen_ai.usage.input_tokens\", r.usage.prompt_tokens)\n    with span(\"search\", **{\"db.system.name\": \"postgresql\", \"app.search.k\": cfg[\"k\"],\n                           \"app.search.floor\": cfg[\"floor\"]}) as s:\n        rows = db.execute(\n            \"SELECT id, path, text, updated, 1 - (embedding <=> %s::vector) AS score FROM chunks\"\n            \" WHERE status = 'current' AND audience = 'public'\"\n            \" ORDER BY embedding <=> %s::vector LIMIT %s\",\n            (r.data[0].embedding, r.data[0].embedding, cfg[\"k\"])).fetchall()\n        kept = [row for row in rows if row[4] >= cfg[\"floor\"]]\n        s.set_attribute(\"app.search.returned\", len(rows))\n        s.set_attribute(\"app.search.kept\", len(kept))\n        if rows:\n            s.set_attribute(\"app.search.top_score\", round(rows[0][4], 3))\n        s.set_attribute(\"app.search.chunks\", [row[0] for row in kept])\n    return kept",
      "note": "A recuperação são dois spans, porque são duas operações que dão errado de jeitos diferentes: o embedding é uma chamada a um fornecedor, a busca é uma consulta ao PostgreSQL. O span da busca registra quantos trechos voltaram, quantos passaram do piso, e quais."
    },
    {
      "code": "def chat(model, messages, max_tokens):\n    \"\"\"One attempt: a streamed completion, with the time to its first token.\"\"\"\n    with span(f\"chat {model}\", **{\"gen_ai.operation.name\": \"chat\", \"gen_ai.provider.name\": \"openai\",\n                                  \"gen_ai.request.model\": model, \"gen_ai.request.max_tokens\": max_tokens}) as s:\n        started, first, parts, finish, usage = time.monotonic(), None, [], None, None\n        stream = client.chat.completions.create(model=model, max_tokens=max_tokens, messages=messages,\n                                                stream=True, stream_options={\"include_usage\": True})\n        for chunk in stream:\n            if chunk.usage:\n                usage = chunk.usage\n            for c in chunk.choices:\n                if c.delta.content:\n                    if first is None:\n                        first = time.monotonic()\n                        event(\"gen_ai.first_token\")\n                    parts.append(c.delta.content)\n                finish = c.finish_reason or finish\n        if first is not None:\n            s.set_attribute(\"app.time_to_first_token_ms\", round((first - started) * 1000))\n        if usage:\n            s.set_attribute(\"gen_ai.usage.input_tokens\", usage.prompt_tokens)\n            s.set_attribute(\"gen_ai.usage.output_tokens\", usage.completion_tokens)\n        if finish is None:\n            s.set_attribute(\"app.partial_pieces\", len(parts))\n            raise IncompleteReply(f\"stream ended after {len(parts)} pieces with no finish reason\")\n        s.set_attribute(\"gen_ai.response.model\", chunk.model)\n        s.set_attribute(\"gen_ai.response.finish_reasons\", [finish])\n        return \"\".join(parts)",
      "note": "Uma tentativa no modelo. O pedido é feito em streaming, como é para a tela de um cliente, e por isso o span consegue registrar quando chegou o primeiro pedaço de texto, além de quando chegou o último. A aula 4 precisa dos dois."
    },
    {
      "code": "def ask(question, user=\"anonymous\", session=None, feature=\"help\", at=None):\n    at = at or datetime.now().isoformat(timespec=\"seconds\")\n    release, cfg = release_at(at)\n    with span(\"ask\", **{\"app.feature\": feature, \"app.release\": release, \"gen_ai.request.model\": cfg[\"model\"],\n                        \"user.hash\": redact.pseudonym(user), \"session.id\": session or \"\",\n                        \"app.question\": redact.redact(question)}) as root:\n        if feature == \"summary\":\n            reply = generate([{\"role\": \"user\", \"content\": question}], cfg[\"model\"], max_tokens=120)\n            outcome, sources = \"summarised\", []\n        else:\n            sources = retrieve(question, cfg)\n            if not sources:\n                reply, outcome = REFUSAL, \"refused\"\n            else:\n                numbered = \"\\n\\n\".join(f\"[{n}] {path} (updated {updated})\\n{text}\"\n                                       for n, (_, path, text, updated, _) in enumerate(sources, 1))\n                reply = generate([{\"role\": \"system\", \"content\": SYSTEM},\n                                  {\"role\": \"user\", \"content\": f\"{numbered}\\n\\nQuestion: {question}\"}],\n                                 cfg[\"model\"])\n                outcome = \"refused\" if reply.startswith(REFUSAL) else \"answered\"\n            with span(\"check_citations\") as c:\n                cited = [int(n) for n in re.findall(r\"\\[(\\d+)\\]\", reply)]\n                c.set_attribute(\"app.citations.count\", len(cited))\n                c.set_attribute(\"app.citations.dangling\", sum(1 for n in cited if not 0 < n <= len(sources)))\n        root.set_attribute(\"app.outcome\", outcome)\n        root.set_attribute(\"app.reply\", redact.redact(reply))\n        trace_id = f\"{root.get_span_context().trace_id:032x}\"\n    return reply, sources, trace_id",
      "note": "O span raiz leva o que o pedido inteiro foi: a funcionalidade, a versão, o modelo, quem perguntou (como um hash com chave, aula 2) e a pergunta. Todo o resto abre dentro dele e vira filho dele sem que ninguém diga: `span()` torna cada span novo o corrente, e um span aberto enquanto outro é o corrente toma esse como pai."
    }
  ]
}
```

## O trace

```
ana@lab:~/obs$ python assistant.py "Above what order value is standard delivery free?"
Express delivery is not free at any order value. [1]
trace 1a218c3902fa97519a4b28d0bd1f155f
ana@lab:~/obs$ python tree.py
trace 1a218c3902fa97519a4b28d0bd1f155f   start(ms) took(ms)
      0     785 ms  ask
      0      56 ms    embed
     56       4 ms    search
     61     723 ms    generate
     61     723 ms      chat extract-1
    784       0 ms    check_citations
```

O `tree.py` lê os spans que o assistente escreveu no `spans.jsonl` e os desenha como a árvore que
são: cada linha é um span, recuado sob o seu pai, com quando começou, contado do início do trace, e
quanto levou. São quarenta linhas, e ele está no laboratório ao lado dos outros; as aulas 6 e 7 o
trocam por ferramentas que desenham a mesma coisa numa tela.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"O trace de uma pergunta respondida, em barras sobre um eixo de tempo de 0 a 800 ms. ask cobre os 785 ms inteiros. Abaixo dele, embed leva 56 ms, search 4 ms, generate 723 ms, e check_citations menos de um milissegundo no fim. Dentro de generate, um span chat extract-1 do mesmo comprimento, cujo primeiro token chegou aos 386 ms.\"><text x=\"20\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ask</text><rect x=\"170\" y=\"22\" width=\"510.25\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"178\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">785 ms</text><text x=\"34\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">embed</text><rect x=\"170\" y=\"52\" width=\"36.4\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"212.4\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">56 ms</text><text x=\"34\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">search</text><rect x=\"206.4\" y=\"82\" width=\"2.6\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"215\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4 ms</text><text x=\"34\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">generate</text><rect x=\"209.65\" y=\"112\" width=\"469.95\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"217.65\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">723 ms</text><text x=\"48\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">chat extract-1</text><rect x=\"209.65\" y=\"142\" width=\"469.95\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"217.65\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">723 ms</text><text x=\"34\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">check_citations</text><rect x=\"679.6\" y=\"172\" width=\"2\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"687.6\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">&lt;1 ms</text><path d=\"M420.9 163 L420.9 169\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"424.9\" y=\"169\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">primeiro token, 325 ms depois do início da chamada</text><path d=\"M170 208 L690 208\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M170 208 L170 213\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"170\" y=\"223\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M300 208 L300 213\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"300\" y=\"223\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">200</text><path d=\"M430 208 L430 213\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"430\" y=\"223\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">400</text><path d=\"M560 208 L560 213\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"560\" y=\"223\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">600</text><path d=\"M690 208 L690 213\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"690\" y=\"223\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">800</text><text x=\"430\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">milissegundos desde o início do trace</text></svg>", "caption": "Nove décimos do tempo estão num span só, e quase metade dele é a espera pelo primeiro token."}
```

A forma diz três coisas de relance.

**Os spans fecham a conta.** O `ask` levou 785 ms, e os seus filhos levaram 56, 4, 723 e menos de 1,
um depois do outro. Nada rodou em paralelo e nada falta: um buraco entre dois filhos seria tempo que o
código passou num lugar sem span, que é a primeira coisa a procurar num trace que não fecha a conta.

**Um span é quase tudo.** A chamada ao modelo levou 723 dos 785 ms. Deixar a busca duas vezes mais
rápida economizaria 2 ms; deixar a resposta mais curta economizaria centenas. Um trace é como essa
discussão se faz com números em vez de opiniões, e a aula 4 a faz direito.

**`generate` e `chat extract-1` têm o mesmo comprimento** porque a chamada deu certo na primeira
tentativa. Se o fornecedor a tivesse recusado, o `generate` teria dois ou três filhos `chat`, um por
tentativa, e o tempo entre eles. É por isso que as novas tentativas estão no código do assistente e não
dentro do SDK: a aula 4 mostra como uma repetição do SDK aparece num trace, que é de jeito nenhum.

## Por que spans, e não linhas de log

Os mesmos fatos poderiam ser escritos como cinco linhas de log com data e hora. O que o trace
acrescenta é o **pai**: cada span sabe dentro de qual span rodou. É isso que deixa uma ferramenta
desenhar a árvore, subtrair o tempo de um filho do tempo do pai, e achar todos os spans de um pedido
entre os spans de mil outros rodando ao mesmo tempo, o que um horário não consegue fazer assim que dois
pedidos se sobrepõem. A aula 11 do `observability` lê traces de uma loja web do mesmo jeito; a única
diferença aqui é qual costuma ser o span mais lento.
