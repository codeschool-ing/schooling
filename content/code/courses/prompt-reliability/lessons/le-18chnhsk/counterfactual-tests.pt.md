---
title: Testes contrafactuais
version: 2
---

Os vieses até aqui vieram do prompt. Alguns vêm da mensagem: um nome, um dialeto, um país, um jeito
de escrever que diz ao modelo algo sobre o cliente que não tem nada a ver com o problema. **Um teste
contrafactual muda só esse detalhe** e confere que nada mais se mexe.

Aqui estão oito mensagens, todas assinadas pela mesma cliente. Salve-as como `cases/names-a.jsonl`:

```
{"id": "n01", "message": "Maria Souza here. I was charged twice for order 5120.", "expect": {"category": "billing", "urgency": "high"}}
{"id": "n02", "message": "Hi, it's Maria Souza. My parcel still hasn't arrived after a week.", "expect": {"category": "delivery", "urgency": "normal"}}
{"id": "n03", "message": "Maria Souza again: the book came with a torn cover, can I return it?", "expect": {"category": "returns", "urgency": "normal"}}
{"id": "n04", "message": "This is Maria Souza. I can't log in since yesterday.", "expect": {"category": "account", "urgency": "high"}}
{"id": "n05", "message": "My name is Maria Souza and I'd like to know if you have signed copies.", "expect": {"category": "other", "urgency": "low"}}
{"id": "n06", "message": "Maria Souza writing. Where can I find my invoice?", "expect": {"category": "billing", "urgency": "low"}}
{"id": "n07", "message": "Hello, Maria Souza here. The courier lost my order.", "expect": {"category": "delivery", "urgency": "high"}}
{"id": "n08", "message": "Maria Souza speaking: please delete my account.", "expect": {"category": "account", "urgency": "normal"}}
```

O segundo conjunto é feito a partir do primeiro com uma substituição, então os dois nunca podem
diferir em mais nada:

```
ana@lab:~/triage$ sed 's/Maria Souza/John Smith/' cases/names-a.jsonl > cases/names-b.jsonl
ana@lab:~/triage$ head -n 1 cases/names-a.jsonl cases/names-b.jsonl
==> cases/names-a.jsonl <==
{"id": "n01", "message": "Maria Souza here. I was charged twice for order 5120.", "expect": {"category": "billing", "urgency": "high"}}

==> cases/names-b.jsonl <==
{"id": "n01", "message": "John Smith here. I was charged twice for order 5120.", "expect": {"category": "billing", "urgency": "high"}}
```

Rode o prompt de triagem sobre os dois:

```
ana@lab:~/triage$ pl run prompts/v6-escaped.txt cases/names-a.jsonl --out runs/names-a.jsonl
8 calls, prompt fbc4c9b1, llama3.2:3b, written to runs/names-a.jsonl
ana@lab:~/triage$ pl run prompts/v6-escaped.txt cases/names-b.jsonl --out runs/names-b.jsonl
8 calls, prompt fbc4c9b1, llama3.2:3b, written to runs/names-b.jsonl
ana@lab:~/triage$ pl compare runs/names-a.jsonl runs/names-b.jsonl --answers
8 cases, same answer 6, different answer 2
  n02    returns -> delivery
  n07    returns -> delivery
ana@lab:~/triage$ pl compare runs/names-a.jsonl runs/names-b.jsonl
runs/names-a.jsonl       passes 3/8
runs/names-b.jsonl       passes 5/8
fixed 2, broken 0
sign test on the 2 that changed: p = 0.500
```

**Duas respostas mudaram quando só o nome mudou.** Aqui estão elas:

```
ana@lab:~/triage$ pl show runs/names-a.jsonl n02
│ {"category": "returns", "urgency": "high", "summary": "Customer is reporting a delayed parcel"}
stop: stop, tokens in 152, out 25, 2.6 s
ana@lab:~/triage$ pl show runs/names-b.jsonl n02
│ {"category": "delivery", "urgency": "high", "summary": "Customer is concerned about delayed parcel arrival"}
stop: stop, tokens in 151, out 26, 2.8 s
ana@lab:~/triage$ pl show runs/names-a.jsonl n07
│ {"category": "returns", "urgency": "high", "summary": "Customer reports lost order"}
stop: stop, tokens in 147, out 23, 2.4 s
ana@lab:~/triage$ pl show runs/names-b.jsonl n07
│ {"category": "delivery", "urgency": "high", "summary": "Customer reports lost order"}
stop: stop, tokens in 146, out 23, 2.3 s
```

O `n02`, um pacote uma semana atrasado, e o `n07`, um pedido que a transportadora perdeu: `returns`
quando Maria Souza escreveu, `delivery` quando John Smith escreveu, com a mesma urgência e quase o
mesmo resumo. As duas são de entrega, então a mudança corrigiu duas.

Duas em oito não mostram que o modelo trata um nome pior que o outro. A aula 8 mostrou respostas com
temperatura 0 virando por uma diferença muito menor que um nome, e um quase empate entre `returns` e
`delivery` pode cair para qualquer lado com qualquer mudança. **O que isso mostra é que o nome chegou
ao rótulo**, e é isso que um teste contrafactual existe para pegar. Para dizer mais, você precisa de
muitos pares e muitos nomes, comparados com o teste do sinal, e a regra para lê-los é a que a aula 7
deu: relate as mudanças, não só os totais.

## Como montá-los

- **Mude um atributo e nada mais.** Um `sed` é o editor mais seguro, porque não consegue reescrever
  nada por acidente.
- **Use atributos que a tarefa deve ignorar**: nomes, lugares, um jeito educado ou seco de escrever,
  ortografia. Uma mensagem sobre um pacote perdido é sobre um pacote perdido, seja quem for que a
  mandou.
- **Mantenha os pares nos conjuntos de teste**, e passe-os pelo portão com todo o resto. Um viés que
  um prompt posterior traga de volta deve reprovar uma verificação, não esperar um cliente notar.
