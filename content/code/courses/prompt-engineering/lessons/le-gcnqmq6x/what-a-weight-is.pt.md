---
title: O que é um peso
version: 1
---

Duas imagens do interior de um modelo são comuns, e as duas estão erradas. Uma é a de uma
biblioteca: o modelo guarda as frases que leu e acha a certa quando alguém pergunta. A outra pega
emprestada uma palavra da API: os "parâmetros" de um modelo seriam as configurações dele, a
temperatura e o limite de tokens. **Os parâmetros de um modelo são os números que ele aprendeu, e o
modelo é esses números.** Ele não guarda frase nenhuma, e as configurações que você manda junto com
um pedido são outra coisa, assunto das lições 13 a 17.

O menor modelo que você consegue abrir é o da bancada. A lição 1 imprimiu o tamanho dele, e a
última linha é a que interessa nesta lição:

```
ana@lab:~/pe$ toylm info
corpus:        761 words in corpus.txt
vocabulary:    72 distinct words
trigram rows:  152 contexts, 212 counts
bigram rows:   72 contexts, 152 counts
parameters:    436 stored counts
```

O `toylm` tem **436 parâmetros**, e cada um é uma contagem. O `toylm save` grava todos num arquivo,
que é o modelo inteiro no disco:

```
ana@lab:~/pe$ toylm save model.json
ana@lab:~/pe$ ls -l model.json
-rw-r--r-- 1 ana ana 7478 Oct  2 00:14 model.json
ana@lab:~/pe$ head -c 240 model.json; echo
{"bigram": {",": {"bread": 2}, ".": {"</s>": 98, "question": 6}, ":": {"at": 4, "is": 6, "tomato": 2, "what": 2, "when": 4, "yes": 6}, "<s>": {"ana": 4, "bruno": 5, "it": 6, "question": 6, "the": 77}, "?": {"answer": 12}, "a": {"coffee": 5,
```

Leia uma entrada: `"<s>": {... "the": 77}` diz que 77 linhas do corpus começam com `the`. Cada
número é um parâmetro. As porcentagens que a lição 1 imprimiu saem direto deles:

```
ana@lab:~/pe$ python3 -c "import json; print(json.load(open('model.json'))['trigram']['coffee is'])"
{'bitter': 1, 'cold': 2, 'hot': 16, 'ready': 3, 'strong': 5}
```

Essas cinco contagens somam 27, e `hot` é 16 delas, que são os 59,3% que o `toylm next "the
coffee is"` mostrou. **Mude um número deste arquivo e a resposta do modelo muda junto.** Não há
mais nada no modelo para mudar.

## O que são os pesos de um modelo grande

Um grande modelo de linguagem tem o mesmo arranjo, e a lição 1 já apontou a diferença que importa
aqui: os parâmetros dele não são contagens. **São números aprendidos no treinamento**, em geral
chamados de pesos, e nenhum deles, sozinho, quer dizer algo que você consiga ler. Onde o `toylm` tem
`"hot": 16`, uma rede neural tem bilhões de números como `-0.4121` e `0.0173`, e a nota de `hot`
sai de multiplicar os tokens do texto por todos eles.

O treinamento é o que dá valor a eles. A rede começa com números aleatórios, lê um trecho de
texto, dá nota a cada próximo token possível e confere a nota que deu ao token que de fato veio em
seguida. Cada peso é então empurrado um pouquinho na direção que teria deixado aquele token mais
provável. Repetidos sobre uma quantidade enorme de texto, esses empurrões viram gramática, fatos que
eram comuns no texto e o formato de programas e de argumentos.

Isso tem duas consequências que surpreendem:

- não dá para procurar uma frase nos pesos: o que o modelo leu está espalhado por todos eles,
  misturado com tudo o mais que ele leu. É por isso que ele produz texto fluente que não aparece em
  lugar nenhum dos dados de treinamento, e por isso que erra um fato que leu muitas vezes;
- os pesos não mudam enquanto você usa o modelo, e uma conversa não ensina nada a ele; o que ele
  "lembra" dentro de um chat é o texto anterior enviado de novo como entrada, que é a lição 4. Mudar
  os pesos é outro trabalho, e a lição 9 trata de quando vale a pena fazê-lo.

## O que "7B" quer dizer

Quando um modelo é descrito como **7B, ele tem sete bilhões de pesos**; 70B são setenta bilhões. A
letra é a palavra *billion*, bilhão em inglês, e mais nada. "Parâmetros" e "pesos" são usados para
a mesma coisa nos anúncios e, a rigor, os parâmetros são todos os números aprendidos: os pesos e um
conjunto menor de deslocamentos chamados vieses (*biases*), juntos.

A contagem é uma medida de tamanho, não de qualidade. Um modelo maior tem espaço para mais padrões,
e dois modelos com a mesma contagem podem ser muito diferentes por causa do que viram no treinamento
e por quanto tempo treinaram. O que a contagem decide, com exatidão, é quanta memória o modelo
precisa, e esse é o assunto da próxima seção.
