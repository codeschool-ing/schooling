---
title: Passos, tokens, segundos e dinheiro
version: 2
---

Um orçamento é um limite que o hospedeiro conta enquanto o agente roda. O `agent.py` conta três, e um quarto decorre deles:

| orçamento | contado como | protege contra |
|---|---|---|
| passos | pedidos mandados ao modelo | laços; um modelo que nunca chama `finish` |
| tokens | entrada mais saída, somadas ao longo dos pedidos | uma execução cuja conversa cresce sem limite |
| segundos | tempo de relógio desde o início da execução | um cliente esperando; uma fila acumulando |
| dinheiro | tokens vezes o preço de cada um | a conta; a aula 18 transforma tokens em centavos |

A mesma tarefa, rodada mais três vezes com o `llama3.2:3b` e limites baixos o bastante para disparar neste modelo, que dá um passo antes de parar sozinho:

```
ana@lab:~/agents$ python agent.py "I need a gift for my nephew, who loves adventure stories. And is my order M-1045 on its way?" --max-steps 1
[1] find_books({"genre": "adventure", "max_results": 10}) -> [{"id": "b31", "title": "Moby-Dick", "author": "Herman Melvi
[1] get_order({"order_id": "M-1045"}) -> {"id": "M-1045", "customer_id": "c-104", "placed_on": "2026-
{
 "status": "stopped",
 "reason": "step limit: 1",
 "done": [],
 "not_done": [],
 "handoff": "Passed to a person. No plan was written."
}
```

```
ana@lab:~/agents$ python agent.py "I need a gift for my nephew, who loves adventure stories. And is my order M-1045 on its way?" --max-tokens 500
[1] find_books({"genre": "adventure", "max_results": null}) -> ERROR invalid arguments: max_results: None is not of type 'integer
[1] get_order({"order_id": "M-1045"}) -> {"id": "M-1045", "customer_id": "c-104", "placed_on": "2026-
{
 "status": "answered",
 "steps": 1,
 "tokens": 583,
 "answer": "Find an adventure book for your nephew, such as “The Jungle Book” by Rudyard Kipling, and check the status of your order M-1045, which is on its way.",
 "sources": [
  "find_books",
  "get_order"
 ]
}
```

```
ana@lab:~/agents$ python recorder.py &
ana@lab:~/agents$ export ANTHROPIC_BASE_URL=http://127.0.0.1:11435
ana@lab:~/agents$ python agent.py "I need a gift for my nephew, who loves adventure stories. And is my order M-1045 on its way?" --max-seconds 2
[1] find_books({"max_results": null, "genre": "adventure"}) -> ERROR invalid arguments: max_results: None is not of type 'integer
[1] get_order({"order_id": "M-1045"}) -> {"id": "M-1045", "customer_id": "c-104", "placed_on": "2026-
{
 "status": "stopped",
 "reason": "time budget: 2.0 s",
 "done": [],
 "not_done": [],
 "handoff": "Passed to a person. No plan was written."
}
ana@lab:~/agents$ python -c 'import json; [print(r["usage"]["output_tokens"], "output tokens in", r["ms"], "ms") for r in map(json.loads, open("requests.jsonl"))]'
1024 output tokens in 119835 ms
```

O limite de passos e o orçamento de tempo pararam as suas execuções antes do segundo pedido, e **cada motivo nomeia o limite e o número**, para que quem lê o resultado saiba o que aumentar, se aumentar for o certo. O orçamento de tokens nunca disparou: o modelo chamou `finish` na primeira resposta, na mesma resposta das duas consultas, então a execução acabou em 583 tokens antes que a conferência que a pegaria pudesse rodar. A resposta dele recomenda *The Jungle Book*, que a Marginalia não vende, e diz que o M-1045 está a caminho, o que não está: as duas coisas foram escritas antes de qualquer das consultas voltar. O hospedeiro as aceitou, porque nada no `agent.py` recusa um `finish` que chega ao lado de outras chamadas. A seção 05 volta a isso.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"O laço com o seu orçamento. Antes de cada pedido, o hospedeiro confere três contadores: passos dados, tokens usados e segundos passados. Se algum está no limite, a execução para e devolve o que foi feito e o que não foi, para uma pessoa assumir. Senão, o pedido vai ao modelo, cuja resposta chama finish, que encerra a execução com uma resposta, ou chama ferramentas, cujos resultados voltam para a conversa antes da próxima conferência.\"><defs><marker id=\"l5budget-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l5budget-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l5budget-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"30\" y=\"90\" width=\"170\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"40\" y=\"112.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">conferir orçamento</text><text x=\"40\" y=\"128.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">passos · tokens · segundos</text><rect x=\"270\" y=\"90\" width=\"150\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"280\" y=\"112.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o modelo</text><text x=\"280\" y=\"128.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um pedido</text><rect x=\"500\" y=\"20\" width=\"190\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"510\" y=\"37.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">finish</text><text x=\"510\" y=\"53.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">respondida</text><rect x=\"500\" y=\"100\" width=\"190\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"510\" y=\"117.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">ferramentas</text><text x=\"510\" y=\"133.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">resultados anexados</text><rect x=\"30\" y=\"190\" width=\"170\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"40\" y=\"205.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">parada</text><text x=\"40\" y=\"221.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">passada a uma pessoa</text><path d=\"M200 120 L270 120\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l5budget-ah-wire)\"></path><text x=\"235\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">ok</text><path d=\"M420 110 L500 45\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l5budget-ah-phosphor)\"></path><path d=\"M420 125 L500 125\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l5budget-ah-wire)\"></path><path d=\"M595 150 L595 175 L115 175 L115 150\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l5budget-ah-wire)\"></path><text x=\"360\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">próximo passo</text><path d=\"M60 150 L60 190\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l5budget-ah-amber)\"></path><text x=\"66\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">limite</text></svg>", "caption": "A conferência vem antes do pedido, então uma execução estoura no máximo um passo.", "same": ["finish", "ok"]}
```

## A conferência vem antes do pedido

O orçamento de tempo era de 2 segundos, e a linha do gravador diz que só o primeiro pedido levou 119835 ms, dois minutos: o modelo escreveu 1024 tokens, o máximo que o `agent.py` permite numa resposta, antes de parar. O `agent.py` confere os orçamentos **antes** de cada pedido e não tem como saber de antemão quanto tempo o próximo vai levar nem que tamanho vai ter, então a conferência depois daquele primeiro pedido foi a primeira chance de parar, e ela veio 118 segundos atrasada. **Um orçamento conferido entre passos pode ser ultrapassado em no máximo um passo**, e o tamanho desse passo é o tamanho do estouro. Para a maioria dos agentes isso é aceitável e simples. Onde não é, o hospedeiro pode limitar o próprio passo: um `max_tokens` menor por resposta, um tempo limite no pedido ou, onde a API oferece, uma contagem de tokens do próximo pedido antes de mandá-lo, recusando um pedido que cruzaria a linha.

## Por que três orçamentos e não um

Eles falham de jeitos diferentes. Uma execução de muitos passos minúsculos bate no limite de passos com poucos tokens usados. Uma execução que busca um documento enorme bate no orçamento de tokens em dois passos. Uma execução cujas ferramentas são lentas, como buscar uma página ou uma consulta longa ao banco, bate no orçamento de tempo enquanto tokens e passos parecem modestos. Um limite só deixaria os outros dois modos de falha abertos.
