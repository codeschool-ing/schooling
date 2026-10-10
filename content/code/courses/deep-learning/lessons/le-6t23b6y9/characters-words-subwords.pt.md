---
title: Caracteres, palavras e os pedaços no meio do caminho
version: 1
---

A imagem que a maioria traz é a de um modelo que lê: as palavras entram, e algo lá dentro as pesa.
**O que entra é uma lista de inteiros.** Antes de uma rede ver uma frase, um programa separado a corta
em pedaços e troca cada pedaço pela posição dele numa lista fixa. Essa lista é o **vocabulário**, o
programa é o **tokenizador**, e um pedaço é um **token**. Tudo o que o modelo sabe sobre texto, ele
aprendeu através desses inteiros.

Então a primeira decisão é o que um pedaço deve ser. Esta aula responde num texto pequeno o bastante
para ser lido, e o texto é o mesmo em todas as seções: quarenta e cinco linhas sobre uma cidade com
feira que não existe. Ele está em inglês, porque o tokenizador desta aula vai ser treinado em inglês, e
a última seção mostra o que isso custa ao português. Salve-o como `~/dl/corpus.txt`:

```
The market at Wenbury opens on Monday and closes on Saturday night.
On Monday the baker sells bread, and the farmer sells apples and pears.
On Tuesday the miller sells flour, and the farmer sells plums and cherries.
On Wednesday the potter sells bowls, and the baker sells cakes and buns.
On Thursday the farmer brings a goat, two sheep and a cow to the square.
On Friday the miller brings flour, and the potter brings jugs and cups.
On Saturday everyone comes, and the square is full until the lamps are lit.
The baker wakes before the sun. The farmer wakes before the baker.
The miller wakes when the river is loud, and the potter wakes last of all.
A child asked the baker why bread rises. The baker said it is the yeast.
A child asked the farmer why pears fall. The farmer said it is the wind.
A child asked the miller why the wheel turns. The miller said it is the river.
A child asked the potter why bowls crack. The potter said it is the fire.
The apples are red, the pears are green, and the plums are dark blue.
The cherries are red, the lemons are yellow, and the grapes are green.
The baker paints his door yellow. The potter paints her door blue.
The farmer paints the gate green, and the miller paints the wheel red.
The goat eats apples, the sheep eat grass, and the cow eats hay.
The dog sleeps by the door, the cat sleeps by the fire, and the hen sleeps in the barn.
On Monday the dog follows the baker. On Tuesday the dog follows the miller.
On Wednesday the cat follows the potter. On Thursday the cat follows the farmer.
The baker sells three loaves for one coin and six buns for two coins.
The farmer sells four apples for one coin and five pears for two coins.
The miller sells two bags of flour for three coins on a good day.
The potter sells one bowl for four coins and one jug for five coins.
In spring the farmer plants apples, pears, plums and cherries in long rows.
In summer the baker makes cakes with cherries, and the children run to the stall.
In autumn the miller grinds the wheat, and the river turns the wheel all night.
In winter the potter fires the kiln, and the whole square smells of smoke.
The goat is white, the sheep is grey, the cow is brown, and the dog is black.
The cat is black too, and it watches the hen from the barn roof.
Every Friday the baker and the potter argue about the price of cups.
Every Tuesday the miller and the farmer argue about the price of flour.
Nobody wins, and on Saturday they sit together and eat cherries.
The road to Wenbury is long, and the carts are slow when the road is wet.
A cart with two wheels carries bread. A cart with four wheels carries flour.
When it rains on Monday, the baker sells less bread and more cakes.
When it rains on Thursday, the farmer keeps the goat and the sheep at home.
When it rains on Friday, the potter covers the bowls and the jugs.
The old miller says the river remembers every wheel that ever turned.
The young potter says the fire remembers every bowl that ever cracked.
The baker says nothing, because the baker is busy selling bread.
At night the lamps go out one by one: first the baker, then the farmer,
then the miller, and last of all the potter, who is still at the wheel.
On Sunday the market is closed, and the square is quiet until Monday.
```

Três jeitos de cortá-lo são óbvios: em caracteres, em palavras, ou em algo entre os dois. Salve isto
como `~/dl/split.py`, que testa os dois primeiros:

```python
# split.py: the corpus cut into characters and into words, and a sentence it never saw
import re

text = open("corpus.txt").read()
chars = sorted(set(text))
words = re.findall(r"\w+|[^\w\s]", text)
vocab = sorted(set(words))
print(f"characters: {len(chars):4d} different, {len(text):5d} in the corpus")
print(f"words:      {len(vocab):4d} different, {len(words):5d} in the corpus")

new = "On Sunday the weaver sells blankets."
pieces = re.findall(r"\w+|[^\w\s]", new)
print("as words:     ", [w if w in vocab else "<unk>" for w in pieces])
print("as characters:", len(new), "symbols, none unknown:", all(c in chars for c in new))
```

```
PENDING split
```

## Caracteres: nada desconhecido, e comprido

**Quarenta caracteres diferentes cobrem o corpus inteiro**, contando maiúsculas, pontuação e a quebra
de linha, e qualquer frase em inglês que você digitar é feita deles. A frase que o corpus nunca viu
sai inteira, com todo símbolo conhecido. O preço é o comprimento: o texto tem 3.261 tokens, um por
caractere, e o modelo precisa descobrir do zero que `b`, `a`, `k`, `e` e `r`, nessa ordem, querem dizer
alguém que vende pão. Todo passo de uma rede que lê uma sequência custa tempo por token, então um
vocabulário de caracteres deixa comprido tudo o que vem depois dele.

## Palavras: curto, e cego para o que é novo

**Cortado em palavras, o mesmo texto tem 713 tokens**, menos de um quarto do comprimento, com 187
entradas diferentes. Cada token agora carrega um sentido sozinho. Mas `weaver` e `blankets` não estavam
no corpus, então não têm entrada, e a frase chega ao modelo com dois buracos marcados `<unk>`. O que
essas palavras diziam se perde antes da primeira camada.

Um corpus maior não resolve isso, só torna mais raro. Um vocabulário de palavras para texto de verdade
precisa de centenas de milhares de entradas e ainda deixa de fora nomes, erros de digitação e toda
palavra criada depois que ele foi montado. Ele também trata `baker` e `bakers` como duas entradas sem
relação, o que joga fora a única coisa óbvia sobre elas.

## Os pedaços no meio do caminho

A saída é um vocabulário de **subpalavras**: palavras comuns ficam inteiras, palavras raras são
cortadas em pedaços menores que são comuns, e caracteres isolados, ou bytes isolados, ficam no fundo
para que nada seja desconhecido. `weaver` vira alguns pedaços que o vocabulário já tem, a frase mantém
o sentido, e a sequência fica perto do comprimento da versão em palavras.

Quais pedaços, porém, não é algo que alguém escreve à mão. **Eles são aprendidos do texto, contando**,
e a próxima seção faz essa contagem numa página de Python.
