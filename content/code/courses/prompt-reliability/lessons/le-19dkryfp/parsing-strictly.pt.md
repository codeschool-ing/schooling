---
title: Analisando com rigor
version: 1
---

A aula 1 encontrou treze respostas ao `v2-json.txt` com o conteúdo certo no embrulho errado: um
bloco de código em volta do objeto, ou uma frase na frente dele. A descrição dizia JSON e nunca
dizia o que pode vir em volta. O `v4-only-json.txt` diz, numa linha:

```
ana@lab:~/triage$ diff prompts/v2-json.txt prompts/v4-only-json.txt
7a8,9
> Reply with only the JSON object: no code fence and no other text.
> 
ana@lab:~/triage$ pl run prompts/v4-only-json.txt cases/dev.jsonl --out runs/v4.jsonl
40 calls, prompt 651820d7, written to runs/v4.jsonl
ana@lab:~/triage$ pl check runs/v4.jsonl --failures
check      pass  fail
json         37     3
fields       37     3
labels       37     3
category     37     3
urgency      34     6
all          34     6

t08    json      not JSON
t14    urgency   normal, expected low
t19    json      not JSON
t22    json      not JSON
t24    urgency   low, expected normal
t28    urgency   normal, expected low
ana@lab:~/triage$ pl compare runs/v2.jsonl runs/v4.jsonl
runs/v2.jsonl            passes 24/40
runs/v4.jsonl            passes 34/40
fixed 11, broken 1, still passing 23, still failing 5
broken: t19
sign test on the 12 that changed: p = 0.006
```

Trinta e sete de quarenta são analisáveis agora, contra vinte e sete, e o teste do sinal põe a
mudança em p = 0.006. **A linha tornou os hábitos mais raros, não os eliminou.** Três respostas
ainda voltaram embrulhadas. `t19` é uma delas, uma resposta que passava com o `v2-json.txt` e
quebrou com o prompt mais rigoroso:

```
ana@lab:~/triage$ pl show runs/v4.jsonl t19
│ ```json
│ {
│   "category": "account",
│   "urgency": "high",
│   "summary": "Someone else seems to have logged into their account and changed the delivery address."
│ }
│ ```
stop: end, tokens in 94, out 46
```

## O analisador tolerante

Existe um atalho óbvio. Quase todas as falhas são um objeto bom com alguma coisa em volta, então um
analisador poderia procurar o objeto e ignorar o resto. O `pl check --lenient` é esse analisador, e
ele é curto:

```
ana@lab:~/triage$ grep -n -A12 "^def parse" promptlab/cli.py
188:def parse(text, lenient=False):
189-    """The reply as a dict, or (None, why)."""
190-    t = text
191-    if lenient:
192-        m = re.search(r"\{.*\}", text, re.S)
193-        if m:
194-            t = m.group(0)
195-    try:
196-        obj = json.loads(t)
197-    except ValueError:
198-        return None, "not JSON"
199-    if not isinstance(obj, dict):
200-        return None, "not an object"
```

Ele pega tudo do primeiro `{` ao último `}` e analisa isso. Rodando nos dois prompts:

```
ana@lab:~/triage$ pl check runs/v2.jsonl --lenient
check      pass  fail
json         40     0
fields       40     0
labels       40     0
category     40     0
urgency      37     3
all          37     3
ana@lab:~/triage$ pl check runs/v4.jsonl --lenient
check      pass  fail
json         40     0
fields       40     0
labels       40     0
category     40     0
urgency      37     3
all          37     3
```

**Com o analisador tolerante, os dois prompts são o mesmo prompt**: quarenta de quarenta são
analisáveis nos dois, e trinta e sete passam em tudo nos dois. A melhora que a verificação rigorosa
mediu em p = 0.006 sumiu, porque o analisador tolerante mede o conteúdo e joga o embrulho fora antes
de contar. Se você só tivesse olhado números tolerantes, nunca teria escrito a linha do
`v4-only-json.txt`, e não saberia dizer se uma edição posterior a desfez.

Ele também aceita mais do que embrulho. O padrão não pergunta o que há em volta do objeto, então uma
resposta que pede desculpas por um parágrafo e põe um objeto no meio dele passa, e também passa uma
resposta que responde em prosa e por acaso cita um objeto JSON da mensagem do cliente. **Um
analisador tolerante não distingue um hábito de uma resposta diferente.**

## Rigor na medição, deliberação no programa

Então meça com rigor e conte o que falha. A contagem rigorosa é o número que diz se o prompt está
fazendo o trabalho dele, e é o número que se mexe quando um prompt ou um modelo muda.

Se o programa que consome as respostas precisa aceitar um bloco de código, porque o modelo que você
usa embrulha uma resposta em vinte e nada do que você escreve impede isso, essa é uma decisão
legítima. Faça dela uma **etapa de reparo**: uma parte nomeada do programa consumidor que tira o
bloco, roda antes da análise rigorosa e conta quantas vezes age. Mantenha-a fora da verificação. Um
reparo dentro da medição faz a medição deixar de ver justamente o que está sendo reparado, e **uma
contagem de reparos que sobe é o primeiro sinal de que algo mudou mais acima**.
