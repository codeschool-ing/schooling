---
title: O que um exemplo corrige
version: 1
---

O primeiro prompt que alguém escreve descreve a tarefa e para por aí. É uma frase razoável, e **ela
deixa para o modelo todas as decisões sobre a forma da resposta**:

```
ana@lab:~/triage$ cat prompts/v1-bare.txt
Sort this customer message for the support team. Say what it is about and how urgent it is.

Message: {{message}}
ana@lab:~/triage$ pl run prompts/v1-bare.txt cases/dev.jsonl --out runs/v1.jsonl
40 calls, prompt a4ffc4b1, written to runs/v1.jsonl
ana@lab:~/triage$ pl show runs/v1.jsonl t01
│ Sure! Here is the triage for this message.
│
│ Type: Payment
│ Priority: urgent
│ Summary: They were charged twice for order 4471.
stop: end, tokens in 36, out 26
ana@lab:~/triage$ pl check runs/v1.jsonl
check      pass  fail
json          0    40
fields        0    40
labels        0    40
category      0    40
urgency       0    40
all           0    40
```

O `pl show` mostra uma resposta atrás de uma barra, para você ver exatamente onde ela começa e
termina. A resposta para `t01` está certa, e uma pessoa a leria sem problema. Um programa não: não é
JSON, os campos se chamam `Type` e `Priority`, e os valores são as palavras do próprio modelo para as
categorias, `Payment` e `urgent`. **Nada disso é erro do modelo.** O prompt nunca disse JSON, nunca
deu nome a um campo e nunca listou um rótulo, então o modelo preencheu cada lacuna com algo
plausível.

## Descrever a resposta

A segunda versão diz as três coisas em palavras:

```
ana@lab:~/triage$ pl run prompts/v2-json.txt cases/dev.jsonl --out runs/v2.jsonl
40 calls, prompt 9c365e2d, written to runs/v2.jsonl
ana@lab:~/triage$ pl check runs/v2.jsonl
check      pass  fail
json         27    13
fields       27    13
labels       27    13
category     27    13
urgency      24    16
all          24    16
ana@lab:~/triage$ pl show runs/v2.jsonl t03
│ ```json
│ {
│   "category": "returns",
│   "urgency": "normal",
│   "summary": "The book arrived with the cover torn."
│ }
│ ```
stop: end, tokens in 81, out 39
ana@lab:~/triage$ pl show runs/v2.jsonl t06
│ Here is the JSON you asked for:
│
│ {
│   "category": "billing",
│   "urgency": "low",
│   "summary": "Asks: where can I find a copy of my invoice for last month's order?"
│ }
stop: end, tokens in 80, out 50
```

Vinte e quatro de quarenta agora passam em tudo. As treze que falham em `json` têm o conteúdo certo
no invólucro errado: `t03` está dentro de um bloco de código Markdown, `t06` tem uma frase na frente.
Os dois são hábitos que uma descrição não alcança, porque a descrição nunca disse o que pode vir **em
volta** do JSON.

## Mostrar a resposta

A terceira versão mantém a descrição e acrescenta três exemplos, cada um com uma mensagem e a
resposta exata para ela:

```
ana@lab:~/triage$ cat prompts/v3-examples.txt
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
ana@lab:~/triage$ pl run prompts/v3-examples.txt cases/dev.jsonl --out runs/v3.jsonl
40 calls, prompt 1d9c6ec4, written to runs/v3.jsonl
ana@lab:~/triage$ pl check runs/v3.jsonl --failures
check      pass  fail
json         40     0
fields       40     0
labels       40     0
category     39     1
urgency      36     4
all          36     4

t14    urgency   normal, expected low
t24    urgency   low, expected normal
t28    urgency   normal, expected low
t37    category  billing, expected delivery
```

