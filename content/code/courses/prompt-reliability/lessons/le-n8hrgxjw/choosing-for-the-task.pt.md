---
title: Escolher pela tarefa
version: 2
---

A triagem tem uma resposta certa por mensagem. A mesma mensagem deve receber a mesma categoria toda
vez, porque uma pessoa ou um programa age a partir dela. **Numa tarefa com uma resposta certa, o
sorteio só consegue mexer nas respostas, e ele mexe nos casos apertados.** Este é o
`v6-escaped.txt`, o prompt da aula 4, rodado cinco vezes sobre as quarenta mensagens, primeiro com
temperatura 0:

```
ana@lab:~/triage$ pl run prompts/v6-escaped.txt cases/dev.jsonl --samples 5 --out runs/t0.jsonl
200 calls, prompt fbc4c9b1, llama3.2:3b, written to runs/t0.jsonl
ana@lab:~/triage$ pl check runs/t0.jsonl
check      pass  fail
json        195     5
fields      195     5
labels      195     5
category    150    50
urgency     100   100
all         100   100
```

`--samples 5` chama o modelo cinco vezes por mensagem, cada uma com uma semente diferente: 200
chamadas. Com temperatura 0 a semente não tem o que escolher, então as cinco chamadas são idênticas e
toda contagem é cinco vezes a de uma execução só: 30 categorias certas viram 150. Agora a mesma coisa
com temperatura 1:

```
ana@lab:~/triage$ pl run prompts/v6-escaped.txt cases/dev.jsonl --samples 5 --set temperature=1 --out runs/t1.jsonl
200 calls, prompt fbc4c9b1, llama3.2:3b, written to runs/t1.jsonl
ana@lab:~/triage$ pl check runs/t1.jsonl
check      pass  fail
json        198     2
fields      198     2
labels      198     2
category    152    48
urgency      85   115
all          85   115
ana@lab:~/triage$ pl check runs/t1.jsonl --failures | grep -e '^t22' -e '^t01'
t01    category  returns, expected billing
t01#1  category  returns, expected billing
t01#2  category  returns, expected billing
t01#3  category  returns, expected billing
t01#4  category  returns, expected billing
t22    category  other, expected billing
t22#1  category  other, expected billing
t22#2  category  other, expected billing
t22#3  category  other, expected billing
t22#4  category  other, expected billing
```

As categorias não sofreram: 152 certas contra 150, e três respostas a mais viraram JSON válido.
**A urgência caiu de 100 para 85.** Para este modelo, com este prompt, a categoria é quase sempre uma
escolha segura e a urgência é o caso apertado, e o sorteio achou os casos apertados. O `t01` e o
`t22`, errados com temperatura 0, também estão errados nas cinco amostras com temperatura 1. A
primeira seção desta aula mediu o `t22` com 62,1% para `other` e 22,5% para `billing`, então cinco
sorteios sem nenhum billing não são surpresa, e **o sorteio não salva uma resposta de que o modelo
está razoavelmente seguro**. Ele só gasta as margens.

Uma temperatura baixa não é o mesmo que zero:

```
ana@lab:~/triage$ pl run prompts/v6-escaped.txt cases/dev.jsonl --samples 5 --set temperature=0.2 --out runs/t02.jsonl
200 calls, prompt fbc4c9b1, llama3.2:3b, written to runs/t02.jsonl
ana@lab:~/triage$ pl check runs/t02.jsonl
check      pass  fail
json        195     5
fields      195     5
labels      195     5
category    149    51
urgency      96   104
all          96   104
```

A 0,2 a categoria perdeu 1 de 150 e a urgência 4 de 100. Uma mensagem cujas duas primeiras
candidatas estão quase empatadas continua virando com quase qualquer temperatura acima de zero,
porque uma temperatura pequena estica uma distância pequena até uma distância que continua pequena.

## Quando a variedade é o objetivo

