---
title: Números inteiros com buracos
version: 1
---

Os anos de nascimento convertidos acima saíram como `1986.0`, com um ponto decimal que nenhum ano
tem. Não é um problema de arredondamento. **Uma coluna de inteiros simples no pandas não consegue
guardar um vazio**, então, no momento em que aparece um vazio, a coluna inteira é armazenada como
ponto flutuante, onde mora o `NaN`:

```
ana@lab:~/clean$ python -c "import pandas as pd; s = pd.Series(['1987', None, '2001']); print(pd.to_numeric(s).to_string()); print(pd.to_numeric(s).astype('Int64').to_string())"
0    1987.0
1       NaN
2    2001.0
0    1987
1    <NA>
2    2001
```

A primeira impressão é o padrão: dois anos escritos como decimais e um `NaN`. A segunda são os
mesmos valores como `Int64`, com I maiúsculo, que é o inteiro anulável do pandas. Os anos voltam a
ser inteiros, e o vazio é `<NA>`, uma marca que quer dizer "não se sabe" em todo tipo anulável
(`Int64`, `boolean`, `string`), em vez de um número especial de ponto flutuante.

A diferença importa além da aparência:

- **Um ano em float convida a contas sem sentido**, como um ano médio de nascimento de 1983,47
  gravado de volta numa coluna de anos.
- **Floats perdem inteiros a partir de certo tamanho.** Um código de cliente ou um número de pedido
  de dezesseis dígitos guardado como float pode voltar com os últimos dígitos trocados; o inteiro
  anulável o mantém exato.
- **Um float gravado em arquivo volta como `1986.0`.** A próxima pessoa que lê esse arquivo como
  texto, como este curso faz, tem uma chave que já não é igual a `1986`, e uma junção sobre ela não
  casa nada sem levantar erro.

Então o hábito tem dois passos, nesta ordem: converter com a contagem da seção anterior e depois
passar para o tipo anulável. Uma coluna que é um identificador e não uma quantidade, como um CEP ou
um código de produto com zeros à esquerda, nem é convertida; a aula 7 os manteve como texto, e
**um número só é número se somar dois deles significar alguma coisa**.
