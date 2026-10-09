---
title: Medindo, com honestidade
version: 2
---

Quarenta mensagens são uma amostra pequena para uma mudança que deveria ajudar nos casos difíceis,
então esta medição usa mais trinta: mensagens guardadas longe de tudo até agora, escritas para serem
mais difíceis, com os rótulos que uma pessoa deu. Salve-as como `cases/holdout.jsonl`:

```
{"id": "h01", "message": "I returned the paperback but you refunded the wrong card.", "expect": {"category": "billing", "urgency": "normal"}}
{"id": "h02", "message": "The delivery driver left my parcel with a neighbour I don't know. Can you find out who has it?", "expect": {"category": "delivery", "urgency": "normal"}}
{"id": "h03", "message": "My account shows an order I never placed and my card has been charged for it.", "expect": {"category": "billing", "urgency": "high"}}
{"id": "h04", "message": "I'd like to return the atlas, but the courier you use doesn't collect from my area.", "expect": {"category": "returns", "urgency": "normal"}}
{"id": "h05", "message": "Can you send the invoice to my work email instead of my personal one?", "expect": {"category": "billing", "urgency": "low"}}
{"id": "h06", "message": "The box arrived empty. The packing slip says three books.", "expect": {"category": "delivery", "urgency": "high"}}
{"id": "h07", "message": "How do I update the card saved in my account?", "expect": {"category": "billing", "urgency": "low"}}
{"id": "h08", "message": "I was sent a refund for the wrong amount after my return.", "expect": {"category": "returns", "urgency": "normal"}}
{"id": "h09", "message": "Your password rules won't let me use a space. Is that deliberate?", "expect": {"category": "account", "urgency": "low"}}
{"id": "h10", "message": "I placed an order as a guest. Can I attach it to my account now?", "expect": {"category": "account", "urgency": "low"}}
{"id": "h11", "message": "The tracking page shows my full home address to anyone with the link. That worries me.", "expect": {"category": "account", "urgency": "high"}}
{"id": "h12", "message": "I paid for gift wrapping and the book came unwrapped.", "expect": {"category": "billing", "urgency": "normal"}}
{"id": "h13", "message": "The second volume in the set is the wrong edition. Everything else is fine.", "expect": {"category": "returns", "urgency": "normal"}}
{"id": "h14", "message": "Is the price of the boxed set going down in the sale next week?", "expect": {"category": "other", "urgency": "low"}}
{"id": "h15", "message": "I can't see my order history since the website changed.", "expect": {"category": "account", "urgency": "normal"}}
{"id": "h16", "message": "My order arrived but one book was signed and the other wasn't, though both were listed as signed.", "expect": {"category": "returns", "urgency": "normal"}}
{"id": "h17", "message": "The courier damaged my gate getting the parcel through.", "expect": {"category": "delivery", "urgency": "normal"}}
{"id": "h18", "message": "I want a refund for my subscription box: the last two arrived damaged.", "expect": {"category": "returns", "urgency": "normal"}}
{"id": "h19", "message": "Please stop sending me catalogues by post.", "expect": {"category": "account", "urgency": "low"}}
{"id": "h20", "message": "Do you deliver to Portugal, and how much does it cost?", "expect": {"category": "delivery", "urgency": "low"}}
{"id": "h21", "message": "I bought the wrong book by mistake. It hasn't been dispatched yet. Can you cancel it?", "expect": {"category": "delivery", "urgency": "normal"}}
{"id": "h22", "message": "My payment failed three times and now the order has disappeared from my account.", "expect": {"category": "billing", "urgency": "high"}}
{"id": "h23", "message": "The ebook download link says it has expired.", "expect": {"category": "returns", "urgency": "normal"}}
{"id": "h24", "message": "A book I pre-ordered in March still hasn't been dispatched and the release date was last month.", "expect": {"category": "delivery", "urgency": "high"}}
{"id": "h25", "message": "I've been charged in euros instead of pounds.", "expect": {"category": "billing", "urgency": "normal"}}
{"id": "h26", "message": "Can I reserve a book in the shop and pay when I collect it?", "expect": {"category": "other", "urgency": "low"}}
{"id": "h27", "message": "Someone used my gift card balance before I did.", "expect": {"category": "account", "urgency": "high"}}
{"id": "h28", "message": "The reading group discount wasn't applied to my order.", "expect": {"category": "billing", "urgency": "normal"}}
{"id": "h29", "message": "I sent the book back with the return label but the label had someone else's address.", "expect": {"category": "returns", "urgency": "normal"}}
{"id": "h30", "message": "Thank you for sorting out the refund so quickly last week.", "expect": {"category": "other", "urgency": "low"}}
```

