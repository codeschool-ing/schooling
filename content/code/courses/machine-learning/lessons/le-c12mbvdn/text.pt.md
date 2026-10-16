---
title: Texto como colunas
version: 1
---

A aula 6 transformou avaliações em colunas contando palavras, e percebeu o que isso perde: *on* saiu como
uma palavra que sugere **não** reclamação, porque só aparece em *arrived on time*. Ela prometeu que
contar pares de palavras recuperaria parte da ordem. Esta seção faz isso, e mais uma coisa.

- **Pares de palavras**, também chamados bigramas, são cada duas palavras vizinhas numa avaliação,
  contadas como uma coluna própria: `arrived late`, `on time`, `box was`.
  `CountVectorizer(ngram_range=(1, 2))` faz palavras soltas e pares juntos.
- O **TF-IDF** (frequência do termo, frequência inversa nos documentos) pesa cada contagem pelo quão rara
  a palavra é entre todas as avaliações. Uma palavra presente em toda avaliação, como *and*, diz pouco
  sobre qualquer uma delas e recebe peso pequeno; uma palavra em poucas avaliações recebe peso grande.

Salve isto como `text.py`; ele treina a mesma regressão logística em três versões das colunas de texto,
na divisão da aula 6, de 2.400 avaliações e 600:

```python
# text.py
import pandas as pd
from sklearn.feature_extraction.text import CountVectorizer, TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import roc_auc_score

reviews = pd.read_csv("data/reviews.csv")
train, test = reviews.iloc[:2400], reviews.iloc[2400:]

print("columns from the text      columns   right    AUC")
for name, words in [("single words, counted", CountVectorizer()),
                    ("words and pairs, counted", CountVectorizer(ngram_range=(1, 2))),
                    ("words and pairs, tf-idf", TfidfVectorizer(ngram_range=(1, 2)))]:
    words.fit(train["text"])
    model = LogisticRegression(max_iter=1000).fit(words.transform(train["text"]),
                                                  train["complaint"])
    chance = model.predict_proba(words.transform(test["text"]))[:, 1]
    print(f"{name:25} {len(words.vocabulary_):8} {((chance >= 0.5) == test['complaint']).mean():7.1%}"
          f" {roc_auc_score(test['complaint'], chance):6.3f}")

weight = dict(zip(words.get_feature_names_out(), model.coef_[0]))
print("weights in the last model:", ", ".join(f"{w} {weight[w]:+.2f}" for w in
                                              ["arrived", "late", "arrived late", "on", "on time"]))
```

O vetorizador é ajustado só nas avaliações de treino, então o vocabulário, e a ideia que o TF-IDF faz de
quais palavras são raras, vêm de linhas que o teste nunca toca.

```
ana@lab:~/ml$ python text.py
columns from the text      columns   right    AUC
single words, counted           39   94.2%  0.966
words and pairs, counted       524   94.3%  0.964
words and pairs, tf-idf        524   93.8%  0.967
weights in the last model: arrived +0.25, late +2.37, arrived late +2.37, on -1.27, on time -1.27
```

**Os pares fizeram 485 colunas novas e não mudaram nada**: 94,2% de acerto com palavras soltas, 94,3% com
pares, uma AUC que mexeu na terceira casa decimal. A última linha diz por quê. `on` e `on time` têm
exatamente o mesmo peso, e também `late` e `arrived late`. Nestas avaliações *on* nunca aparece sem
*time*, nem *late* sem *arrived*, então o par não diz nada que a palavra sozinha não dizia. As avaliações
foram escritas a partir de um conjunto fixo de frases, e nenhuma frase quer dizer outra coisa com as
palavras em outra ordem.

Texto de verdade não é assim. *"Not fresh"* e *"fresh, not bruised"* têm as mesmas palavras e querem
dizer coisas opostas, e ali os pares pagam suas colunas. A lição é a mesma de todo atributo desta aula:
**acrescente, meça, e fique com ele só se ele mover o número que importa.** Aqui não moveu, e 485 colunas
que não fazem nada são 485 colunas para calcular, guardar e explicar.

O TF-IDF também não fez melhor, por um motivo parecido: as avaliações têm todas poucas frases, então
quantas vezes uma palavra aparece numa avaliação é quase sempre uma. Em documentos longos, onde *the*
aparece quarenta vezes e *mouldy* uma, a ponderação importa muito.

Além de contar, texto pode virar colunas por **embeddings**: um modelo de linguagem transforma cada
avaliação em algumas centenas de números que põem avaliações de sentido parecido perto umas das outras,
*rotten* perto de *mouldy* mesmo que o modelo nunca as tenha visto juntas. Esse é o assunto do
`deep-learning`, e dos cursos de modelos de linguagem depois dele.
