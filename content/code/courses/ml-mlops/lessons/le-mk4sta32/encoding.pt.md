---
title: Transformando palavras em números que o modelo usa
version: 1
---

Um algoritmo de aprendizado faz contas, então todo atributo precisa ser um número. Três dos da Ponto
Final são palavras: `channel`, `age_band` e `home_shop`. **A correção tentadora é numerá-los**,
Paulista 0, Pinheiros 1, Cambuí 2 e assim por diante, e ela está errada de um jeito que nenhuma
mensagem de erro aponta: o modelo passa a acreditar que Cambuí é o dobro de Pinheiros, e que
Savassi fica entre Cambuí e Batel. Ele vai ajustar contente um peso a essa ordem, que não existe.

**One-hot dá a cada valor uma coluna própria**, com 1 para o valor que a linha tem e 0 para todos
os outros. Nada é maior que nada. Este programa mostra no que um membro se transforma; salve-o como
`encode.py`:

```python
"""encode.py: what the model actually receives for one member."""
from sklearn.preprocessing import OneHotEncoder

import features

members = features.build("2025-09-30")
encoder = OneHotEncoder().fit(members[features.CATEGORICAL])

print(members[features.CATEGORICAL].head(1).to_string(index=False))
columns = encoder.get_feature_names_out()
row = encoder.transform(members[features.CATEGORICAL].head(1)).toarray()[0]
for name, value in zip(columns, row):
    print(f"  {name:22} {value:.0f}")
```

```
ana@dev:~/ml$ python encode.py
channel age_band home_shop
  store    25-34   Savassi
  channel_app            0
  channel_store          1
  channel_web            0
  age_band_18-24         0
  age_band_25-34         1
  age_band_35-49         0
  age_band_50-64         0
  age_band_65+           0
  home_shop_Batel        0
  home_shop_Cambuí       0
  home_shop_Moinhos      0
  home_shop_Online       0
  home_shop_Paulista     0
  home_shop_Pinheiros    0
  home_shop_Savassi      1
```

Três palavras viraram dezesseis colunas: três canais, cinco faixas de idade e sete lojas de
referência, com exatamente um 1 em cada grupo. `Online` é uma loja de referência porque os membros
que entraram pelo site ou pelo aplicativo são arquivados nela pelo gerador.

## O valor que não existia no treino

O codificador aprende as suas colunas com as linhas em que foi ajustado, e **um valor que só
aparece depois não tem coluna**. O aplicativo chegou em setembro de 2025, então um modelo treinado
num corte mais antigo nunca teria visto `channel_app`. O que acontece quando ele encontra um é uma
decisão, e o scikit-learn obriga você a escrevê-la: o `classify.py` passa
`handle_unknown="ignore"`, que codifica um valor desconhecido como tudo zero, o mesmo que "nenhum
dos canais que eu conheço". Sem isso, o codificador levanta um erro no primeiro membro do
aplicativo.

Nenhuma das duas escolhas é certa em geral. Ignorar mantém o serviço respondendo, com um modelo que
não sabe nada do canal novo; recusar o derruba, com barulho. **O que nunca está certo é não saber
qual das duas o seu modelo faz**, e a lição 10 é sobre perceber que as linhas começaram a trazer
valores, e misturas de valores, que o modelo nunca viu.

Categorias ordenadas são a exceção que vale uma frase. `age_band` tem uma ordem, e quem modela pode
codificá-la de 0 a 4 de propósito. Essa é uma escolha sobre o significado da coluna, feita por quem
o conhece, que é exatamente o que numerar as lojas não era.
