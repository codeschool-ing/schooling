---
title: O que um exemplo conserta
version: 2
---

O primeiro prompt que qualquer pessoa escreve descreve a tarefa e para. É uma frase razoável, e
**ela deixa ao modelo toda decisão sobre a forma da resposta**. Salve-o como
`prompts/v1-bare.txt`:

```
Sort this customer message for the support team. Say what it is about and how urgent it is.

Message: {{message}}
```

Depois rode-o nas quarenta mensagens e olhe duas das respostas:

```
ana@lab:~/triage$ pl run prompts/v1-bare.txt cases/dev.jsonl --out runs/v1.jsonl
40 calls, prompt a4ffc4b1, llama3.2:3b, written to runs/v1.jsonl
```
```
ana@lab:~/triage$ pl show runs/v1.jsonl t01
│ Here is the sorted customer message:
│
│ **Message:** I was charged twice for order 4471. Please refund the second payment.
│
│ **Category:** Refund Request
│
│ **Urgency:** Medium
│
│ **Reason:** The customer is requesting a refund for a duplicate payment, which is a relatively straightforward issue. However, it's not an emergency situation, and the customer is not experiencing any immediate financial harm. A timely response to resolve the issue would be appreciated, but it's not critical.
stop: stop, tokens in 63, out 99, 34.8 s
ana@lab:~/triage$ pl show runs/v1.jsonl t02
│ Here is the sorted customer message:
│
│ **Message:** My parcel was meant to arrive on Monday and the tracking hasn't moved since Friday.
│
│ **Category:** Delivery Issue
│
│ **Urgency:** Medium
│
│ **Reason:** The customer is concerned about the delayed delivery of their parcel, which was expected to arrive on Monday. The tracking information has not updated since Friday, indicating a potential issue with the delivery.
│
│ **Action Required:** The support team should investigate the status of the parcel, check for any updates or notifications from the courier, and provide a resolution or estimated delivery date to the customer.
stop: stop, tokens in 64, out 118, 12.7 s
ana@lab:~/triage$ pl check runs/v1.jsonl
check      pass  fail
json          0    40
fields        0    40
labels        0    40
category      0    40
urgency       0    40
all           0    40
```

O `pl show` imprime uma resposta atrás de uma barra, para que dê para ver exatamente onde ela
começa e termina. As duas respostas fazem sentido, e uma pessoa as leria sem problema. Um programa
não: elas não são JSON, os rótulos são palavras do próprio modelo, *Refund Request* e *Delivery
Issue*, a urgência é *Medium*, que não está na lista da Folio, e a segunda resposta acrescentou um
*Action Required* que ninguém pediu. **Nada disso é erro do modelo.** O prompt nunca disse JSON,
nunca nomeou um campo e nunca listou um rótulo, então o modelo preencheu cada lacuna com algo
plausível.

Olhe também o último número de cada resposta. A primeira levou 34,8 segundos, porque foi a primeira
chamada depois que o Ollama subiu e quase todo esse tempo foi carregar o modelo na memória. A
segunda levou 12,7, e não havia modelo para carregar: ela tinha 118 tokens, e um modelo num
processador os escreve um de cada vez. **Uma resposta que ninguém pediu também é uma resposta pela
qual você espera.**

## Descrevendo a resposta

A segunda versão diz as três coisas em palavras. Salve-a como `prompts/v2-json.txt`:

```
You sort customer messages for Folio, an online bookshop.

Read the message and answer in JSON with three fields:
- "category": one of billing, delivery, returns, account, other
- "urgency": one of low, normal, high
- "summary": one sentence saying what the customer needs

Message: {{message}}
```

