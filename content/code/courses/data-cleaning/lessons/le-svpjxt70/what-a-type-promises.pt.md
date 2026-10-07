---
title: O que um tipo promete
version: 1
---

Todo arquivo deste curso foi lido do mesmo jeito desde a aula 2:

```python
import pandas as pd

customers = pd.read_csv("raw/customers.csv", dtype=str, keep_default_na=False,
                        na_values=[""]).drop_duplicates()
```

**`dtype=str` transforma cada coluna em texto, e isso foi uma escolha, não um atalho.** Texto
guarda qualquer coisa. Um ano digitado como `1900`, um preço escrito `R$ 94,50`, um consentimento
registrado como `não`: cada um chega exatamente como foi escrito, e nada é arredondado, adivinhado
ou descartado na entrada. Um leitor que adivinhasse os tipos por você teria tomado essas decisões
em silêncio, antes de você olhar uma única linha.

O custo é que texto não promete nada. Somar duas strings não dá uma soma, e `"9" > "10"` é
verdadeiro, porque texto se compara caractere por caractere. Ordenar anos de nascimento como texto
só funciona por sorte, enquanto todo ano tiver quatro dígitos.

Um tipo é uma promessa sobre todos os valores de uma coluna:

- **um inteiro** pode ser somado, ter média e ser comparado por tamanho;
- **uma data** pode ser subtraída de outra data e agrupada por mês;
- **um booleano** é verdadeiro ou falso, e mais nada;
- **um vazio**, em cada um deles, quer dizer "não se sabe", e fica separado de todo valor real.

Converter uma coluna é o momento em que você faz essa promessa, e o momento em que descobre quais
valores a quebram. **Uma conversão que falha ruidosamente está contando algo sobre os dados.** Uma
conversão que dá certo transformando em vazio os valores que não conseguiu ler escondeu a coisa
mais útil que aprendeu. O resto desta aula é sobre fazer toda conversão ser do tipo ruidoso.