**Toda resposta é analisável.** As quatro que ainda falham são discordâncias sobre um rótulo, que é
outro problema, com outras soluções, e a aula 12 é onde elas são medidas direito.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Quarenta respostas a cada um de três prompts, separadas pela primeira verificação em que falharam. O prompt nu: as 40 falham no formato. Pedindo JSON: 13 falham no formato, 3 num rótulo, 24 passam. Três exemplos: nenhuma falha no formato, 4 num rótulo, 36 passam.\"><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">40 respostas, pela primeira verificação em que cada uma falhou</text><text x=\"158\" y=\"70\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">prompt nu</text><rect x=\"170\" y=\"56\" width=\"500.0\" height=\"28\" rx=\"2\" fill=\"var(--wire)\"></rect><text x=\"680.0\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">0</text><text x=\"158\" y=\"122\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">pede JSON</text><rect x=\"170\" y=\"108\" width=\"162.5\" height=\"28\" rx=\"2\" fill=\"var(--wire)\"></rect><rect x=\"332.5\" y=\"108\" width=\"37.5\" height=\"28\" rx=\"2\" fill=\"var(--amber)\"></rect><rect x=\"370.0\" y=\"108\" width=\"300.0\" height=\"28\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"680.0\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">24</text><text x=\"158\" y=\"174\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">três exemplos</text><rect x=\"170.0\" y=\"160\" width=\"50.0\" height=\"28\" rx=\"2\" fill=\"var(--amber)\"></rect><rect x=\"220.0\" y=\"160\" width=\"450.0\" height=\"28\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"680.0\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">36</text><rect x=\"170\" y=\"216\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--wire)\"></rect><text x=\"188\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">formato</text><rect x=\"340\" y=\"216\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"358\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">rótulo errado</text><rect x=\"510\" y=\"216\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"528\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">passa em tudo</text></svg>", "caption": "As mesmas quarenta mensagens em três prompts. Pedir JSON resolveu quase todo o formato; os exemplos resolveram o resto, e as quatro falhas que sobram são discordâncias sobre um rótulo."}
```

## Foi sorte?

Trinta e seis contra vinte e quatro parece decisivo, mas uma contagem pode mudar por motivos que nada
têm a ver com a mudança. O `pl compare` alinha as duas execuções mensagem por mensagem:

```
ana@lab:~/triage$ pl compare runs/v2.jsonl runs/v3.jsonl
runs/v2.jsonl            passes 24/40
runs/v3.jsonl            passes 36/40
fixed 13, broken 1, still passing 23, still failing 3
broken: t37
sign test on the 14 that changed: p = 0.002
```

Só as catorze mensagens cujo resultado mudou trazem alguma evidência, e treze foram para o mesmo
lado. O **teste do sinal** pergunta com que frequência uma moeda honesta dividiria catorze
lançamentos de forma ao menos tão desigual, e a resposta é duas vezes em mil. A aula 7 usa o mesmo
teste numa mudança que acaba sendo ruído, que é o caso para o qual ele existe.

A mensagem que ela quebrou, `t37`, é o assunto da próxima seção.

## Por que funciona

No substituto o mecanismo está escrito: com um exemplo no prompt, ele **copia a forma da resposta do
primeiro exemplo** e preenche com os próprios valores. Em modelos reais o efeito é um dos resultados
mais antigos da área. O artigo que apresentou o GPT-3, *Language Models are Few-Shot Learners*
(Brown e outros, 2020), leva o nome dele: um punhado de demonstrações no prompt aumentou a acurácia
do modelo em muitas tarefas sem mudar um único peso. Um estudo posterior, *Rethinking the Role of
Demonstrations* (Min e outros, 2022), concluiu que boa parte do ganho vinha de os exemplos mostrarem
o formato e o conjunto de rótulos, e que ele sobrevivia mesmo quando os rótulos dos exemplos estavam
errados.

Esse é o jeito útil de pensar num exemplo: **uma descrição diz o que você quer; um exemplo é uma
instância disso**, e uma instância deixa menos coisa para preencher.