Junte os dois conjuntos num arquivo só, que as aulas seguintes também usam, e rode os dois prompts
nas setenta:

```
ana@lab:~/triage$ cat cases/dev.jsonl cases/holdout.jsonl > cases/all.jsonl
ana@lab:~/triage$ wc -l cases/all.jsonl
70 cases/all.jsonl
ana@lab:~/triage$ pl run prompts/v8-rules.txt cases/all.jsonl --out runs/rules.jsonl
70 calls, prompt 65da61bb, llama3.2:3b, written to runs/rules.jsonl
ana@lab:~/triage$ pl run prompts/v8-guide.txt cases/all.jsonl --out runs/guide.jsonl
70 calls, prompt d0591569, llama3.2:3b, written to runs/guide.jsonl
ana@lab:~/triage$ pl check runs/rules.jsonl
check      pass  fail
json         70     0
fields       70     0
labels       70     0
category     52    18
urgency      27    43
all          27    43
ana@lab:~/triage$ pl check runs/guide.jsonl
check      pass  fail
json         68     2
fields       68     2
labels       68     2
category     54    16
urgency      31    39
all          31    39
```

As regras passam 27 e o guia 31. Antes de ler alguma coisa em quatro mensagens, compare caso a
caso:

```
ana@lab:~/triage$ pl compare runs/rules.jsonl runs/guide.jsonl
runs/rules.jsonl         passes 27/70
runs/guide.jsonl         passes 31/70
fixed 6, broken 2
broken: t22 h24
sign test on the 8 that changed: p = 0.289
```

Oito mensagens mudaram, seis para um lado e duas para o outro. Uma moeda honesta divide oito
lançamentos de forma pelo menos tão desigual umas três vezes em dez (p = 0.289). **Essa não é uma
diferença que este conjunto de teste consiga detectar.** O guia pode ser melhor; setenta mensagens
não conseguem dizer.

## O que os totais escondem

Os dois prompts não são o mesmo prompt, porém. Compare as categorias, lidas sem os vereditos, e
onze diferem:

```
ana@lab:~/triage$ pl compare runs/rules.jsonl runs/guide.jsonl --answers
70 cases, same answer 59, different answer 11
  t22    billing -> other
  t25    delivery -> account
  t26    account -> returns
  t35    account -> other
  t38    delivery -> None
  t39    delivery -> account
  t40    account -> other
  h19    delivery -> other
  h24    delivery -> None
  h26    account -> other
  h28    billing -> returns
```

E as falhas de urgência apontam para direções opostas. Com as regras, 15 mensagens voltaram com
urgência abaixo da que a pessoa deu e 10 acima; com o guia, 8 abaixo e 15 acima. Conte-as nas duas
listas:

