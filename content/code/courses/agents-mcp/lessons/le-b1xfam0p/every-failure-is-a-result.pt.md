---
title: Toda falha é um resultado
version: 1
---

O `Agent.call` é onde o pedido de um modelo encontra o mundo, e ele é escrito para que toda falha sobre a qual o modelo pode fazer algo volte como resultado de ferramenta, e nada que ele não possa consertar fique escondido.

```schooling-example
{
  "language": "python",
  "file": "minagent.py",
  "parts": [
    {
      "code": "    def call(self, call, seen):\n        \"\"\"(content, is_error) for one tool call. Every way it can fail comes back as an error the model reads.\"\"\"\n        t = self.tools.get(call.name)\n        if t is None:\n            return f\"unknown tool {call.name!r}; the tools are {', '.join(self.tools)}\", True\n",
      "note": "**Cinco verificações, em ordem**, cada uma devolvendo um erro que o modelo lê."
    },
    {
      "code": "        key = (call.name, json.dumps(call.args, sort_keys=True))\n        if key in seen:\n            return \"this exact call was already made in this run; use its result\", True\n        seen.add(key)\n",
      "note": "**Repetições são recusadas com um motivo**, não encerradas: a aula 3 parava a execução na primeira repetição; aqui o modelo tem uma chance de usar o resultado que já tem."
    },
    {
      "code": "        problems = sorted(self.validators[call.name].iter_errors(call.args), key=lambda e: list(e.path))\n        if problems:\n            return \"invalid arguments: \" + \"; \".join(\n                f\"{'/'.join(map(str, p.path)) or 'arguments'}: {p.message}\" for p in problems), True\n",
      "note": "**Validação por esquema, com cada problema nomeado.**"
    },
    {
      "code": "        if t.writes and not (self.confirm and self.confirm(call)):\n            return \"refused: this tool changes data and needs a person's confirmation\", True\n",
      "note": "**Uma escrita precisa de uma pessoa.** Sem callback `confirm`, ou com um que diz não, a função nunca roda. A aula 17 constrói o callback direito."
    },
    {
      "code": "        try:\n            return json.dumps(t.fn(**call.args), ensure_ascii=False, default=str), False\n        except (LookupError, ValueError) as e:\n            return f\"{type(e).__name__}: {e}\", True\n\n",
      "note": "**Só erros esperados são pegos.** Qualquer outro se propaga e para a execução com barulho, como a aula 4 defendeu."
    },
    {
      "code": "    def record(self, trace, record):\n        trace.append(record)\n        if self.trace_path:\n            with open(self.trace_path, \"a\") as f:\n                f.write(json.dumps(record, ensure_ascii=False) + \"\\n\")\n\n",
      "note": "**O rastro é anexado durante a execução**, uma linha JSON por passo, então uma queda deixa em disco os passos de antes dela."
    },
    {
      "code": "    def stop(self, reason, steps, used, trace):\n        found = [f\"{c['tool']}({json.dumps(c['args'])})\" for r in trace for c in r[\"calls\"] if not c[\"error\"]]\n        handoff = f\"Stopped ({reason}). \" + (f\"Results so far: {'; '.join(found)}.\" if found else \"Nothing found yet.\")\n        return Outcome(\"stopped\", None, handoff, steps, used, trace)",
      "note": "**Uma execução parada entrega os seus resultados**, não o seu plano: toda chamada que deu certo, por nome e argumentos."
    }
  ]
}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Os jeitos como uma chamada de ferramenta pode falhar no minagent, na ordem em que o Agent.call os confere, e o que o modelo lê em cada um: um nome de ferramenta desconhecido, uma chamada já feita nesta execução, argumentos que falham no esquema, uma escrita sem confirmação e um erro conhecido levantado pela função. Cada um vira um resultado de ferramenta marcado como erro. Três passos seguidos só com erros param a execução.\"><defs><marker id=\"l7fail-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l7fail-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"124\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"82.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">ferramenta</text><text x=\"82.0\" y=\"71.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">inexistente</text><path d=\"M82 86 L82 130\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l7fail-ah-amber)\"></path><rect x=\"160\" y=\"40\" width=\"124\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"222.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">repetição</text><path d=\"M144 63 L160 63\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l7fail-ah-wire)\"></path><path d=\"M222 86 L222 130\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l7fail-ah-amber)\"></path><rect x=\"300\" y=\"40\" width=\"124\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"362.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">esquema</text><path d=\"M284 63 L300 63\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l7fail-ah-wire)\"></path><path d=\"M362 86 L362 130\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l7fail-ah-amber)\"></path><rect x=\"440\" y=\"40\" width=\"124\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"502.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">escrita</text><text x=\"502.0\" y=\"71.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sem confirmação</text><path d=\"M424 63 L440 63\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l7fail-ah-wire)\"></path><path d=\"M502 86 L502 130\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l7fail-ah-amber)\"></path><rect x=\"580\" y=\"40\" width=\"124\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"642.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">LookupError</text><text x=\"642.0\" y=\"71.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ValueError</text><path d=\"M564 63 L580 63\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l7fail-ah-wire)\"></path><path d=\"M642 86 L642 130\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l7fail-ah-amber)\"></path><rect x=\"20\" y=\"130\" width=\"684\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"362\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">tool_result com is_error: true, devolvido ao modelo</text><text x=\"362\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">três passos só com erros: parada (sem progresso)</text></svg>", "caption": "Cinco verificações, um formato de resposta: um resultado que o modelo consegue ler.", "same": ["LookupError", "ValueError"]}
```