```
ana@lab:~/triage$ pl run prompts/v2-json.txt cases/dev.jsonl --out runs/v2.jsonl
40 calls, prompt 9c365e2d, llama3.2:3b, written to runs/v2.jsonl
ana@lab:~/triage$ pl check runs/v2.jsonl --failures
check      pass  fail
json         39     1
fields       39     1
labels       39     1
category     31     9
urgency      22    18
all          22    18

t02    urgency   high, expected normal
t06    category  account, expected billing
t07    urgency   high, expected normal
t09    urgency   high, expected normal
t16    urgency   high, expected normal
t18    urgency   high, expected normal
t19    category  delivery, expected account
t22    category  other, expected billing
t24    urgency   low, expected normal
t25    category  other, expected account
t26    category  account, expected billing
t31    category  returns, expected billing
t32    urgency   high, expected normal
t33    urgency   low, expected normal
t36    category  account, expected billing
t37    urgency   high, expected normal
t38    json      not a JSON object
t39    category  delivery, expected account
ana@lab:~/triage$ pl show runs/v2.jsonl t38
│ {"category": "returns", "urgency": "high", "summary": "Ebook won"}}
stop: stop, tokens in 103, out 22, 2.2 s
```

Trinta e nove das quarenta respostas agora são JSON válido, e vinte e duas passam em tudo. **O
formato era a parte fácil.** O que sobra é quase só sobre rótulos, e tem um padrão: sete das
dezoito falhas são uma mensagem que uma pessoa chamou de `normal` e o modelo chamou de `high`.
Perguntado sobre o quanto algo é urgente, sem nenhuma ideia do que a loja quer dizer com cada
palavra, ele pende para o urgente.

A única resposta que não é JSON válido vale uma olhada. O resumo do `t38`, um cliente cujo ebook
*won't* abrir, para em *won* e o objeto fecha duas vezes. O modelo escreveu o apóstrofo de *won't*
e se perdeu. Isso não é um hábito que uma descrição alcance: a descrição nunca disse o que fazer
com um apóstrofo, e nada poderia dizer.

## Mostrando

A terceira versão mantém a descrição e acrescenta três exemplos, cada um uma mensagem e a resposta
exata para ela. Salve-a como `prompts/v3-examples.txt`:

```
You sort customer messages for Folio, an online bookshop.

Read the message and answer in JSON with three fields:
- "category": one of billing, delivery, returns, account, other
- "urgency": one of low, normal, high
- "summary": one sentence saying what the customer needs

<example>
Message: I paid for express delivery but the order came by normal post.
Output: {"category": "billing", "urgency": "normal", "summary": "Wants the express delivery charge back."}
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
ana@lab:~/triage$ pl run prompts/v3-examples.txt cases/dev.jsonl --out runs/v3.jsonl
40 calls, prompt 1d9c6ec4, llama3.2:3b, written to runs/v3.jsonl
ana@lab:~/triage$ pl check runs/v3.jsonl --failures
check      pass  fail
json         39     1
fields       39     1
labels       39     1
category     35     5
urgency      28    12
all          28    12

t01    urgency   normal, expected high
t02    urgency   high, expected normal
t07    urgency   high, expected normal
t09    urgency   high, expected normal
t22    category  other, expected billing
t24    urgency   high, expected normal
t25    category  other, expected account
t26    category  account, expected billing
t32    urgency   high, expected normal
t33    category  delivery, expected returns
t37    json      not a JSON object
t39    urgency   low, expected normal
```

