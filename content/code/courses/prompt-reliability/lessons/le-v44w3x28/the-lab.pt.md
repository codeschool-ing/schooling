---
title: O laboratório, e o que nele é real
version: 1
---

Um prompt que funcionou quando você testou foi testado uma vez. **Este curso trata de testá-lo as
outras trinta e nove**: escrever o que é uma boa resposta, rodar o prompt em mensagens que ele
nunca viu e contar. Tudo o que vem depois desta seção é um jeito de deixar essa contagem mais
honesta, mais barata ou mais difícil de enganar.

O curso inteiro acompanha um prompt. A Folio é uma livraria online, inventada para o curso, e a
caixa de atendimento dela precisa de cada mensagem classificada antes que uma pessoa a leia: uma
**categoria** (billing, delivery, returns, account ou other), uma **urgência** (low, normal ou high)
e um **resumo** de uma frase. A resposta é JSON, porque quem a lê em seguida é um programa.

## A bancada

O laboratório é um diretório, `~/triage`, montado pelo `lab.sh` que fica ao lado do `course.json`
deste curso. Ele precisa de Python e git, e de mais nada:

```
ana@lab:~/triage$ ls
bin
cases
checks
prices.json
promptlab
prompts
runs
ana@lab:~/triage$ head -n 2 cases/dev.jsonl
{"id": "t01", "message": "I was charged twice for order 4471. Please refund the second payment.", "expect": {"category": "billing", "urgency": "high"}}
{"id": "t02", "message": "My parcel was meant to arrive on Monday and the tracking hasn't moved since Friday.", "expect": {"category": "delivery", "urgency": "normal"}}
ana@lab:~/triage$ wc -l cases/dev.jsonl
40 cases/dev.jsonl
```

`cases/dev.jsonl` é o **conjunto de teste**: quarenta mensagens, uma por linha, cada uma com a
resposta que uma pessoa decidiu ser a certa. `prompts/` guarda os prompts. `pl` é o comando que
junta os dois, e três subcomandos dele fazem quase todo o trabalho neste curso:

| comando | o que faz |
|---|---|
| `pl run PROMPT CASES --out RUN` | preenche o prompt com cada mensagem, chama o modelo e grava cada resposta num arquivo |
| `pl check RUN` | submete cada resposta a cinco verificações e conta as aprovações |
| `pl show RUN ID` | mostra uma resposta exatamente como o modelo a escreveu |

As verificações rodam em ordem, e uma resposta que falha numa falha em todas as seguintes: `json`
(ela é analisável), `fields` (tem os campos, e nenhum outro), `labels` (os valores vêm das
listas), `category` e `urgency` (batem com a resposta da pessoa). `all` conta as respostas que
passaram em tudo.

## O modelo é um substituto

**O modelo deste laboratório não é um modelo de linguagem.** É o `promptlab/standin.py`, umas
quatrocentas linhas de Python escritas para o curso, e o comentário de abertura dele lista cada
regra pela qual responde: classifica uma mensagem por palavras-chave, pende para os rótulos que os
exemplos mostram, escreve no formato do primeiro exemplo e tem alguns hábitos de formatação com
taxas fixas.

Ele está ali por três motivos. Não precisa de chave de API e não custa nada. Responde do mesmo jeito
toda vez, então os números destas aulas são os números que você obtém ao rodá-las. E as falhas dele
foram colocadas de propósito, para que a bancada sempre tenha algo a encontrar.

O que isso significa para o que você lê: **todo número numa transcrição foi calculado pela bancada,
e toda resposta foi escrita pelo substituto.** Os números são aritmética real sobre um comportamento
inventado. Quando uma aula diz algo sobre modelos reais, diz na prosa, e diz de onde vem a
afirmação. A bancada não distingue um do outro; `promptlab/model.py` é a única função que chama um
modelo, e apontá-la para um modelo real não muda mais nada.

::: track ai
Você escreveu Python em `python`, então leia o `promptlab/cli.py` quando um número surpreender: cada
verificação tem poucas linhas, e saber exatamente o que ela conta é metade de confiar nela.
:::

::: track *
Você não precisa ler o código da bancada para usá-la. Cada aula diz o que um comando conta, e isso
basta para discutir com o número.
:::

## Onde este curso começa

`prompt-engineering` apresentou as técnicas: exemplos few-shot nas aulas 20 e 21, temperatura na
aula 13, injeção na aula 7. **Este curso retoma várias delas de propósito**, com outra pergunta. Lá a
pergunta era o que é uma técnica. Aqui é se ela ainda funciona na quadragésima mensagem, e como você
saberia se ela parasse de funcionar.
