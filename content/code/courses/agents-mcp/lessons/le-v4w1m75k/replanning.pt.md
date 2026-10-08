---
title: Quando um resultado muda o plano
version: 2
---

Um plano é um palpite sobre o trabalho, feito antes do trabalho. Alguns resultados tornam o palpite errado, e a resposta útil é dizer isso no plano em vez de continuar com passos que deixaram de fazer sentido.

```
ana@lab:~/agents$ python agent.py "Is my order M-1049 delivered, and can I still return it?"
[1] get_order({"order_id": "M-1049"}) -> ERROR LookupError: no order M-1049
{
 "status": "stopped",
 "reason": "replied without calling finish",
 "done": [],
 "not_done": [],
 "handoff": "Passed to a person. No plan was written."
}
```

Esse é o `llama3.2:3b`: uma consulta, um erro, e uma resposta em texto, que o hospedeiro trata como parada. Um modelo que não consegue chamar uma ferramenta depois de um resultado também não consegue reescrever o plano depois de um. O dublê consegue, com a segunda entrada do `plan.json` da seção 03:

```
ana@lab:~/agents$ python agent.py "Is my order M-1049 delivered, and can I still return it?"
[1] plan
      [ ] Look up order M-1049
      [ ] Check the return window
      [ ] Answer
[2] get_order({"order_id": "M-1049"}) -> ERROR LookupError: no order M-1049
[3] plan
      [x] Look up order M-1049
      [-] Check the return window
      [ ] Ask the customer for the order number
{
 "status": "answered",
 "steps": 4,
 "tokens": 0,
 "answer": "I cannot find an order M-1049, so I cannot check its return window yet. Could you send the order number from your confirmation email? It starts with M- and has four digits.",
 "sources": [
  "get_order M-1049"
 ]
}
```

O plano tinha três passos: consultar o M-1049, conferir a janela de devolução, responder. A consulta falhou, `no order M-1049`. Conferir a janela de devolução de um pedido que não existe não tem sentido, então o passo 3 reescreveu o plano: a consulta está `done` (ela rodou, e a resposta dela é que não há tal pedido), a conferência da janela está `dropped`, e um passo novo pede ao cliente o número certo. O passo 4 terminou com exatamente isso.

**`dropped` é o status importante.** Sem ele, as únicas opções do modelo seriam marcar o passo como `done`, o que é falso, ou deixá-lo `todo` para sempre, o que faz a execução parecer inacabada. Com ele, o plano registra uma decisão: este passo foi considerado e abandonado, neste ponto, depois deste resultado. Uma pessoa lendo o resultado depois vê por que a resposta não menciona janela de devolução.

## Quando replanejar, e quando parar

Replanejar é a resposta certa quando um resultado muda o caminho mas o objetivo continua alcançável. É a errada quando o próprio objetivo sumiu, ou quando o agente fica reescrevendo o plano sem progredir. Um hospedeiro pega o segundo caso com pouco custo: contar atualizações de plano que não são seguidas por um resultado novo de ferramenta, e parar depois de algumas. É a linha "nenhum progresso" da tabela da aula 3, aplicada a planos.

Repare também no que as respostas do dublê não fazem, porque um modelo real às vezes faz: supor que o cliente quis dizer M-1048 ou M-1046, os ids existentes mais próximos. **Um agente que "corrige" um id por conta própria é um agente que age sobre o pedido de outra pessoa**, o que a aula 17 trata como problema de permissão.
