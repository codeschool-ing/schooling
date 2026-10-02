---
title: Como um juiz funciona
version: 1
---

A aula 12 terminou onde as regras acabam: se uma resposta responde à pergunta, se soa como alguém
que se importa. O passo óbvio seguinte é perguntar a um modelo. **Um juiz é um prompt como qualquer
outro, e o veredito dele é uma resposta como qualquer outra**, com formato, taxa de erro e hábitos. O
erro comum é tratá-lo como um leitor neutro, de fora do sistema, quando ele é mais uma parte do
sistema que precisa ser medida.

## O prompt

O `prompts/judge.txt` mostra a mensagem de um cliente e duas respostas, e pergunta qual é melhor:

```
ana@lab:~/triage$ cat prompts/judge.txt
You compare two replies to a customer of Folio, an online bookshop.

<message>
{{message}}
</message>

<reply_a>
{{reply_a}}
</reply_a>

<reply_b>
{{reply_b}}
</reply_b>

Which reply answers the customer better? Answer A or B and nothing else.
```

Ele pede uma comparação em vez de uma nota de zero a dez. Uma comparação tem uma pergunta só, *qual
destas duas*, enquanto uma nota ainda precisa de um sentido combinado para o 7. Ela também precisa
de pares, e o `cases/pairs.jsonl` guarda dezesseis, escritos pelo curso, cada um com o veredito que
uma pessoa deu:

```
ana@lab:~/triage$ head -n 1 cases/pairs.jsonl
{"id": "j01", "message": "I was charged twice for order 4471.", "a": "Thank you for contacting Folio. We take billing very seriously and our team is committed to resolving every issue our customers raise. Please be assured that your message has been passed to the relevant department, who will review your account and be in touch in due course.", "b": "Sorry about that. I can see two payments for order 4471 and I've refunded the second one; it will reach your card in 3 to 5 working days.", "human": "b"}
```

Em `j01` a pessoa escolheu `b`: ela diz o que aconteceu e o que foi feito. `a` é um parágrafo de
tranquilização em que nada acontece.

## O que o juiz do substituto faz

O substituto reconhece o prompt do juiz pelas tags e pontua cada resposta com uma rubrica curta: um
ponto por um pedido de desculpas ou um agradecimento, um ponto por dizer o que será feito, um ponto
por citar o que está em jogo, como o pedido ou o reembolso, e uma penalidade por pontos de
exclamação. **Depois ele soma duas coisas que a rubrica nunca pediu**, e as declara:

```
ana@lab:~/triage$ grep -nE "^(FIRST_SEAT|PER_CHARACTER)" promptlab/standin.py
442:FIRST_SEAT = 0.6        # what being shown first is worth to a reply
443:PER_CHARACTER = 0.006   # what each character of length is worth
```

A resposta mostrada primeiro ganha 0,6 a mais, e cada caractere de comprimento soma 0,006, então uma
resposta cem caracteres mais longa ganha o mesmo que uma mostrada primeiro. Esses dois números são
escolha do curso, postos ali para que as duas próximas seções tenham o que encontrar. Se um juiz real
tem vieses parecidos, e de que tamanho, é uma pergunta que se responde do mesmo jeito: medindo contra
uma pessoa.
