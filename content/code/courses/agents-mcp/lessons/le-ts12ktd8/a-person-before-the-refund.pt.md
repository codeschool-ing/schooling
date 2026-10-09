---
title: Uma pessoa antes do reembolso
version: 2
---

O `refund` em `oa_tools.py` é declarado com `@function_tool(needs_approval=True)`. Quando um modelo o pede, o SDK não o roda: a execução para e devolve uma **interrupção**, uma chamada pendente esperando a decisão de alguém. O callback `confirm` da aula 7 respondia à mesma pergunta dentro do laço; aqui o laço pausa, e a decisão pode ser tomada depois, por outro processo, depois de uma pessoa olhar.

```schooling-example
{
  "language": "python",
  "file": "oa_guard.py",
  "parts": [
    {
      "code": "mode, message = sys.argv[1], sys.argv[2]\nif mode in (\"parallel\", \"blocking\"):\n    try:\n        Runner.run_sync(agent(parallel=mode == \"parallel\"), message)\n    except InputGuardrailTripwireTriggered as e:\n        print(f\"refused by the guardrail {e.guardrail_result.guardrail.get_name()!r}\")\nelse:\n",
      "note": "**Três modos**: os dois modos de guardrail da seção 08, e aprovar ou recusar."
    },
    {
      "code": "    result = Runner.run_sync(agent(), message)\n",
      "note": "**A primeira execução termina na interrupção**, não numa resposta."
    },
    {
      "code": "    for pending in result.interruptions:\n        print(f\"waiting for approval: {pending.name}({pending.arguments})\")\n",
      "note": "**Cada chamada pendente**, com o nome da ferramenta e os argumentos exatos que o modelo escolheu."
    },
    {
      "code": "        state = result.to_state()\n        if mode == \"approve\":\n",
      "note": "**O estado da execução**, tudo o que é preciso para continuá-la. Ele pode ser salvo e retomado em outro lugar."
    },
    {
      "code": "            state.approve(pending)\n        else:\n            state.reject(pending, rejection_message=\"A person declined this refund.\")\n",
      "note": "**A decisão fica registrada no estado**, aprovar ou recusar com uma mensagem para o modelo."
    },
    {
      "code": "        result = Runner.run_sync(agent(), state)\n    print(\"answer:\", result.final_output)",
      "note": "**Rodar o estado continua a execução** a partir da chamada pausada."
    }
  ]
}
```

```
ana@lab:~/agents$ python oa_guard.py approve "One copy in my order M-1047 arrived damaged. Please refund 38.90."
waiting for approval: refund({"order_id":"M-1047","cents":"390","reason":"damaged product"})
answer: Here is the refund order for M-1047:

Refund Order: M-1047

* Refund Amount: $38.90
* Reason: Damaged Product
ana@lab:~/agents$ python -c "import shop; print(shop.get_order(\"M-1047\")[\"refunded\"])"
390
ana@lab:~/agents$ python oa_guard.py decline "One copy in my order M-1047 arrived damaged. Please refund 38.90."
waiting for approval: refund({"cents":"390","reason":"damaged item","order_id":"M-1047"})
answer: None
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Uma execução com uma ferramenta que precisa de aprovação. A execução para quando o modelo pede refund e devolve uma interrupção em vez de uma resposta final. O programa mostra a chamada pendente a uma pessoa, registra aprovar ou rejeitar no estado da execução e roda o estado de novo. Aprovada, o reembolso roda; rejeitada, o modelo recebe a mensagem de rejeição como resultado da ferramenta.\"><defs><marker id=\"l8approve-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l8approve-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l8approve-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"70\" width=\"140\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"87.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Runner.run_sync</text><text x=\"30\" y=\"103.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o modelo pede refund</text><rect x=\"200\" y=\"70\" width=\"150\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"210\" y=\"87.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">result.interruptions</text><text x=\"210\" y=\"103.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma chamada pendente</text><rect x=\"390\" y=\"20\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"400\" y=\"35.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">state.approve()</text><text x=\"400\" y=\"51.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o reembolso roda</text><rect x=\"390\" y=\"124\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"400\" y=\"139.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">state.reject()</text><text x=\"400\" y=\"155.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">mensagem ao modelo</text><rect x=\"580\" y=\"70\" width=\"120\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"590\" y=\"87.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">run_sync(state)</text><text x=\"590\" y=\"103.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">continua</text><path d=\"M160 95 L200 95\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l8approve-ah-amber)\"></path><path d=\"M350 88 L390 45\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l8approve-ah-phosphor)\"></path><path d=\"M350 102 L390 147\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l8approve-ah-wire)\"></path><path d=\"M540 45 L580 85\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l8approve-ah-phosphor)\"></path><path d=\"M540 147 L580 105\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l8approve-ah-wire)\"></path></svg>", "caption": "A execução fica pausada, não terminada, enquanto uma pessoa decide."}
```

A pessoa viu exatamente o que ia acontecer antes de acontecer, e **o que ia acontecer estava errado**. O cliente pediu 38,90; o modelo pediu para reembolsar `"cents":"390"`, um número escrito como string e cem vezes pequeno demais. A aprovação foi dada, a validação Pydantic do SDK transformou `"390"` no inteiro 390 sem reclamar, e a loja reembolsou 390 centavos: 3,90. A resposta depois disse 38,90 ao cliente. Recusado, o reembolso não rodou, o modelo recebeu a mensagem de recusa como resultado da ferramenta e não escreveu resposta nenhuma: `None`.

**Uma aprovação vale o que vale a leitura por trás dela.** A pausa, o estado e os dois desfechos são do SDK, e funcionaram; a verificação que teria pegado esta execução é uma pessoa comparando `390` com "38.90", ou um hospedeiro que recusa um reembolso cujo valor não bate com um que o cliente informou. A aula 17 constrói esse segundo tipo.

Dois detalhes importam em produção. A pausa pode ser longa: o `result.to_state()` pode ser serializado e a execução retomada depois de uma pessoa responder numa fila horas mais tarde, o que o callback em processo da aula 7 não consegue. E a aprovação é por chamada, com os argumentos dela, que é exatamente o que a aula 17 pede de uma confirmação: a pessoa aprova este reembolso de 390 centavos no M-1047, não "reembolsos", e é por isso que a pessoa tem de ler o número.