```
ana@lab:~/triage$ pl check runs/rules.jsonl --failures
check      pass  fail
json         70     0
fields       70     0
labels       70     0
category     52    18
urgency      27    43
all          27    43

t02    urgency   low, expected normal
t03    urgency   low, expected normal
t04    urgency   low, expected high
t07    urgency   low, expected normal
t08    urgency   high, expected normal
t09    urgency   high, expected normal
t12    urgency   low, expected high
t16    urgency   high, expected normal
t18    urgency   low, expected normal
t19    category  delivery, expected account
t24    urgency   low, expected normal
t25    category  delivery, expected account
t26    category  account, expected billing
t32    urgency   low, expected normal
t33    urgency   low, expected normal
t35    category  account, expected other
t37    urgency   low, expected normal
t38    category  delivery, expected returns
t39    category  delivery, expected account
t40    category  account, expected other
h01    category  returns, expected billing
h02    urgency   low, expected normal
h04    urgency   low, expected normal
h05    urgency   high, expected low
h06    category  returns, expected delivery
h07    category  account, expected billing
h08    urgency   high, expected normal
h11    category  delivery, expected account
h12    category  returns, expected billing
h13    urgency   low, expected normal
h15    urgency   low, expected normal
h16    urgency   low, expected normal
h17    urgency   high, expected normal
h18    urgency   high, expected normal
h19    category  delivery, expected account
h21    category  returns, expected delivery
h23    category  delivery, expected returns
h25    urgency   high, expected normal
h26    category  account, expected other
h27    category  billing, expected account
h28    urgency   high, expected normal
h29    urgency   high, expected normal
h30    category  returns, expected other
ana@lab:~/triage$ pl check runs/guide.jsonl --failures
check      pass  fail
json         68     2
fields       68     2
labels       68     2
category     54    16
urgency      31    39
all          31    39

t02    urgency   high, expected normal
t03    urgency   low, expected normal
t07    urgency   high, expected normal
t08    urgency   high, expected normal
t09    urgency   high, expected normal
t16    urgency   high, expected normal
t18    urgency   high, expected normal
t19    category  delivery, expected account
t22    category  other, expected billing
t24    urgency   high, expected normal
t25    urgency   low, expected normal
t26    category  returns, expected billing
t32    urgency   high, expected normal
t33    urgency   low, expected normal
t37    urgency   high, expected normal
t38    json      not a JSON object
t39    urgency   low, expected normal
h01    category  returns, expected billing
h02    urgency   high, expected normal
h04    urgency   low, expected normal
h06    category  returns, expected delivery
h07    category  account, expected billing
h08    urgency   high, expected normal
h11    category  delivery, expected account
h12    category  returns, expected billing
h13    urgency   low, expected normal
h15    urgency   low, expected normal
h16    urgency   low, expected normal
h17    urgency   high, expected normal
h18    urgency   high, expected normal
h19    category  other, expected account
h21    category  returns, expected delivery
h23    category  delivery, expected returns
h24    json      not a JSON object
h25    urgency   high, expected normal
h27    category  billing, expected account
h28    category  returns, expected billing
h29    urgency   high, expected normal
h30    category  returns, expected other
```

A linha 12 das regras, *NEVER mark a question as high urgency*, puxa as respostas para baixo: o
`t04`, alguém que não consegue entrar, e o `t12`, um pacote marcado como entregue que nunca chegou,
foram os dois para `low` onde uma pessoa disse `high`. O *a customer out of pocket ... is high
however politely they ask* do guia as puxa para cima: o `t02`, o `t07` e uma série de outras que uma
pessoa chamou de `normal` voltaram `high`. **Cada prompt tem uma direção para a qual pende**, e o
total de cada um é a soma de um conjunto diferente de erros. Dois prompts podem ficar a quatro um do
outro e errar sobre clientes diferentes.

## O caso pelo qual duas regras brigaram

```
ana@lab:~/triage$ pl show runs/rules.jsonl t22
│ {"category": "billing", "urgency": "low", "summary": "Inquiring about payment options for an order."}
stop: stop, tokens in 233, out 28, 3.5 s
ana@lab:~/triage$ pl show runs/guide.jsonl t22
│ {"category": "other", "urgency": "low", "summary": "Customer wants to know if they can use a gift card and a credit card together on an order."}
stop: stop, tokens in 287, out 39, 4.9 s
```

O `t22` voltou certo com as regras, `billing` e `low`, e errado com o guia, que o chamou de `other`.
Então, justamente na mensagem que o princípio foi escrito para resolver, a lista de regras venceu. É
uma mensagem, e é o tipo de resultado a relatar e não a explicar para longe: o argumento a favor do
guia fez uma previsão sobre o `t22`, e neste modelo a previsão falhou.

## Para que serve a medição

Então o relato honesto desta seção é **nenhuma diferença detectada em setenta casos**, com duas notas
anexas: os prompts erram a urgência em direções opostas, e o guia perdeu o caso a partir do qual foi
defendido. Não *o guia é melhor*, e não *o guia não funciona*. Uma afirmação de que explicações
vencem regras por alguma porcentagem, feita sem uma execução como esta, é uma afirmação sobre o
modelo e o conjunto de teste de outra pessoa, e no seu é uma hipótese até você rodá-la. A aula 11
trata de montar um conjunto de teste grande o bastante, e dirigido o bastante, para detectar as
diferenças que importam a você.