Vinte e oito passam agora. Duas das urgências infladas sumiram, `t16` e `t18`, assim como quatro
erros de categoria, e o `t38` agora é JSON válido, embora o `t37`, que antes falhava na urgência,
agora nem seja JSON válido. Os exemplos mostram o que *normal* quer dizer aqui: um livro danificado
e uma entrega expressa que não foi cumprida são os dois `normal`, e nenhum é emergência. A aula 12
mede direito as falhas de urgência que restam.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Quarenta respostas a cada um de três prompts, separadas pela primeira verificação em que falharam. O prompt sem nada: as 40 falham no formato. Pedindo JSON: 1 falha no formato, 17 num rótulo, 22 passam. Três exemplos: 1 falha no formato, 11 num rótulo, 28 passam.\"><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">40 respostas, pela primeira verificação em que cada uma falhou</text><text x=\"158\" y=\"70\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">prompt sem nada</text><rect x=\"170.0\" y=\"56\" width=\"500.0\" height=\"28\" rx=\"2\" fill=\"var(--wire)\"></rect><text x=\"680.0\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">0</text><text x=\"158\" y=\"122\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">pede JSON</text><rect x=\"170.0\" y=\"108\" width=\"12.5\" height=\"28\" rx=\"2\" fill=\"var(--wire)\"></rect><rect x=\"182.5\" y=\"108\" width=\"212.5\" height=\"28\" rx=\"2\" fill=\"var(--amber)\"></rect><rect x=\"395.0\" y=\"108\" width=\"275.0\" height=\"28\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"680.0\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">22</text><text x=\"158\" y=\"174\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">três exemplos</text><rect x=\"170.0\" y=\"160\" width=\"12.5\" height=\"28\" rx=\"2\" fill=\"var(--wire)\"></rect><rect x=\"182.5\" y=\"160\" width=\"137.5\" height=\"28\" rx=\"2\" fill=\"var(--amber)\"></rect><rect x=\"320.0\" y=\"160\" width=\"350.0\" height=\"28\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"680.0\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">28</text><rect x=\"170\" y=\"216\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--wire)\"></rect><text x=\"188\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">formato</text><rect x=\"340\" y=\"216\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"358\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">rótulo errado</text><rect x=\"510\" y=\"216\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"528\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">passa em tudo</text></svg>", "caption": "As mesmas quarenta mensagens em três prompts, no llama3.2:3b. Pedir JSON resolveu o formato; o que sobrou foram quase só rótulos, e os exemplos resolveram parte deles."}
```

## Foi sorte?

Vinte e oito contra vinte e dois parece progresso, mas uma contagem pode mudar por motivos que
nada têm a ver com a mudança. O `pl compare` alinha as duas execuções mensagem por mensagem:

```
ana@lab:~/triage$ pl compare runs/v2.jsonl runs/v3.jsonl
runs/v2.jsonl            passes 22/40
runs/v3.jsonl            passes 28/40
fixed 7, broken 1
broken: t01
sign test on the 8 that changed: p = 0.070
```

Só as oito mensagens cujo resultado mudou trazem alguma evidência, e sete foram para o mesmo lado. O
**teste do sinal** pergunta com que frequência uma moeda honesta dividiria oito lançamentos de forma
pelo menos tão desigual, e a resposta é sete vezes em cem. **Isso sugere, e não prova.** Pelo
critério habitual de cinco em cem, nem significativo é. Com uma mensagem quebrada, como aqui, são
precisas oito consertadas (p = 0,039) antes que a contagem sozinha passe de cinco em cem. A aula 7
trata de ler esse número, e a aula 11 de montar um conjunto de teste grande o bastante para precisar
menos dele.

A única mensagem que os exemplos quebraram, o `t01`, é o assunto da próxima seção.

## Por que funciona

O efeito é um dos resultados mais antigos da área. O artigo que apresentou o GPT-3, *Language
Models are Few-Shot Learners* (Brown e outros, 2020), leva o nome dele: um punhado de
demonstrações no prompt aumentou a precisão do modelo em muitas tarefas sem mudar um único peso. Um
estudo posterior, *Rethinking the Role of Demonstrations* (Min e outros, 2022), descobriu que boa
parte do ganho vinha de os exemplos mostrarem o formato e o conjunto de rótulos. Essa parte do
ganho sobrevivia mesmo quando os rótulos dos exemplos estavam errados.

Esse é o jeito útil de pensar num exemplo: **uma descrição diz o que você quer; um exemplo é uma
instância disso**, e uma instância deixa menos para preencher.
