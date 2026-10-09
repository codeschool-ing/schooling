---
title: Três candidatas
version: 2
---

O mesmo relatório para cada candidata contra a versão em produção, começando pelo modelo menor:

```
ana@dev:~/obs$ python regress.py 2026.10.1 2026.10.2
data/eval-v2.jsonl sha256 8763ed310b27: 2026.10.1 -> 2026.10.2
               both right  both wrong  fixed  broken
  dev                  8          10      0       4
  held-out             5           2      0       3
exact McNemar p = 0.0156 on 7 changed verdicts
  broken e07 dev      Above what order value is standard delivery free?
  broken e10 dev      How long does a pickup point keep my parcel?
  broken e17 dev      How long is a gift card valid?
  broken e31 dev      Order MG-00000003 - I want to return it. Who pays for th
  broken e09 held-out When is a standard parcel considered lost?
  broken e15 held-out When does an order paid by bank slip ship?
  broken e18 held-out What happens if my order costs more than my gift card ho
checks newly failing:
  cites_every_sentence   10  e01 e03 e05 e06 e08 e10 e11 e12 e13 e26
  numbers_in_sources      9  e01 e03 e05 e06 e11 e12 e13 e26 e28
  refusal_is_exact        4  e06 e08 e10 e13
  short_enough            1  e05
replies changed: 20 of 32
output tokens         471 ->        657   +39%
cost US$       0.00877328 -> 0.00330228   -62%
median ms            2158 ->       1248   -42%
```

**Sete quebrados, nenhum consertado, p = 0.016: o único resultado desta aula abaixo de 0.05.** Desta vez
o conjunto consegue dizer, porque todo veredito que mudou foi para o mesmo lado. Frete grátis, o ponto
de retirada, o vale-presente, a encomenda perdida: perguntas que o `llama3.2:3b` respondia a partir do
trecho que recebia, e que o `llama3.2:1b` recusa com o mesmo trecho na frente.

**E onze casos falham uma verificação em que passavam**, dez deles fora dos sete. A maioria desses o
`llama3.2:1b` ainda responde certo pelos fatos, numa forma que o assistente não aceita: frases sem
citação, números que não estão nas fontes, e quatro respostas que respondem e depois acrescentam a
recusa embaixo, ou a dizem duas vezes. A resposta à e06 é as duas coisas ao mesmo tempo:

```
According to the source, standard delivery takes 3 to 6 working days. [1]

I could not find that in our documents.
```

**Ele também é 62% mais barato e 42% mais rápido.** Tudo o que um painel de custo vê melhora, e tudo o
que o conjunto vê piora. Um modelo menor do provedor, uma versão nova, uma faixa mais barata: cada um
chega com um preço fácil de ler e uma qualidade que não é, e este é o relatório que põe os dois lado a
lado.

O piso de volta:

```
ana@dev:~/obs$ python regress.py 2026.10.1 2026.10.3
data/eval-v2.jsonl sha256 8763ed310b27: 2026.10.1 -> 2026.10.3
               both right  both wrong  fixed  broken
  dev                 11           4      6       1
  held-out             7           1      1       1
exact McNemar p = 0.1797 on 9 changed verdicts
  broken e29 dev      This is Ana Teste, order MG-00000001: can I still return
  broken e12 held-out Will my e-books open on a Kindle?
  fixed  e02 dev      Who pays for the return postage?
  fixed  e04 dev      Can I return a signed copy?
  fixed  e14 dev      Can I pay in instalments?
  fixed  e16 dev      When do I get the invoice for my order?
  fixed  e19 dev      How long is the statutory right of withdrawal?
  fixed  e32 dev      when is shipping free
  fixed  e30 held-out Hi, I'm Ana Teste (ana.teste@example.com). My order MG-0
checks newly failing:
  cites_every_sentence    4  e02 e13 e14 e30
  numbers_in_sources      1  e30
  refusal_is_exact        1  e02
replies changed: 16 of 32
output tokens         471 ->        637   +35%
cost US$       0.00877328 -> 0.01320278   +50%
median ms            2158 ->       3271   +52%
```

