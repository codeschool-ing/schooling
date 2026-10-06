---
title: Três candidatas
version: 1
---

O mesmo relatório para cada candidata contra a versão em produção, começando pelo modelo novo:

```
ana@lab:~/obs$ python regress.py 2026.10.1 2026.10.2
data/eval-v2.jsonl sha256 0d464ef783cd: 2026.10.1 -> 2026.10.2
               both right  both wrong  fixed  broken
  dev                 10          18      0       0
  held-out             8           6      0       0
exact McNemar p = 1.0000 on 0 changed verdicts
checks newly failing: none
replies changed: 5 of 42
output tokens         637 ->        782   +23%
cost US$       0.00944242 -> 0.02061592   +118%
median ms              92 ->         95   +2%
```

**Nada se mexeu, e o preço mais que dobrou.** Nenhum veredicto mudou, cinco respostas mudaram de
redação, o extract-2 escreve 23% mais tokens, e com o dobro do preço por token o conjunto custa 118% a
mais para responder. Uma taxa de acerto sozinha teria relatado esta candidata como "sem mudança". É uma
regressão, em dinheiro, e não compra nada que estas 42 perguntas consigam ver.

As cinco respostas que mudaram ainda precisam ser lidas, porque o conjunto avalia fatos e forma, e uma
resposta pode mudar de jeitos que nenhum dos dois vê: uma frase a mais, verdadeira mas fora do ponto,
como as definições de relevância da aula 11 discordavam. O `regress.py` as conta para que alguém saiba
quantas ler.

O piso de volta:

```
ana@lab:~/obs$ python regress.py 2026.10.1 2026.10.3
data/eval-v2.jsonl sha256 0d464ef783cd: 2026.10.1 -> 2026.10.3
               both right  both wrong  fixed  broken
  dev                 10          15      3       0
  held-out             8           4      2       0
exact McNemar p = 0.0625 on 5 changed verdicts
  fixed  e07 dev      Above what order value is standard delivery free?
  fixed  e17 dev      When is the contract of sale formed?
  fixed  e38 dev      My parcel MG-00000001 still hasn't arrived, two weeks no
  fixed  e24 held-out Do you store my IP address?
  fixed  e42 held-out right of withdrawal days
checks newly failing: none
replies changed: 12 of 42
output tokens         637 ->        956   +50%
cost US$       0.00944242 -> 0.01821592   +93%
median ms              92 ->        651   +604%
```

**O espelho da versão que foi ao ar.** Os mesmos cinco casos consertados, nada quebrado, e o custo e a
latência voltam a mais ou menos o que eram antes de 2 de outubro. O valor-p é o mesmo 0,0625, pela mesma
razão: cinco casos. Ninguém precisa que ele seja menor para lançar esta, porque todo caso que mudou mudou
na direção certa e cada um pode ser lido.

As duas mudanças juntas:

```
ana@lab:~/obs$ python regress.py 2026.10.1 2026.10.4
data/eval-v2.jsonl sha256 0d464ef783cd: 2026.10.1 -> 2026.10.4
               both right  both wrong  fixed  broken
  dev                 10          14      4       0
  held-out             8           4      2       0
exact McNemar p = 0.0312 on 6 changed verdicts
  fixed  e04 dev      Can I return a signed copy?
  fixed  e07 dev      Above what order value is standard delivery free?
  fixed  e17 dev      When is the contract of sale formed?
  fixed  e38 dev      My parcel MG-00000001 still hasn't arrived, two weeks no
  fixed  e24 held-out Do you store my IP address?
  fixed  e42 held-out right of withdrawal days
checks newly failing: e38 short_enough
replies changed: 23 of 42
output tokens         637 ->       1389   +118%
cost US$       0.00944242 -> 0.04161892   +341%
median ms              92 ->        904   +877%
```

**Seis consertados, e o primeiro resultado significativo da aula, p = 0,031**, e ainda assim não é a
candidata para lançar. Uma resposta, e38, agora falha numa verificação em que passava: o `short_enough`
da aula 8, mais de oitenta palavras, porque o extract-2 mantém até quatro frases e o piso mais baixo lhe
dá mais de onde escolher. E o conjunto custa mais de quatro vezes mais para responder e demora cerca de
dez vezes mais.

Uma equipe escolhendo entre as três lançaria a **2026.10.3**: ela conserta o que a versão do piso quebrou,
pelo custo que a loja pagava antes. O sexto conserto, e04, é a única coisa que a 2026.10.4 acrescenta, e
vem com uma verificação quebrada e uma conta quadruplicada; é motivo para olhar o e04, não para trocar o
modelo.
