---
title: Quão certa uma amostra pode ser
version: 2
---

Uma taxa de aprovação tirada de uma amostra é uma estimativa, e toda estimativa precisa do seu erro ao
lado. O `grade_sample.py` imprime um **intervalo de Wilson**: a faixa em que está a taxa verdadeira, com
95% de confiança, dado quantas respostas passaram de quantas foram avaliadas. Ele se comporta melhor do
que o `p ± 1.96 × √(p(1-p)/n)` dos livros com amostras pequenas e perto de 0% ou 100%, que é onde
resultados de avaliação costumam estar; o código são dez linhas no `grade_sample.py`.

A largura do intervalo depende de quantas respostas foram avaliadas, e não do tamanho do tráfego. O
`sizes.py` imprime a meia-largura para uma taxa de 70% em cinco tamanhos de amostra:

```python
"""sizes.py: how close a sample of n replies gets to a true pass rate of 70%, at 95%."""
import math

for n in (50, 100, 400, 1000, 4000):
    print(f"n = {n:5}   a pass rate of 70% is known to within {1.96 * math.sqrt(0.7 * 0.3 / n):5.1%}")
```

```
ana@dev:~/obs$ python sizes.py
n =    50   a pass rate of 70% is known to within 12.7%
n =   100   a pass rate of 70% is known to within  9.0%
n =   400   a pass rate of 70% is known to within  4.5%
n =  1000   a pass rate of 70% is known to within  2.8%
n =  4000   a pass rate of 70% is known to within  1.4%
```

**Reduzir o erro à metade exige quatro vezes a amostra.** Cem respostas dão ±9 pontos; quatrocentas dão
±4,5; mil, ±2,8. Essa aritmética decide a maior parte das perguntas práticas:

- **Para ver uma queda de 9 pontos**, como a que a versão desta semana mostra, são precisas algumas
  centenas de respostas por versão. A semana teve 134 e 141, e é por isso que mesmo avaliando tudo os
  intervalos se sobrepõem; o décimo uniforme teve 10 e 13, que não dizem nada.
- **Para ver uma queda de 3 pontos**, são precisas alguns milhares por período, porque as duas taxas
  levam um erro e os dois se somam. No volume desta loja isso são meses de tráfego, e uma equipe que
  precisa saber antes tem de avaliar o conjunto de avaliação, onde as perguntas são as mesmas dos dois
  lados.
- **O tamanho do tráfego não importa**, desde que a amostra seja uma parte pequena dele. Quatrocentas
  respostas dizem tanto sobre um milhão quanto sobre dez mil.

## Comparar duas taxas

"A versão piorou?" é uma pergunta sobre duas taxas, e a resposta honesta vem de dois intervalos: se
não se sobrepõem, sim; se se sobrepõem muito, a amostra não sabe dizer. Com a semana inteira, 35,2% a
51,7% contra 26,7% a 42,2%: eles se sobrepõem, e o relato certo é "provavelmente pior pela medida
deste juiz, não demonstrado", mesmo com toda resposta avaliada. **O limite é a semana, não a
amostra.** A aula 14 responde direito a pergunta para uma mudança testada antes da versão, no conjunto
de avaliação, com um teste feito para duas medidas das mesmas perguntas.