O outro tipo de tarefa quer uma resposta diferente a cada vez: cinco linhas de assunto para escolher,
uma resposta a um cliente que não deve soar como as últimas cinquenta, uma lista de ideias. O
`reply.txt` da aula 4 escreve respostas. Aqui ele roda três vezes para cada mensagem de
`cases/three.jsonl`, também da aula 4, com temperatura 0, e uma linha de Python conta quantos textos
diferentes voltaram:

```
ana@lab:~/triage$ pl run prompts/reply.txt cases/three.jsonl --samples 3 --out runs/same.jsonl --var shop=Folio --var language=English
9 calls, prompt 13304d8d, llama3.2:3b, written to runs/same.jsonl
ana@lab:~/triage$ python3 -c 'import json, sys; rows = [json.loads(l) for l in open(sys.argv[1])]; print(len(rows), "replies,", len({r["text"] for r in rows}), "different")' runs/same.jsonl
9 replies, 6 different
```

Nove respostas e seis textos diferentes, com temperatura 0. Guarde isso; a última seção desta aula
volta a esse ponto. Um prompt que quer variedade pode levar a própria temperatura, no cabeçalho que o
`pl` lê acima de uma linha `---`. Salve isto como `prompts/reply-varied.txt`:

```
temperature: 0.8
---
You write replies for {{shop}}, an online bookshop. Write in {{language}}.

Reply to the customer below in at most 80 words. Say what happens next and
when. Do not promise a refund or a date the shop has not agreed.

<message>
{{message|xml}}
</message>
```

É o `reply.txt` com duas linhas em cima. As mesmas nove chamadas:

```
ana@lab:~/triage$ pl run prompts/reply-varied.txt cases/three.jsonl --samples 3 --out runs/varied.jsonl --var shop=Folio --var language=English
9 calls, prompt c92bce25, llama3.2:3b, written to runs/varied.jsonl
ana@lab:~/triage$ python3 -c 'import json, sys; rows = [json.loads(l) for l in open(sys.argv[1])]; print(len(rows), "replies,", len({r["text"] for r in rows}), "different")' runs/varied.jsonl
9 replies, 9 different
ana@lab:~/triage$ pl show runs/varied.jsonl t01
│ Dear customer,
│
│ Thank you for reaching out to us about the issue with your order 4471. We are investigating this matter immediately. Our team will review the transaction and take necessary actions to rectify the situation. You can expect a further update on this issue by the end of the business day tomorrow. Please contact us again if you have any additional concerns.
│
│ Best regards,
│ Folio Customer Service
stop: stop, tokens in 96, out 80, 9.3 s
ana@lab:~/triage$ pl show runs/varied.jsonl t01 --sample 1
│ "Thank you for reaching out to us about the double charge for your order 4471. Our team is investigating this issue and will contact you as soon as possible to resolve the problem. You will receive an email with the next steps to rectify the situation. We apologize for the inconvenience caused and appreciate your patience."
stop: stop, tokens in 96, out 65, 7.3 s
```

As nove são diferentes, e diferem desde a primeira linha: uma é uma carta com saudação e assinatura,
a outra um parágrafo só, entre aspas. Se alguma delas é uma boa resposta é outra questão, e a aula 12
mede o tom. O que o cabeçalho fez foi fazer cada chamada valer o que custa.

**Decida por tarefa, e mantenha classificação e extração em 0.** Pôr a temperatura no arquivo do
prompt deixa a decisão ao lado do texto para o qual ela foi tomada, e assim o prompt de triagem e o
de resposta podem morar no mesmo diretório sem ninguém precisar lembrar qual pede o quê.

A aula 19 sorteia de propósito, várias vezes por mensagem, e faz uma votação. Assim a aleatoriedade
trabalha a seu favor, e cada amostra custa uma chamada.

## Zero não é garantia

A temperatura 0 deixou idênticas as cinco amostras da triagem acima. Não fez o mesmo com as
respostas: nove respostas, seis textos diferentes. Estas são as três do `t01`:

