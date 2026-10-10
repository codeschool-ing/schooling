---
title: Naive Bayes, para contar palavras
version: 1
---

As avaliações do `reviews.csv` são frases curtas, *"Bruised bananas, box was damaged"*, e o suporte
marca algumas como reclamação. Transformar texto em colunas é assunto da aula 14; o jeito mais
simples é **contar as palavras**, com uma coluna por palavra do vocabulário e, para cada avaliação,
quantas vezes ela usa cada uma. O `CountVectorizer` faz isso.

O **naive Bayes** é um classificador feito exatamente para dados nesse formato. Ele pergunta, para
cada classe, com que frequência cada palavra aparece nas avaliações daquela classe, e pontua uma
avaliação nova multiplicando a evidência das palavras dela, a partir de quão comum cada classe é.
Ajustar é contar, então é rápido com qualquer quantidade de texto. Salve isto como `bayes.py`; ele
treina nas 2.400 primeiras avaliações e testa nas 600 últimas:

```python
# bayes.py
import numpy as np
import pandas as pd
from sklearn.feature_extraction.text import CountVectorizer
from sklearn.naive_bayes import MultinomialNB

reviews = pd.read_csv("data/reviews.csv")
train, test = reviews.iloc[:2400], reviews.iloc[2400:]

words = CountVectorizer().fit(train["text"])
bayes = MultinomialNB().fit(words.transform(train["text"]), train["complaint"])
said = bayes.predict(words.transform(test["text"]))
print(f"{len(words.vocabulary_)} words; right on {(said == test['complaint']).mean():.1%} "
      f"of {len(test)} test reviews (always 'no complaint': {1 - test['complaint'].mean():.1%})")

ratio = bayes.feature_log_prob_[1] - bayes.feature_log_prob_[0]   # log P(word|complaint) - log P(word|not)
vocab = np.array(words.get_feature_names_out())
print("words that most suggest a complaint:", ", ".join(vocab[np.argsort(-ratio)[:6]]))
print("words that most suggest the opposite:", ", ".join(vocab[np.argsort(ratio)[:6]]))

chance = bayes.predict_proba(words.transform(test["text"]))[:, 1]
print(f"test reviews scored below 1% or above 99%: {((chance < 0.01) | (chance > 0.99)).mean():.1%}")
```

```
ana@lab:~/ml$ python bayes.py
39 words; right on 92.3% of 600 test reviews (always 'no complaint': 78.2%)
words that most suggest a complaint: bruised, wilted, late, soggy, rotten, missing
words that most suggest the opposite: ripe, lovely, crisp, sweet, tasty, on
test reviews scored below 1% or above 99%: 56.8%
```

**92,3% de acerto**, contra 78,2% de um modelo que nunca diz *reclamação*. Como o naive Bayes é feito
de contagens, ele pode ser lido: as palavras que mais sugerem uma reclamação são as que uma pessoa
escolheria, *bruised*, *wilted*, *late*, *soggy*, *rotten*, *missing*, e do outro lado *ripe*,
*lovely*, *crisp*. A diferença de log-probabilidades calculada no programa é quanto mais
frequentemente cada palavra aparece nas reclamações do que no resto.

O vocabulário tem 39 palavras porque as avaliações foram geradas a partir de frases curtas.
Avaliações reais têm milhares de palavras, muitas delas raras, e o naive Bayes lida bem com isso:
cada palavra ganha sua contagem, e as contagens nunca interagem.

Repare que *on* está entre as palavras que sugerem **não** haver reclamação. Ela vem de *arrived on
time*, e o modelo não tem ideia de que *on* faz parte de uma expressão. Ele conta as palavras uma de
cada vez, e todo sentido que mora na ordem delas se perde, que é o preço de transformar texto em
contagens; a aula 14 conta pares de palavras para recuperar parte disso.
