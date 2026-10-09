---
title: Por que delimitar
version: 2
---

Um prompt chega ao modelo como um fluxo único de texto. **As suas instruções e as palavras do
cliente são o mesmo tipo de caractere**, e nada além do próprio texto diz onde uma coisa para e a
outra começa. Um delimitador é uma marca que você põe em volta das palavras do cliente para que a
fronteira fique escrita em vez de adivinhada.

A maioria das mensagens não dá trabalho nenhum à fronteira. As que a testam são mensagens com
estrutura própria: clientes colam uma página de erro, uma linha do extrato do banco, um bilhete do
entregador, e isso chega com crases, quebras de linha e tags dentro. Aqui estão seis, rotuladas como
alguém da equipe de suporte as rotularia. Salve-as como `cases/pasted.jsonl`:

```
{"id": "p01", "message": "The ebook I bought won't download. The page shows ```Error 403: link expired``` instead.", "expect": {"category": "returns", "urgency": "normal"}}
{"id": "p02", "message": "My bank statement shows ```FOLIO BOOKS LTD  £15.00``` but I paid £12 at checkout.", "expect": {"category": "billing", "urgency": "normal"}}
{"id": "p03", "message": "The emails you send to my account show <b>Order 5512</b> as raw tags.", "expect": {"category": "account", "urgency": "low"}}
{"id": "p04", "message": "The courier left this note:\n```\nAttempted delivery 14:02\nNo safe place\n```\nWhen will they try again?", "expect": {"category": "delivery", "urgency": "normal"}}
{"id": "p05", "message": "My review won't post. It says </message> is not allowed, but I never typed that.", "expect": {"category": "other", "urgency": "normal"}}
{"id": "p06", "message": "Tracking shows ``` and then nothing. Is my parcel lost?", "expect": {"category": "delivery", "urgency": "normal"}}
```

O `v4-only-json.txt`, o prompt da aula 3, não tem delimitador. A última linha dele é a mensagem:

```
ana@lab:~/triage$ tail -n 3 prompts/v4-only-json.txt
Reply with only the JSON object: no code fence and no other text.

Message: {{message}}
ana@lab:~/triage$ pl render prompts/v4-only-json.txt --cases cases/pasted.jsonl --case p04 | tail -n 7 | cat -n
     1	
     2	Message: The courier left this note:
     3	```
     4	Attempted delivery 14:02
     5	No safe place
     6	```
     7	When will they try again?
```

O `pl render` preenche o template com um caso e imprime o prompt exatamente como o modelo o
receberia; o `cat -n` numera as linhas, por um motivo que a próxima seção explica. A mensagem começa
depois de `Message:` e vai até o fim do prompt. Isso se sustenta enquanto as palavras do cliente
forem a última coisa do prompt e não tiverem nada que pareça estrutura, e o `p04` já traz um bloco
próprio, cercado por crases. Rode as seis:

```
ana@lab:~/triage$ pl run prompts/v4-only-json.txt cases/pasted.jsonl --out runs/pasted-v4.jsonl
6 calls, prompt 651820d7, llama3.2:3b, written to runs/pasted-v4.jsonl
ana@lab:~/triage$ pl check runs/pasted-v4.jsonl --failures
check      pass  fail
json          6     0
fields        6     0
labels        6     0
category      2     4
urgency       0     6
all           0     6

p01    category  delivery, expected returns
p02    category  returns, expected billing
p03    category  delivery, expected account
p04    urgency   low, expected normal
p05    category  returns, expected other
p06    urgency   high, expected normal
ana@lab:~/triage$ pl show runs/pasted-v4.jsonl p01
│ {"category": "delivery", "urgency": "high", "summary": "Ebook download failed due to expired link"}
stop: stop, tokens in 128, out 27, 38.6 s
ana@lab:~/triage$ pl show runs/pasted-v4.jsonl p04
│ {"category": "delivery", "urgency": "low", "summary": "Customer wants to know when the courier will try again after leaving a note indicating no safe place for delivery."}
stop: stop, tokens in 135, out 40, 5.1 s
```

**Nenhuma resposta passa.** Quatro têm a categoria errada e as outras duas a urgência errada. O
`p01`, um ebook que não baixa, está rotulado `returns`, como o ebook da aula 1 que não abria, e o
modelo o chamou de `delivery`. Os resumos mostram que o modelo leu as mensagens: o resumo do `p04`
tem o bilhete do entregador, que é a parte que uma fronteira traçada no lugar errado teria perdido.
Então nada aqui deu errado *porque* o prompt não marca nada. O modelo adivinhou a fronteira, e com a
mensagem no fim do prompt o palpite era fácil.

Esse é o motivo para delimitar mesmo assim. **Um prompt que não marca nada deixa a fronteira para
um palpite**, e o palpite fica mais difícil assim que qualquer coisa vem depois da mensagem: um
segundo dado, uma instrução repetida no fim, um exemplo. As duas próximas seções marcam a mensagem de
dois jeitos e rodam as mesmas seis, e as contagens a comparar são estas: 2 categorias certas em 6,
nenhuma resposta aprovada.