```
ana@lab:~/triage$ pl show runs/same.jsonl t01
│ "Dear customer,
│
│ We apologize for the inconvenience and are investigating the issue with your order 4471. We will process a refund for the second payment as soon as possible. You can expect to receive an update on the status of your refund within the next 3-5 working days. If you have any further concerns, please don't hesitate to contact us.
│
│ Best regards, Folio Customer Service"
stop: stop, tokens in 96, out 82, 10.9 s
ana@lab:~/triage$ pl show runs/same.jsonl t01 --sample 1
│ "Dear customer,
│
│ We apologize for the inconvenience and are investigating the issue with your order 4471. We will process a refund for the second payment as soon as possible. You will receive an email with the refund details once the process is complete. We appreciate your patience and understanding in this matter.
│
│ Best regards, Folio Customer Service"
stop: stop, tokens in 96, out 69, 7.9 s
ana@lab:~/triage$ pl show runs/same.jsonl t01 --sample 2
│ "Dear customer,
│
│ We apologize for the inconvenience and are investigating the issue with your order 4471. We will process a refund for the second payment as soon as possible. You will receive an email with the refund details once the process is complete. We appreciate your patience and understanding in this matter.
│
│ Best regards, Folio Customer Service"
stop: stop, tokens in 96, out 69, 8.3 s
```

As amostras 1 e 2 concordam. A amostra 0 concorda com elas por trinta palavras e então escreve *You
can expect* onde elas escrevem *You will receive*, e dali em diante é outra resposta. A semente não
pode ser o motivo, porque as amostras 1 e 2 tiveram sementes diferentes e concordam. O mesmo
aconteceu no `t02` e no `t03`: em cada um, a amostra 0 difere e as amostras 1 e 2 concordam. A causa
mais provável é o cache do Ollama. A primeira chamada de cada mensagem calculou a mensagem inteira; as
duas seguintes encontraram a maior parte já calculada e a reaproveitaram. A aritmética seguiu outro
caminho, os últimos dígitos de duas pontuações quase iguais saíram invertidos, e a decodificação
gulosa seguiu a nova vencedora até o fim da resposta. Um objeto JSON curto dá a um quase empate
menos lugares para acontecer do que sessenta palavras de prosa, e é por isso que as amostras da
triagem concordaram. As três respostas também prometem um reembolso, o que o prompt proíbe; a aula 4
achou o mesmo, e a temperatura não tem nada a ver com isso.

Máquinas diferentes acrescentam uma segunda causa. A aula 1 rodou o `v2-json.txt` e imprimiu 22
aprovações; as aulas 2 e 3 rodaram o mesmo arquivo sobre as mesmas quarenta mensagens, com o mesmo
modelo e a mesma configuração, e imprimiram 21. Aqui está ele mais uma vez, na máquina que capturou
esta seção:

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
```

Vinte e duas, e as dezoito falhas são as que a aula 1 listou, mensagem por mensagem. Então duas
máquinas concordam, e na máquina que capturou as aulas 2 e 3 uma resposta a mais falhou. O prompt, o
modelo, a semente e a temperatura eram os mesmos em todas.

**Temperatura 0 quer dizer a primeira candidata toda vez, e a primeira candidata é calculada.** As
pontuações saem de milhões de somas de ponto flutuante, e um cache, um processador diferente, outra
versão do Ollama ou outro número de threads fazem essas somas em outra ordem. Quando duas candidatas
estão quase empatadas, uma diferença nos últimos dígitos basta para trocá-las. Modelos hospedados
acrescentam mais uma causa: a sua requisição é agrupada com as de outras pessoas, e o grupo muda a
aritmética. A documentação da Anthropic para `temperature` diz que mesmo em 0.0 os resultados não
serão totalmente determinísticos.

É mais um motivo para medir num conjunto de teste e comparar mensagem a mensagem, em vez de confiar
numa execução de uma mensagem, e para **rodar a linha de base de novo na máquina onde você testa a
mudança**. Uma comparação entre uma execução do mês passado e uma de hoje mede a máquina tanto quanto
o prompt.
