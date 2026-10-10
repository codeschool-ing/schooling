---
title: O que uma execução parada entrega
version: 2
---

Uma execução que para sem resposta ainda deve uma a alguém. A pior coisa que ela pode devolver é nada, e a segunda pior é uma resposta confiante construída com metade do trabalho. O `agent.py` devolve uma terceira coisa: um relato honesto de até onde chegou, numa forma que uma pessoa consegue assumir.

As execuções da seção 04 pararam antes de existir qualquer plano, então a passagem delas só pode dizer *No plan was written*. Aqui está o dublê da seção 03, que planeja, parado por um limite de 3 passos:

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

O `reason` diz qual limite disparou. `done` e `not_done` vêm do plano. O `handoff` é uma frase que uma fila de suporte pode mostrar a quem assume o caso. **O cliente nunca vê uma resposta inventada**; ele espera uma pessoa, e a pessoa começa de onde o agente parou.

## O plano ficou atrás do trabalho

Leia esse resultado contra os passos impressos acima dele e algo está errado. O `not_done` lista *Find adventure books in stock*, mas o passo 3 chamou o `find_books` e recebeu dois livros. O plano foi escrito na mesma resposta que a busca, antes de a busca rodar, então ainda dizia `todo`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"O plano contra o trabalho na execução parada em três passos. O passo 1 escreveu o plano. O passo 2 consultou o M-1045. O passo 3, numa resposta, marcou a consulta como feita e chamou find_books, que devolveu dois livros. A execução então parou. O plano ainda diz que achar livros não foi feito, porque o modelo escreveu o plano antes de a busca rodar.\"><defs></defs><text x=\"20\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">passo</text><text x=\"90\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o que o plano dizia</text><text x=\"420\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o que as ferramentas devolveram</text><text x=\"28\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><rect x=\"80\" y=\"40\" width=\"300\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"92\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">plano escrito, 3 passos a fazer</text><rect x=\"410\" y=\"40\" width=\"290\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"422\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nada ainda</text><text x=\"28\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2</text><rect x=\"80\" y=\"92\" width=\"300\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"92\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">sem mudança</text><rect x=\"410\" y=\"92\" width=\"290\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"422\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">M-1045: packed</text><text x=\"28\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">3</text><rect x=\"80\" y=\"144\" width=\"300\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"92\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">consulta feita; livros: não feita</text><rect x=\"410\" y=\"144\" width=\"290\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"422\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">dois livros em estoque</text></svg>", "caption": "O plano é o relato do modelo sobre o trabalho. Os resultados das ferramentas são o trabalho.", "same": ["M-1045: packed"]}
```

As respostas do dublê foram escritas para fazer isso, e um modelo que planeja faz a mesma coisa sozinho sempre que atualiza o plano e age numa só resposta: **um plano é o relato do modelo sobre o trabalho, e ele está sempre pelo menos um passo atrás.** Uma passagem montada só a partir do plano manda a pessoa refazer trabalho já feito, ou, pior, omite um resultado que importa. Uma passagem melhor inclui os resultados das ferramentas que a execução coletou, numa forma que uma pessoa consiga ler, ao lado do plano. O `agent.py` não faz isso, para continuar curto; o agente da aula 7 registra cada chamada e cada resultado no rastro, e a passagem dele aponta para isso.

## Respostas parciais

Uma execução parada às vezes tem o bastante para parte do pedido: aqui, o status do pedido era conhecido depois do passo 2, e nas execuções da seção 04, que não escreveram plano nenhum, as duas consultas tinham voltado antes de o limite disparar e a passagem mesmo assim não dizia nada sobre elas. Mandar essa parte é uma decisão de produto. Mandar é mais gentil com o cliente; não mandar evita a confusão de uma resposta que ignora metade da pergunta. De um jeito ou de outro, a decisão deve ser do hospedeiro, escrita em código, e não um improviso do modelo sob um limite que ele não vê.
