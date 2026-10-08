---
title: Escolhendo o limite a partir de uma medição
version: 2
---

Um limite pega uma resposta descontrolada, e só faz esse trabalho se as respostas comuns nunca o
alcançarem. Então **o ponto de partida é a resposta comum mais longa, medida**:

```
ana@lab:~/triage$ pl run prompts/v4-only-json.txt cases/all.jsonl --out runs/v4-all.jsonl
70 calls, prompt 651820d7, llama3.2:3b, written to runs/v4-all.jsonl
ana@lab:~/triage$ python3 stats.py runs/v4-all.jsonl
runs/v4-all.jsonl, 70 calls
  tokens in    mean  121.3   total   8491
  tokens out   mean   29.1   total   2038   max 38
  seconds      p50   3.4   p95   4.4   total  243.2
```

Nas setenta mensagens, o conjunto de desenvolvimento e o guardado juntos, a resposta mais longa
teve 38 tokens e a média 29,1. Um limite de 38 deixaria passar todas elas hoje. **Um limite
exatamente no máximo medido não tem folga**, e o prompt não vai ficar do mesmo jeito.

## O prompt ganha um campo

A aula 21 pergunta ao modelo o quanto ele tem certeza, num quarto campo. Salve o prompt dela como
`prompts/v9-confidence.txt`:

```
You sort customer messages for Folio, an online bookshop.

Read the message and answer in JSON with four fields:
- "category": one of billing, delivery, returns, account, other
- "urgency": one of low, normal, high
- "summary": one sentence saying what the customer needs
- "confidence": how sure you are of the category, from 0 to 1

<example>
Message: I paid for express delivery but the order came by normal post.
Output: {"category": "billing", "urgency": "normal", "summary": "Wants the express delivery charge back.", "confidence": 0.9}
</example>

<example>
Message: The book came with water damage on every page.
Output: {"category": "returns", "urgency": "normal", "summary": "Wants a replacement for a damaged book.", "confidence": 0.95}
</example>

<example>
Message: Can I change the name on my account?
Output: {"category": "account", "urgency": "low", "summary": "Asks how to change the account name.", "confidence": 0.85}
</example>

Message: {{message}}
```

Um quarto campo é uma mudança no contrato além de no prompt: a `judge()` do `pl.py` recusa qualquer
chave que não conheça, então reprovaria toda resposta destas em `fields`. A aula 3 disse que a
verificação são as necessidades do leitor por escrito, e o leitor agora precisa de mais uma chave.
Permita-a com uma edição, da qual todas as aulas seguintes dependem:

```sh
sed -i 's/and k != "summary"/and k not in ("summary", "confidence")/' pl.py
```

Agora rode o prompt novo com o máximo antigo como limite, 38:

```
ana@lab:~/triage$ pl run prompts/v9-confidence.txt cases/dev.jsonl --set num_predict=38 --out runs/v9-38.jsonl
40 calls, prompt c31bed19, llama3.2:3b, written to runs/v9-38.jsonl
ana@lab:~/triage$ pl check runs/v9-38.jsonl --failures
check      pass  fail
json         33     7
fields       33     7
labels       33     7
category     28    12
urgency      19    21
all          19    21

t01    json      cut off at num_predict
t02    urgency   high, expected normal
t03    json      cut off at num_predict
t06    json      cut off at num_predict
t07    urgency   high, expected normal
t09    urgency   high, expected normal
t11    json      cut off at num_predict
t17    json      cut off at num_predict
t19    json      cut off at num_predict
t21    json      cut off at num_predict
t22    category  other, expected billing
t23    urgency   normal, expected high
t24    urgency   high, expected normal
t25    category  other, expected account
t26    category  account, expected billing
t28    urgency   high, expected low
t32    urgency   high, expected normal
t33    category  delivery, expected returns
t36    urgency   normal, expected high
t37    category  billing, expected delivery
t39    urgency   low, expected normal
```

**Sete respostas são cortadas**, cada uma delas uma resposta que teria passado. O campo a mais
deixou as respostas mais longas, e ninguém que acrescenta um campo pensa em conferir o limite. Aqui
está o mesmo prompt com o limite no dobro do máximo antigo:

```
ana@lab:~/triage$ pl run prompts/v9-confidence.txt cases/dev.jsonl --set num_predict=76 --out runs/v9-76.jsonl
40 calls, prompt c31bed19, llama3.2:3b, written to runs/v9-76.jsonl
ana@lab:~/triage$ pl check runs/v9-76.jsonl
check      pass  fail
json         40     0
fields       40     0
labels       40     0
category     35     5
urgency      26    14
all          26    14
ana@lab:~/triage$ python3 stats.py runs/v9-76.jsonl
runs/v9-76.jsonl, 40 calls
  tokens in    mean  288.1   total  11526
  tokens out   mean   36.6   total   1463   max 43
  seconds      p50   4.3   p95   4.9   total  172.9
ana@lab:~/triage$ pl compare runs/v9-38.jsonl runs/v9-76.jsonl
runs/v9-38.jsonl         passes 19/40
runs/v9-76.jsonl         passes 26/40
fixed 7, broken 0
sign test on the 7 that changed: p = 0.016
```

Com um limite de 76 nada é cortado, a resposta mais longa agora tem 43 tokens, e as sete voltam:
fixed 7, broken 0. Um campo a mais levou o máximo de 38 para 43, e um limite sem nenhuma folga
transformou sete respostas certas em sete exceções.

O dobro do máximo medido, aqui 76, é um hábito deste curso e não uma lei. Não custa nada numa
resposta que para antes dele, porque um modelo escreve, e um provedor cobra, os tokens da resposta e
não o limite. A regra por baixo do hábito: o limite fica tão acima de toda resposta que você mediu
que **só uma resposta que deu errado consegue alcançá-lo**, e você mede de novo sempre que o prompt
muda.

## Uma resposta cortada é uma falha

Uma resposta cortada depois do último campo está a uma chave de fechamento de ser JSON válido. Um
leitor que conserta respostas, acrescentando a chave que falta e interpretando o resultado, a
aceitaria, e nessa mensagem ainda teria a resposta inteira. Numa resposta cortada depois de
`"confidence":`, o mesmo conserto não tem valor nenhum para fechar. Numa resposta cortada dentro do
resumo, como o `t01` com o limite de 25, ele aceitaria uma frase sem o fim, e nada adiante saberia.

`prompt-engineering` consertou saída inválida na aula 19. Uma resposta cortada é o único caso em que
consertar é a ferramenta errada. **Toda resposta que parou no limite é uma falha, seja o que sobrou
dela JSON válido ou não.** O leitor olha o motivo da parada antes de interpretar qualquer coisa,
registra a resposta e a trata como o harness trata: como uma resposta que não chegou. Contar essas
paradas também é como você descobre que um limite foi parar no tráfego comum, muito antes de alguém
ler um resumo truncado.
