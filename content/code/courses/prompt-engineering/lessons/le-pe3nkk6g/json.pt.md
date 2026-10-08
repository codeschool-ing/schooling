---
title: JSON, o formato que um programa quer
version: 2
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

O prompt diz como o objeto é, campo por campo, e diz que nada mais pode vir junto. Salve-o como
`~/pe/prompts/classify.txt`:

```
ana@lab:~/pe$ cat prompts/classify.txt
Classify the café review between the <review> tags.

Reply with one JSON object and nothing else: no sentence before
or after it, and no code fence. Use exactly these fields:
  "review"         the review's number, as a number
  "sentiment"      one of "positive", "negative", "mixed"
  "topics"         a list of short lowercase words
  "staff_praised"  true or false

<review number="3">
Waited fifteen minutes for a tea at noon. The staff were kind about it.
</review>
```

Três coisas nele fazem o trabalho. Os campos têm nome exato, então o modelo não tem motivo para
chamar um deles de `mood` na terça. Os valores que vêm de uma lista estão listados. E **o prompt
nomeia os dois embrulhos que os modelos mais acrescentam**, uma frase de introdução e uma cerca de
código em Markdown, porque "só JSON" sozinho não os descarta aos olhos do modelo.

A lição 19 troca a lista de campos por um **esquema** formal, um documento contra o qual um programa
consegue conferir uma resposta. Aqui a descrição está em prosa, e a conferência é só se a resposta é
lida.

## Três respostas, e o que um parser diz a cada uma

A primeira é a resposta do modelo a esse prompt, salva num arquivo:

```
ana@lab:~/pe$ ask - --temperature 0 --plain < prompts/classify.txt > replies/good.json
ana@lab:~/pe$ cat replies/good.json
{"review":3,"sentiment":"mixed","topics":["waited","tea","staff","kind"],"staff_praised":true}
ana@lab:~/pe$ python3 -m json.tool replies/good.json > /dev/null; echo "exit $?"
exit 0
```

O `python3 -m json.tool` é o leitor de JSON do próprio Python, rodado na linha de comando. Ele lê o
arquivo e o imprime de volta, arrumado; aqui a impressão é jogada fora e só o **código de saída**
fica, porque é isso que um programa confere. `0` quer dizer que foi lido. O objeto tem todos os
campos, com os tipos pedidos, e `mixed`, da lista.

A segunda é o que voltou de um prompt mais curto, o que a maioria das pessoas escreve primeiro:

```
ana@lab:~/pe$ cat prompts/classify-short.txt
Classify this café review as JSON with the fields review, sentiment, topics and staff_praised.

Review 3: Waited fifteen minutes for a tea at noon. The staff were kind about it.
ana@lab:~/pe$ ask - --temperature 0 --plain < prompts/classify-short.txt > replies/chatty.json
ana@lab:~/pe$ cat -n replies/chatty.json
     1	Here is the classification of the café review as JSON:
     2	
     3	```
     4	{
     5	  "review": "Waited fifteen minutes for a tea at noon. The staff were kind about it.",
     6	  "sentiment": "NEUTRAL",
     7	  "topics": ["wait time", "customer service"],
     8	  "staff_praised": true
     9	}
    10	```
    11	
    12	Note: The sentiment is classified as NEUTRAL because the reviewer mentions a wait time, but also mentions that the staff were kind about it, which suggests a positive aspect of their experience.
ana@lab:~/pe$ python3 -m json.tool replies/chatty.json > /dev/null; echo "exit $?"
Expecting value: line 1 column 1 (char 0)
exit 1
```

**O parser desistiu no primeiro caractere.** JSON tem de começar com um valor, e `H` não é um. Uma
pessoa vê um objeto ali dentro; o programa vê uma falha, e nunca fica sabendo que o objeto estava
lá. Olhe o objeto mesmo assim: `review` guarda o texto da avaliação em vez do número, e `sentiment`
é `NEUTRAL`, em maiúsculas, um valor que ninguém listou porque ninguém listou nenhum. Para cada uma
dessas coisas o prompt mais longo tinha uma linha. A lição 19 recupera o objeto de uma resposta
assim com um pequeno passo de conserto.

O terceiro formato é comum o bastante para ser reconhecido de vista. Esta resposta foi escrita pelo
curso, para que a mensagem do parser possa ser lida sozinha:

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

Esse é o jeito do Python de escrever um dicionário, e é parecido o bastante com JSON para enganar o
olho. JSON exige aspas duplas, escreve o booleano `true` em minúsculas e recusa a vírgula depois do
último campo. O erro só cita o primeiro problema, na linha 2, coluna 3, a `'` de abertura. **Um
parser informa onde parou, não tudo o que está errado**, então consertar as aspas à mão só levaria o
erro para o `True`.

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