## O reembolso que não aconteceu

Um cliente diz que um de dois exemplares de *Drácula* no M-1047 chegou danificado e pede reembolso. **Os passos do modelo foram escritos pelo curso**, inclusive o reembolso que ele pede:

```
ana@lab:~/agents$ python run.py "One of the two copies of Dracula in my order M-1047 arrived damaged. Please refund it."
answered after 4 steps, 2717 tokens
I am sorry the book arrived damaged. I cannot issue the refund myself, so I have passed it to a colleague. Our policy is to replace damaged books at no cost: photograph the copy next to its packaging and send the pictures within 14 days, and you do not need to send it back.
  step 1: model 628 ms, 435 in / 10 out; get_order 0 ms
  step 2: model 566 ms, 558 in / 8 out; search_help 331 ms
  step 3: model 1325 ms, 785 in / 28 out; refund ERROR 0 ms
  step 4: model 2689 ms, 832 in / 61 out
ana@lab:~/agents$ python -c "import shop; print(shop.get_order(\"M-1047\")[\"refunded\"])"
0
```

O passo 3 pediu `refund`, e o `call` recusou: a ferramenta é declarada `writes=True` e o `run.py` não passa callback `confirm`. O modelo, roteirizado para ler a recusa, disse ao cliente que um colega cuidaria disso, e citou a política da busca do passo 2: livros danificados são trocados sem custo, com fotos em até 14 dias. O último comando confirma que nada foi reembolsado: `0`. **A resposta é honesta sobre o que o agente não podia fazer**, e a decisão que importa foi para uma pessoa.

## O modelo que continuava chutando

```
ana@lab:~/agents$ python run.py "Track my parcel for order M-1043, please."
stopped after 3 steps, 1425 tokens
Stopped (no progress: 3 steps in a row with only errors). Nothing found yet.
  step 1: model 628 ms, 426 in / 10 out; track_parcel ERROR 0 ms
  step 2: model 649 ms, 465 in / 10 out; track_parcel ERROR 0 ms
  step 3: model 647 ms, 504 in / 10 out; parcel_status ERROR 0 ms
```

O curso roteirizou um modelo que chama ferramentas que não existem: `track_parcel` duas vezes, com argumentos diferentes para a guarda de repetição não pegar, depois `parcel_status`. Cada chamada voltou `unknown tool`, com a lista das ferramentas que existem. Depois do terceiro passo só com erros, o laço parou pela própria regra, não pelo limite de passos, e o resultado diz isso. `Nothing found yet.` é a passagem honesta: nenhuma ferramenta devolveu nada.

Um modelo real lendo *"the tools are get_order, search_help, find_books, refund"* muito provavelmente chamaria `get_order` em seguida e acharia o código de rastreio ali. O sentido da terceira parada é o caso em que ele não faz isso.
