---
title: JSON, o formato que um programa quer
version: 1
---

É tentador pensar que um modelo que escreve boa prosa vai escrever bons dados se você pedir. Ele
escreve texto com cara de dados, e **parecer JSON e ser JSON são julgados por leitores
diferentes**. Uma pessoa passa por cima de uma frase sobrando. Um parser para no primeiro caractere
que não esperava, e o programa que o chamou fica sem nada.

Então a pergunta desta seção é estreita: quando uma resposta se destina a um programa, do que o
programa precisa, e como você descobre se ele recebeu isso?

## Por que um programa quer JSON

Suponha que o Café Aurora queira classificar cada avaliação: foi positiva ou negativa, falava de
quê, elogiou a equipe. Uma pessoa poderia ler um parágrafo dizendo isso. Um programa que arquiva a
avaliação, conta as reclamações da semana ou avisa o gerente precisa dos mesmos fatos **em lugares
fixos, com nomes fixos e tipos fixos**:

- um nome de campo que o código consiga pedir, `sentiment`, escrito do mesmo jeito toda vez;
- um valor de uma lista curta, `negative` e não `bem negativa, na verdade`;
- um número como número, uma lista como lista, `true` como booleano e não a palavra `sim`.

O JSON dá as três coisas, toda linguagem de programação o lê, e o leitor é rigoroso. Essa última
parte é o que o torna útil: **um leitor rigoroso avisa que a resposta está quebrada no momento em
que ela chega**, e não três passos depois, quando um relatório sai errado.

## Pedindo no prompt

O prompt diz como é o objeto, campo por campo, e diz que nada mais pode vir junto. O curso escreveu
este prompt como ilustração; nenhum modelo foi chamado:

```localised
Classifique a avaliação do café que está entre as tags <review>.

Responda com um único objeto JSON e mais nada: nenhuma frase antes
ou depois dele, e nenhum bloco de código. Use exatamente estes campos:
  "review"         o número da avaliação, como número
  "sentiment"      um de "positive", "negative", "mixed"
  "topics"         uma lista de palavras curtas em minúsculas
  "staff_praised"  true ou false

<review number="3">
Waited fifteen minutes for a tea at noon. The staff were kind about it.
</review>
```

Três coisas nele fazem o trabalho. Os campos têm nomes exatos, então o modelo não tem motivo para
chamar um deles de `mood` na terça-feira. Os valores que vêm de uma lista estão listados. E **o
prompt nomeia os dois embrulhos que os modelos mais acrescentam**, uma frase de apresentação e um
bloco de código em Markdown, porque "só JSON" sozinho não os exclui aos olhos do modelo.

A lição 19 troca a lista de campos por um **schema** formal, um documento contra o qual um programa
consegue conferir a resposta. Aqui a descrição está em prosa, e a conferência é só se a resposta é
lida pelo parser.

## Três respostas, e o que um parser diz a cada uma

Estas são três respostas do tipo que os modelos devolvem, escritas pelo curso em arquivos na
bancada. A
primeira é o que foi pedido:

```
ana@lab:~/pe$ cat replies/good.json
{
  "review": 3,
  "sentiment": "negative",
  "topics": ["wait", "tea"],
  "staff_praised": true
}
ana@lab:~/pe$ python3 -m json.tool replies/good.json > /dev/null; echo "exit $?"
exit 0
```

`python3 -m json.tool` é o leitor de JSON do próprio Python, rodado pela linha de comando. Ele lê o
arquivo e o imprime de volta arrumado; aqui a impressão é descartada e só o **código de saída** fica,
porque é isso que um programa confere. `0` quer dizer que foi lido.

A segunda resposta tem o objeto certo dentro e uma frase simpática na frente:

```
ana@lab:~/pe$ cat replies/chatty.json
Sure! Here is the JSON for review 3:
{
  "review": 3,
  "sentiment": "negative",
  "topics": ["wait", "tea"],
  "staff_praised": true
}
ana@lab:~/pe$ python3 -m json.tool replies/chatty.json > /dev/null; echo "exit $?"
Expecting value: line 1 column 1 (char 0)
exit 1
```

**O parser desistiu logo no primeiro caractere.** Um JSON precisa começar com um valor, e `S` não é
um. Uma pessoa vê um objeto perfeitamente bom; o programa vê uma falha, e nunca fica sabendo que o
objeto estava ali. A lição 19 recupera esta resposta com um pequeno passo de reparo.

A terceira não tem frase nenhuma, e cada linha dela tem cara de dado:

```
ana@lab:~/pe$ cat replies/python.json
{
  'review': 3,
  'sentiment': 'negative',
  'topics': ['wait', 'tea'],
  'staff_praised': True,
}
ana@lab:~/pe$ python3 -m json.tool replies/python.json > /dev/null; echo "exit $?"
Expecting property name enclosed in double quotes: line 2 column 3 (char 4)
exit 1
```

Esse é o jeito do Python de escrever um dicionário, e ele é parecido o bastante com JSON para
enganar o olho. O JSON exige aspas duplas, escreve o booleano `true` em minúsculas e recusa a
vírgula depois do último campo. O erro aponta só o primeiro problema, na linha 2, coluna 3, o `'`
de abertura. **Um parser informa onde parou, não tudo o que está errado**, então consertar as
aspas à mão só empurraria o erro para o `True`.

## O que levar das três

O código de saída é a fronteira entre dado e texto. Um programa que pede JSON a um modelo lê a
resposta com o parser antes de usá-la, e quando a leitura falha ele faz algo deliberado: tenta de
novo, conserta ou registra a falha. **O que ele não faz nunca é seguir em frente com uma resposta
que não conseguiu ler**, porque tudo o que vem depois passa a trabalhar sobre nada e parece estar
bem.

Pedir bem torna a segunda e a terceira respostas mais raras, e não as torna impossíveis. Um modelo
produz texto provável (lição 1), e no texto de onde ele aprendeu há muito JSON apresentado por uma
frase ou embrulhado num bloco de código. É por isso que a conferência não é opcional, e por isso a
lição 19 parte dela.
