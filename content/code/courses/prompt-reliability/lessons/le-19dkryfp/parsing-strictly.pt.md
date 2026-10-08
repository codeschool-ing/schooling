---
title: Interpretando com rigor
version: 2
---

Pedir JSON deu trinta e nove respostas de quarenta que são JSON válido. Uma correção comum para os
hábitos que quebram o JSON, um bloco de código em volta do objeto ou uma frase antes dele, é mais
uma linha dizendo o que pode vir em volta do objeto. Salve-a como `prompts/v4-only-json.txt`:

```
You sort customer messages for Folio, an online bookshop.

Read the message and answer in JSON with three fields:
- "category": one of billing, delivery, returns, account, other
- "urgency": one of low, normal, high
- "summary": one sentence saying what the customer needs

Reply with only the JSON object: no code fence and no other text.

Message: {{message}}
```

```
ana@lab:~/triage$ diff prompts/v2-json.txt prompts/v4-only-json.txt
7a8,9
> Reply with only the JSON object: no code fence and no other text.
> 
ana@lab:~/triage$ pl run prompts/v4-only-json.txt cases/dev.jsonl --out runs/v4.jsonl
40 calls, prompt 651820d7, llama3.2:3b, written to runs/v4.jsonl
ana@lab:~/triage$ pl check runs/v4.jsonl --failures
check      pass  fail
json         39     1
fields       39     1
labels       39     1
category     31     9
urgency      19    21
all          19    21

t02    urgency   high, expected normal
t04    urgency   low, expected high
t06    category  account, expected billing
t07    urgency   high, expected normal
t08    urgency   high, expected normal
t09    urgency   high, expected normal
t10    category  account, expected other
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
t39    urgency   low, expected normal
ana@lab:~/triage$ pl compare runs/v2.jsonl runs/v4.jsonl
runs/v2.jsonl            passes 21/40
runs/v4.jsonl            passes 19/40
fixed 0, broken 2
broken: t04 t10
sign test on the 2 that changed: p = 0.500
```

**A linha não mudou nada daquilo para que foi escrita**, e mudou duas outras coisas. O
`llama3.2:3b` nunca embrulhou uma resposta neste conjunto de teste, então não havia nada para ela
consertar, e a única resposta que não é JSON válido também não era antes. Ela mexeu em duas
urgências, `t04` e `t10`, as duas de aprovada para reprovada, e o teste do sinal sobre duas mudanças
é cara ou coroa, p = 0.500. Uma linha que conserta um problema que o modelo não tem custa quinze
tokens por chamada e dá ao modelo mais uma coisa para pesar.

Vale dizer isso porque a linha é um bom conselho para muitos modelos: alguns embrulham o JSON num
bloco de código por hábito. **Se o seu modelo tem o hábito é uma medição**, e aqui ela voltou não.

A resposta que não é JSON válido é a mesma com os dois prompts:

```
ana@lab:~/triage$ pl show runs/v2.jsonl t38
│ {"category": "returns", "urgency": "high", "summary": "Ebook won"}}
stop: stop, tokens in 103, out 22, 2.7 s
ana@lab:~/triage$ pl show runs/v4.jsonl t38
│ {"category": "returns", "urgency": "high", "summary": "Ebook won"}}
stop: stop, tokens in 118, out 22, 2.5 s
```

O resumo do `t38`, um cliente cujo ebook *won't* abrir, para em *won* e o objeto fecha duas vezes. O
modelo escreveu o apóstrofo de *won't* e se perdeu. Nenhuma instrução sobre embrulho alcança isso,
porque nada está embrulhado: **o próprio objeto está quebrado.**

## O interpretador tolerante

Existe um atalho óbvio para o embrulho. Um interpretador poderia procurar o objeto e ignorar o
resto. O `pl check --lenient` é esse interpretador, e ele são as quatro primeiras linhas de
`parse()`:

```
ana@lab:~/triage$ grep -n -A9 "^def parse" pl.py
119:def parse(text, lenient=False):
120-    if lenient:
121-        found = re.search(r"\{.*\}", text, re.S)
122-        text = found.group(0) if found else text
123-    try:
124-        obj = json.loads(text)
125-    except ValueError:
126-        return None
127-    return obj if isinstance(obj, dict) else None
128-
```

Ele pega tudo do primeiro `{` até o último `}` e interpreta isso. Aqui ele não muda nada, pelo mesmo
motivo pelo qual a linha a mais não mudou nada:

```
ana@lab:~/triage$ pl check runs/v2.jsonl --lenient
check      pass  fail
json         39     1
fields       39     1
labels       39     1
category     31     9
urgency      21    19
all          21    19
ana@lab:~/triage$ pl check runs/v4.jsonl --lenient
check      pass  fail
json         39     1
fields       39     1
labels       39     1
category     31     9
urgency      19    21
all          19    21
```

As contagens são as mesmas das rigorosas, porque o `t38` não é um objeto no meio de um texto; é um
objeto com um buraco. **O interpretador tolerante conserta embrulho, e um objeto quebrado não é
embrulho.**

Ele também aceita mais do que embrulho, e esse é o motivo para mantê-lo fora da medição. O padrão
não pergunta o que há em volta do objeto:

```
ana@lab:~/triage$ python3 -c 'from pl import parse; print(parse("Sure! {\"category\": \"billing\", \"urgency\": \"low\"} Hope that helps.", lenient=True))'
{'category': 'billing', 'urgency': 'low'}
ana@lab:~/triage$ python3 -c 'from pl import parse; print(parse("The customer pasted {\"category\": \"other\", \"urgency\": \"low\"} from an old ticket; this is billing.", lenient=True))'
{'category': 'other', 'urgency': 'low'}
```

O primeiro é uma resposta com conversa em volta de um objeto bom, que é para o que o interpretador
tolerante serve. O segundo é uma resposta que respondeu em prosa, *this is billing*, e por acaso cita
um objeto JSON que o cliente colou: o interpretador devolve `other`, o oposto do que a resposta
disse. **Um interpretador tolerante não distingue um hábito de uma resposta diferente.**

## Rigoroso na medição, deliberado no programa

Então meça com rigor, e conte o que falha. A contagem rigorosa é o número que diz se o prompt está
fazendo o seu trabalho, e é o número que se mexe quando um prompt ou um modelo muda.

Se o programa que consome as respostas precisa aceitar um bloco de código, porque o modelo que você
usa embrulha uma resposta em vinte e nada que você escreva impede isso, é uma decisão legítima.
Faça disso uma **etapa de reparo**: uma parte nomeada do programa consumidor que tira o bloco, roda
antes da interpretação rigorosa e conta quantas vezes dispara. Mantenha-a fora da verificação. Um
reparo dentro da medição quer dizer que a medição não consegue mais ver o que está sendo reparado,
e **uma contagem de reparos que sobe é o primeiro sinal de que algo antes mudou**.
