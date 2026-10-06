---
title: Guardrails, e quando eles rodam
version: 1
---

Um **guardrail** no SDK é uma função que confere a entrada (ou a saída) de um agente e pode parar a execução disparando um alarme. Ele roda ao lado do agente e não dentro do laço dele, e pode ser código simples ou outra chamada de modelo. O de `oa_guard.py` recusa uma mensagem que contenha algo com cara de número de cartão, uma regra com resposta certa que dispensa modelo:

```schooling-example
{
  "language": "python",
  "file": "oa_guard.py",
  "parts": [
    {
      "code": "\"\"\"A guardrail on the customer's message, and a person in front of a refund, with the OpenAI Agents SDK.\"\"\"\nimport asyncio\nimport re\nimport sys\n\nfrom agents import (Agent, GuardrailFunctionOutput, InputGuardrailTripwireTriggered, Runner, input_guardrail,\n                    set_default_openai_api, set_tracing_disabled)\n\nfrom oa_tools import get_order, refund\n\nset_default_openai_api(\"chat_completions\")\nset_tracing_disabled(True)\n"
    },
    {
      "code": "CARD = re.compile(r\"\\b(?:\\d[ -]?){13,19}\\b\")\n\n\n",
      "note": "**A regra**: de 13 a 19 dígitos, com espaços ou hífens opcionais entre eles."
    },
    {
      "code": "def card_check(parallel):\n    @input_guardrail(name=\"no card numbers\", run_in_parallel=parallel)\n",
      "note": "**O mesmo guardrail montado de dois jeitos**, diferindo só em `run_in_parallel`."
    },
    {
      "code": "    async def no_card_numbers(ctx, agent, message):\n        \"\"\"Trip if the customer's message contains something shaped like a card number.\"\"\"\n",
      "note": "**Um guardrail recebe a mensagem** e devolve se o alarme disparou."
    },
    {
      "code": "        await asyncio.sleep(0.5)  # stands for a check that calls a model, which takes time\n        return GuardrailFunctionOutput(output_info=None, tripwire_triggered=bool(CARD.search(str(message))))\n    return no_card_numbers\n\n\n",
      "note": "**Um substituto para uma verificação mais lenta.** Guardrails que chamam um modelo de moderação levam tempo; meio segundo de espera faz esse papel aqui, para a diferença de tempo abaixo ficar visível."
    },
    {
      "code": "def agent(parallel=True):\n    return Agent(name=\"Refunds\", model=\"scripted-1\", tools=[get_order, refund],\n                 input_guardrails=[card_check(parallel)],\n                 instructions=\"You handle refunds in the OpenAI Agents SDK lesson. Look up the order, then refund.\")\n",
      "note": "**O guardrail é preso ao agente**, ao lado das ferramentas."
    }
  ]
}
```

A mesma mensagem, com o guardrail em cada modo. O log do labllm foi esvaziado antes de cada execução, e o `grep -c` conta os pedidos que continham o número do cartão:

```
ana@lab:~/agents$ python oa_guard.py parallel "Refund it to my card 4111 1111 1111 1111 please"
refused by the guardrail 'no card numbers'
ana@lab:~/agents$ grep -c 4111 /var/log/labllm/requests.jsonl
1
ana@lab:~/agents$ python oa_guard.py blocking "Refund it to my card 4111 1111 1111 1111 please"
refused by the guardrail 'no card numbers'
ana@lab:~/agents$ grep -c 4111 /var/log/labllm/requests.jsonl
0
```

As duas execuções foram recusadas. **Só uma delas impediu o número do cartão de sair da máquina.** Com `run_in_parallel=True`, o padrão do SDK, o guardrail e o pedido ao modelo começam juntos; o guardrail levou meio segundo para disparar, e a essa altura o pedido, número do cartão e tudo, já tinha chegado ao fornecedor: `1`. Com `run_in_parallel=False`, o guardrail roda primeiro e o pedido nunca é mandado: `0`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Duas linhas do tempo para um guardrail de entrada. Em paralelo, o guardrail e o pedido ao modelo começam juntos; o guardrail dispara depois de meio segundo, mas a mensagem do cliente, número do cartão incluído, já foi mandada ao fornecedor. Bloqueante, o guardrail roda primeiro; ele dispara, e nenhum pedido chega a ser mandado.\"><defs><marker id=\"l8guard-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l8guard-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">run_in_parallel=True</text><rect x=\"20\" y=\"46\" width=\"260\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"63.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">guardrail: 0,5 s</text><rect x=\"20\" y=\"88\" width=\"420\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"105.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">pedido ao modelo, com o número do cartão</text><path d=\"M284 40 L284 84\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></path><text x=\"290\" y=\"63\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dispara aos 0,5 s: execução cancelada, pedido já enviado</text><text x=\"20\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">run_in_parallel=False</text><rect x=\"20\" y=\"172\" width=\"260\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"189.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">guardrail: 0,5 s</text><rect x=\"300\" y=\"172\" width=\"400\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"310\" y=\"189.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">nenhum pedido é enviado</text><path d=\"M280 189 L300 189\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l8guard-ah-phosphor)\"></path></svg>", "caption": "Em paralelo, um guardrail para a resposta. Só bloqueante para o pedido."}
```

Paralelo é o padrão porque não custa latência quando o guardrail passa, o que é a maior parte das vezes. Isso o torna certo para verificações cujo propósito é barrar uma *resposta* ruim, como um pedido fora do assunto. **Para uma verificação cujo propósito é impedir que dados cheguem ao fornecedor, é o modo errado**: quando ele dispara, os dados já foram. Dados sensíveis na mensagem de um cliente são um problema de privacidade além de segurança, e a aula 12 de `ai-security` trata do que pode ser mandado ao fornecedor de um modelo.

Guardrails não são um sistema de permissões. Um guardrail recusa uma entrada ou uma saída; ele não decide se uma chamada de ferramenta é permitida, que é para o que servem o `needs_approval` (seção 07) e as verificações do próprio hospedeiro (aula 17).
