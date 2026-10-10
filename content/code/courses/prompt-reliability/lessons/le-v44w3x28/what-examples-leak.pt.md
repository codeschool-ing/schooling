---
title: O que os exemplos vazam
version: 2
---

Um exemplo mostra a resposta, e **o modelo copia mais dela do que você quis dizer como resposta**.
Veja como uma mensagem voltou sem os exemplos e com eles:

```
ana@lab:~/triage$ pl show runs/v2.jsonl t22
│ {"category": "other", "urgency": "low", "summary": "Customer wants to know if they can use a gift card and a credit card together in one order"}
stop: stop, tokens in 108, out 38, 3.8 s
ana@lab:~/triage$ pl show runs/v3.jsonl t22
│ {"category": "other", "urgency": "low", "summary": "Asks about payment options for a gift card and credit card."}
stop: stop, tokens in 250, out 32, 4.0 s
```

O resumo mudou de voz. Sem exemplos ele começava com *"Customer wants to know"*; com eles começa
com *"Asks about"*, porque dois dos três resumos dos exemplos começam com *Wants* e um com *Asks*.
Nada confere isso e nada precisa conferir, mas é o primeiro sinal do que o próximo arquivo faz de
propósito.

## Um campo que ninguém quis

`prompts/v3-leaky.txt` é o `v3-examples.txt` com uma mudança. Alguém copiou o primeiro exemplo de
um chamado real e manteve o número do pedido. Salve-o como `prompts/v3-leaky.txt`:

```
You sort customer messages for Folio, an online bookshop.

Read the message and answer in JSON with three fields:
- "category": one of billing, delivery, returns, account, other
- "urgency": one of low, normal, high
- "summary": one sentence saying what the customer needs

<example>
Message: I paid for express delivery but the order came by normal post.
Output: {"category": "billing", "urgency": "normal", "summary": "Wants the express delivery charge back.", "order": "4471"}
</example>

<example>
Message: The book came with water damage on every page.
Output: {"category": "returns", "urgency": "normal", "summary": "Wants a replacement for a damaged book."}
</example>

<example>
Message: Can I change the name on my account?
Output: {"category": "account", "urgency": "low", "summary": "Asks how to change the account name."}
</example>

Message: {{message}}
```

```
ana@lab:~/triage$ grep -n order prompts/v3-leaky.txt
9:Message: I paid for express delivery but the order came by normal post.
10:Output: {"category": "billing", "urgency": "normal", "summary": "Wants the express delivery charge back.", "order": "4471"}
ana@lab:~/triage$ pl run prompts/v3-leaky.txt cases/dev.jsonl --out runs/leaky.jsonl
40 calls, prompt 0acdc3c7, llama3.2:3b, written to runs/leaky.jsonl
ana@lab:~/triage$ pl check runs/leaky.jsonl --failures
check      pass  fail
json         39     1
fields       34     6
labels       34     6
category     30    10
urgency      24    16
all          24    16

t01    fields    unexpected order
t02    urgency   high, expected normal
t07    urgency   high, expected normal
t08    fields    unexpected order
t09    urgency   high, expected normal
t16    fields    unexpected order
t21    fields    unexpected order
t22    category  other, expected billing
t24    urgency   high, expected normal
t25    category  other, expected account
t26    category  account, expected billing
t31    fields    unexpected order
t32    urgency   high, expected normal
t33    category  delivery, expected returns
t37    json      not a JSON object
t39    urgency   low, expected normal
```

Cinco respostas trazem um campo chamado `order` que ninguém pediu. Não são aleatórias: `t01`,
`t08`, `t16`, `t21` e `t31` são todas mensagens sobre um pedido ou um pagamento, as mais parecidas
com o exemplo que o trazia. E olhe o valor:

```
ana@lab:~/triage$ grep -c 4471 runs/leaky.jsonl
5
ana@lab:~/triage$ pl show runs/leaky.jsonl t16
│ {"category": "billing", "urgency": "normal", "summary": "Wants a refund for the £3 price difference.", "order": "4471"}
stop: stop, tokens in 256, out 36, 4.0 s
```

O `grep` conta cinco respostas com `4471`, e só um cliente, o `t01`, chegou a mencionar o pedido
4471. O `t16` é alguém cobrado três libras a mais, e o modelo deu a ele o número de pedido do
exemplo, porque tinha um campo que viu e nenhum valor próprio para pôr nele. **Nomes, datas e
números de exemplos aparecem em respostas sobre outra coisa.**



**A verificação pegou porque é estrita.** `fields` reprova uma resposta com um campo que ninguém
pediu. Uma verificação que só procurasse os campos de que precisa teria aprovado as cinco, e um
número de pedido errado teria chegado a quem lê o JSON em seguida, igualzinho a um certo.

**E uma demonstração nunca o teria mostrado.** Teste o prompt com vazamento numa mensagem só, *"I
can't log in"*, e a resposta vem limpa. O defeito mora em cinco mensagens de quarenta, as que se
parecem com o exemplo, e só um conjunto de teste é grande o bastante para contê-las.

## Impedindo os exemplos de ensinar a coisa errada

- Varie o que deve variar. Os resumos aqui começam com *Wants*, *Wants* e *Asks*, e os resumos do
  modelo agora começam do mesmo jeito.
- Tire o que pertence a um cliente: nomes, números de pedido, datas, valores. Troque por valores
  que obviamente são exemplos, ou deixe de fora.
- Faça os exemplos responderem exatamente ao que o prompt pede, campo por campo. Um exemplo é a
  instrução mais forte de um prompt, então um exemplo que discorda da descrição vence.
- Confira de forma estrita, para que o que um exemplo vaza reprove um teste em vez de chegar a um
  leitor.