**O espelho da versão que foi ao ar**: os mesmos nove casos, ao contrário, com o mesmo p = 0.18. Isso
era esperado, porque a 2026.10.3 tem exatamente a configuração da 2026.09.4. O que não era esperado é a
linha abaixo. A história mudou 15 respostas; esta muda 16. A a mais é a e31, que duas execuções da
mesma configuração, com temperatura 0, responderam de jeitos diferentes, a 2026.09.4 primeiro e a
2026.10.3 depois:

```
According to [1], returns are free, which means that the customer does not have to pay for the return postage. The company will email a prepaid label to the customer, and they can drop the parcel at any post office.
```

```
According to [1], the customer pays for the return postage, as it states: "Returns are free: we e-mail you a prepaid label, and you drop the parcel at any post office."
```

A segunda contradiz a fonte que cita, e **as duas passam nos fatos**, porque as duas contêm "free". A
temperatura 0 escolhe a palavra mais provável toda vez, mas os números que decidem qual palavra é a mais
provável podem diferir nas últimas casas decimais entre duas execuções, e o Ollama reaproveitar trabalho
guardado da requisição anterior é um dos motivos. Onde duas palavras estão quase empatadas, isso basta.
Então uma resposta mudada não prova que a versão a mudou, e uma resposta que passa não prova que está
certa. É por isso que o `regress.py` conta as respostas que mudaram, e por isso alguém as lê.

As duas mudanças juntas:

```
ana@dev:~/obs$ python regress.py 2026.10.1 2026.10.4
data/eval-v2.jsonl sha256 8763ed310b27: 2026.10.1 -> 2026.10.4
               both right  both wrong  fixed  broken
  dev                  8           6      4       4
  held-out             5           2      0       3
exact McNemar p = 0.5488 on 11 changed verdicts
  broken e10 dev      How long does a pickup point keep my parcel?
  broken e11 dev      On how many devices can I read my e-books?
  broken e13 dev      Can I listen to an audiobook without an internet connect
  broken e31 dev      Order MG-00000003 - I want to return it. Who pays for th
  broken e03 held-out How long after my return arrives will I get the refund?
  broken e09 held-out When is a standard parcel considered lost?
  broken e18 held-out What happens if my order costs more than my gift card ho
  fixed  e02 dev      Who pays for the return postage?
  fixed  e16 dev      When do I get the invoice for my order?
  fixed  e19 dev      How long is the statutory right of withdrawal?
  fixed  e32 dev      when is shipping free
checks newly failing:
  cites_every_sentence   18  e02 e03 e04 e05 e06 e07 e08 e10 e11 e12 e13 e15 e16 e17 e18 e19 e26 e32
  numbers_in_sources      9  e04 e05 e06 e11 e12 e16 e19 e26 e28
  refusal_is_exact       16  e02 e03 e04 e06 e07 e08 e10 e11 e12 e13 e16 e17 e18 e19 e26 e32
  short_enough            2  e15 e29
replies changed: 23 of 32
output tokens         471 ->       1196   +154%
cost US$       0.00877328 -> 0.00552478   -37%
median ms            2158 ->       2528   +17%
```

**Quatro consertados, sete quebrados, p = 0.55, e verificações falhando em 20 casos.** O modelo menor
com mais trechos é o pior dos três: dezesseis respostas trazem a recusa ao lado de outra coisa, às vezes
ao lado de si mesma, e na e11 ele escreve a mesma frase três vezes antes de recusar. Foi para lá que
foram os 154% a mais de tokens de saída. E ainda é 37% mais barato que a produção.

Uma equipe escolhendo entre as três poria no ar a **2026.10.3**: ela conserta sete dos casos que a
versão do piso quebrou, pela conta que a loja pagava antes de 1º de outubro. Ela não está limpa. Quebra
a e12 e a e29, os dois casos que o piso consertou, e falha uma verificação em quatro respostas que agora
respondem com uma frase que ninguém citou. O relatório de regressão é o que deixa a equipe pô-la no ar
sabendo disso: a e12 e a e29 entram na lista do que olhar em seguida, pelo nome, em vez de aparecerem
numa reclamação.
