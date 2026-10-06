---
title: Passos, tokens, segundos e dinheiro
version: 1
---

Um orçamento é um limite que o hospedeiro conta enquanto o agente roda. O `agent.py` conta três, e um quarto decorre deles:

| orçamento | contado como | protege contra |
|---|---|---|
| passos | pedidos mandados ao modelo | laços; um modelo que nunca chama `finish` |
| tokens | entrada mais saída, somadas ao longo dos pedidos | uma execução cuja conversa cresce sem limite |
| segundos | tempo de relógio desde o início da execução | um cliente esperando; uma fila acumulando |
| dinheiro | tokens vezes o preço de cada um | a conta; a aula 18 transforma tokens em centavos |

A mesma tarefa, rodada mais três vezes com limites mais apertados:

```
ana@lab:~/agents$ python agent.py "I need a gift for my nephew, who loves adventure stories. And is my order M-1045 on its way?" --max-steps 3
[1] plan
      [ ] Look up order M-1045
      [ ] Find adventure books in stock
      [ ] Answer both questions
[2] get_order({"order_id": "M-1045"}) -> {"id": "M-1045", "customer_id": "c-104", "placed_on": "2026-
[3] plan
      [x] Look up order M-1045
      [ ] Find adventure books in stock
      [ ] Answer both questions
[3] find_books({"genre": "adventure"}) -> [{"id": "b31", "title": "Moby-Dick", "author": "Herman Melvi
{
 "status": "stopped",
 "reason": "step limit: 3",
 "done": [
  "Look up order M-1045"
 ],
 "not_done": [
  "Find adventure books in stock",
  "Answer both questions"
 ],
 "handoff": "Passed to a person. Done: Look up order M-1045. Not done: Find adventure books in stock; Answer both questions."
}
```

```
ana@lab:~/agents$ python agent.py "I need a gift for my nephew, who loves adventure stories. And is my order M-1045 on its way?" --max-tokens 1500
[1] plan
      [ ] Look up order M-1045
      [ ] Find adventure books in stock
      [ ] Answer both questions
[2] get_order({"order_id": "M-1045"}) -> {"id": "M-1045", "customer_id": "c-104", "placed_on": "2026-
[3] plan
      [x] Look up order M-1045
      [ ] Find adventure books in stock
      [ ] Answer both questions
[3] find_books({"genre": "adventure"}) -> [{"id": "b31", "title": "Moby-Dick", "author": "Herman Melvi
{
 "status": "stopped",
 "reason": "token budget: 1895 of 1500 used",
 "done": [
  "Look up order M-1045"
 ],
 "not_done": [
  "Find adventure books in stock",
  "Answer both questions"
 ],
 "handoff": "Passed to a person. Done: Look up order M-1045. Not done: Find adventure books in stock; Answer both questions."
}
```

```
ana@lab:~/agents$ python agent.py "I need a gift for my nephew, who loves adventure stories. And is my order M-1045 on its way?" --max-seconds 1
[1] plan
      [ ] Look up order M-1045
      [ ] Find adventure books in stock
      [ ] Answer both questions
{
 "status": "stopped",
 "reason": "time budget: 1.0 s",
 "done": [],
 "not_done": [
  "Look up order M-1045",
  "Find adventure books in stock",
  "Answer both questions"
 ],
 "handoff": "Passed to a person. Not done: Look up order M-1045; Find adventure books in stock; Answer both questions."
}
ana@lab:~/agents$ tail -n 1 /var/log/labllm/requests.jsonl | python -c 'import json, sys; r = json.loads(sys.stdin.read()); print(r["usage"]["output_tokens"], "output tokens in", r["ms"], "ms")'
52 output tokens in 2282 ms
```

O limite de passos parou a execução depois de três pedidos, o orçamento de tokens também depois de três, e o de tempo depois de um. **Cada motivo nomeia o limite e o número**, para que quem lê o resultado saiba o que aumentar, se aumentar for o certo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"O laço com o seu orçamento. Antes de cada pedido, o hospedeiro confere três contadores: passos dados, tokens usados e segundos passados. Se algum está no limite, a execução para e devolve o que foi feito e o que não foi, para uma pessoa assumir. Senão, o pedido vai ao modelo, cuja resposta chama finish, que encerra a execução com uma resposta, ou chama ferramentas, cujos resultados voltam para a conversa antes da próxima conferência.\"><defs><marker id=\"l5budget-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l5budget-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l5budget-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"30\" y=\"90\" width=\"170\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"40\" y=\"112.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">conferir orçamento</text><text x=\"40\" y=\"128.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">passos · tokens · segundos</text><rect x=\"270\" y=\"90\" width=\"150\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"280\" y=\"112.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o modelo</text><text x=\"280\" y=\"128.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um pedido</text><rect x=\"500\" y=\"20\" width=\"190\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"510\" y=\"37.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">finish</text><text x=\"510\" y=\"53.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">respondida</text><rect x=\"500\" y=\"100\" width=\"190\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"510\" y=\"117.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">ferramentas</text><text x=\"510\" y=\"133.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">resultados anexados</text><rect x=\"30\" y=\"190\" width=\"170\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"40\" y=\"205.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">parada</text><text x=\"40\" y=\"221.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">passada a uma pessoa</text><path d=\"M200 120 L270 120\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l5budget-ah-wire)\"></path><text x=\"235\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">ok</text><path d=\"M420 110 L500 45\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l5budget-ah-phosphor)\"></path><path d=\"M420 125 L500 125\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l5budget-ah-wire)\"></path><path d=\"M595 150 L595 175 L115 175 L115 150\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l5budget-ah-wire)\"></path><text x=\"360\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">próximo passo</text><path d=\"M60 150 L60 190\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l5budget-ah-amber)\"></path><text x=\"66\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">limite</text></svg>", "caption": "A conferência vem antes do pedido, então uma execução estoura no máximo um passo.", "same": ["finish", "ok"]}
```

## A conferência vem antes do pedido

Olhe a execução de tokens: `1895 of 1500 used`. O orçamento foi ultrapassado, não atingido, porque o `agent.py` confere antes de cada pedido e não tem como saber de antemão o tamanho da resposta. Depois do passo 2 o total estava abaixo de 1500, então o passo 3 foi permitido; o passo 3 levou o total a 1895; a conferência antes do passo 4 parou a execução. **Um orçamento conferido entre passos pode ser ultrapassado em no máximo um passo**, e o tamanho desse passo é o tamanho do estouro. Para a maioria dos agentes isso é aceitável e simples. Onde não é, o hospedeiro pode pedir o tamanho do próximo pedido antes de mandá-lo (a API da Anthropic tem um endpoint de contagem de tokens, e o labllm o implementa) e recusar um pedido que cruzaria a linha.

O orçamento de tempo se comporta do mesmo jeito. A última linha daquela transcrição lê o log do labllm: o primeiro pedido escreveu o plano, 52 tokens a 40 ms cada depois dos primeiros 200 ms, e levou mais de dois segundos. A conferência antes do segundo pedido parou a execução só com o plano escrito.

## Por que três orçamentos e não um

Eles falham de jeitos diferentes. Uma execução de muitos passos minúsculos bate no limite de passos com poucos tokens usados. Uma execução que busca um documento enorme bate no orçamento de tokens em dois passos. Uma execução cujas ferramentas são lentas, como buscar uma página ou uma consulta longa ao banco, bate no orçamento de tempo enquanto tokens e passos parecem modestos. Um limite só deixaria os outros dois modos de falha abertos.
