---
title: Conferindo relações quando ninguém sabe a resposta
version: 1
---

**Às vezes quem testa não consegue dizer qual é o resultado certo, mas consegue dizer como dois resultados precisam se
relacionar.** Ninguém talvez saiba quanto deveria custar um ingresso das 9:30; todo mundo sabe que um ingresso de
manhã não pode custar mais que um da tarde. Uma verificação construída sobre relações assim é um **oráculo parcial**:
não consegue confirmar que um resultado está certo, mas consegue provar que dois resultados não podem estar certos ao
mesmo tempo.

A ideia tem nome na pesquisa, **teste metamórfico**, de Tsong Yueh Chen e colegas em 1998, em que as relações se
chamam relações metamórficas. A ideia é mais velha que o nome, e é a coisa mais útil a saber sobre oráculos, porque
transforma *não dá para dizer* em *dá para dizer alguma coisa*.

## Relações na regra de preço

As cinco frases da Joana implicam relações que ninguém escreveu:

- **uma sessão mais cedo nunca custa mais que uma mais tarde no mesmo dia**, porque só há dois preços e o mais barato
  é antes das 17:00;
- **ser estudante nunca faz um ingresso custar mais**;
- **acrescentar um ingresso a um pedido nunca deixa o pedido mais barato**;
- **um preço nunca passa de R$ 36,00 e nunca fica abaixo de R$ 14,00**.

Cada uma dessas pode ser conferida em centenas de entradas sem ninguém calcular um único preço esperado.

## Uma verificação de relações, no laboratório

A Lia escreveu um programa curto que confere as duas primeiras relações numa série de horários, dias e idades, contra
a versão do `tickets.py` que passou em todos os testes de aceitação da aula 17. Salve-o em `~/aurora` como
`relations.py`:

```schooling-example
{"language": "python", "file": "relations.py", "parts": [{"code": "# relations.py\nfrom tickets import price\n\nTIMES = [\"9:30\", \"11:00\", \"15:00\", \"16:59\", \"17:00\", \"20:00\"]\n", "note": "A regra de preço da aula 17, e uma série de horários de sessão na ordem em que acontecem num dia, escritos do jeito que a programação os escreve."}, {"code": "\nfound = 0\nfor day in (\"thu\", \"wed\", \"sun\"):\n    for age in (35, 70):\n", "note": "Três dias, um deles quarta, e duas idades, uma delas acima da linha da idade: cada combinação passa pelas duas relações."}, {"code": "        prices = [price(age, False, day, t) for t in TIMES]\n        for i in range(len(TIMES) - 1):\n            if prices[i] > prices[i + 1]:\n                found += 1\n                print(f\"{day}, age {age}: {TIMES[i]} costs {prices[i]}, but the later {TIMES[i + 1]} costs {prices[i + 1]}\")\n", "note": "A primeira relação: andando pelo dia, um preço pode ficar igual ou subir, nunca descer. Nenhum preço está escrito em lugar nenhum; só a comparação entre vizinhos."}, {"code": "        for time in TIMES:\n            if price(age, True, day, time) > price(age, False, day, time):\n                found += 1\n                print(f\"{day}, age {age}, {time}: a student pays more than a non-student\")\n", "note": "A segunda relação: o mesmo cliente, estudante ou não, na mesma sessão. Ser estudante pode baixar o preço ou deixá-lo igual, nunca aumentar."}, {"code": "print(found, \"broken relations\")\n", "note": "A contagem no fim, para uma execução em que nada quebra ainda dizer o que conferiu."}]}
```

```
lia@lab:~/aurora$ python relations.py
thu, age 35: 9:30 costs 3600, but the later 11:00 costs 2800
thu, age 70: 9:30 costs 1800, but the later 11:00 costs 1400
wed, age 35: 9:30 costs 1800, but the later 11:00 costs 1400
wed, age 70: 9:30 costs 1800, but the later 11:00 costs 1400
sun, age 35: 9:30 costs 3600, but the later 11:00 costs 2800
sun, age 70: 9:30 costs 1800, but the later 11:00 costs 1400
6 broken relations
```

Seis relações quebradas, e todas são a sessão das 9:30: às 9:30 o programa cobra o preço da noite, e às 11:00 cobra o
da matinê. A verificação não sabe quanto deveria custar 9:30. Sabe que 9:30 não pode custar mais que 11:00 no mesmo
dia, e isso bastou para achar o defeito que as tabelas verdes da aula 17 eram honestas em não cobrir.

A relação do estudante não achou nada, e isso também importa: em 36 combinações, ser estudante nunca aumentou um
preço. Uma relação que se mantém é evidência, não prova, sobre as entradas em que foi tentada.

## De onde vêm as relações

Boas relações vêm de perguntar o que precisa ficar igual, ou andar num sentido só, quando uma entrada muda:

| mude a entrada | e o resultado precisa |
|---|---|
| passe a sessão para mais tarde no dia | não ficar mais caro |
| acrescente um motivo para meia | não ficar mais caro |
| acrescente um ingresso ao pedido | ficar mais caro, pelo preço desse ingresso |
| ordene a lista de sessões duas vezes | dar a mesma lista que ordenar uma vez |
| rode o mesmo pedido duas vezes | dar o mesmo total nas duas |

Cada linha é um teste que não precisa de valor esperado, e cada uma é uma pergunta a uma pessoa quando falha: a relação
pode estar errada, o que acontece, ou o programa pode estar. De qualquer jeito, alguém aprende algo que não sabia.
