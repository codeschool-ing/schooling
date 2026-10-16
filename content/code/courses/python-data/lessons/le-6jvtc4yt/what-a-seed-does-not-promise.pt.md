---
title: O que uma semente não promete
version: 1
---

**Uma semente torna uma execução repetível com o mesmo código e as mesmas bibliotecas. Não torna um
resultado verdadeiro, e não congela os números para sempre.** Três limites, cada um um jeito de um
notebook semeado ainda surpreender você.

## Entre versões do NumPy

O NumPy garante que as funções globais antigas, `np.random.seed` e as outras, vão produzir os
mesmos números para a mesma semente em toda versão futura: essa interface está congelada, o que é
parte do motivo de ela continuar por aí. Ele **não** faz essa promessa para os métodos do Generator.
Um NumPy futuro pode melhorar o algoritmo por trás de `rng.normal` ou de `rng.choice`, e a mesma
semente vai dar outros números. É mais um motivo para a aula 3 fixar `numpy==2.5.3`: a semente só
reproduz uma execução junto com a versão em que ela rodou.

## Em trabalho paralelo

Dois trabalhos que precisam cada um de números aleatórios, uma simulação dividida entre processos,
por exemplo, não podem compartilhar um gerador, e não podem ser semeados cada um com `2025`, o que
os faria sortear os mesmos números. Um gerador pode **gerar** filhos cujas sequências são
independentes entre si e do pai:

```python
parent = np.random.default_rng(2025)
children = parent.spawn(3)
[c.integers(0, 100, size=3) for c in children]
```

```
[array([87, 99, 72]), array([53, 71, 62]), array([ 5, 72, 24])]
```

Três geradores, três sequências diferentes, todas reproduzíveis a partir da única semente. Dê um a
cada trabalhador.

## Contra você mesmo

A semente é um número que você escolheu, e outro dá outra amostra, outra divisão, outro intervalo de
bootstrap. **Testar sementes até o resultado parecer bom é um jeito de escolher o resultado**, e nada
no notebook mostraria que foi feito: o código mostra uma semente e um número satisfatório. As
defesas são hábitos:

- escolha a semente antes de olhar os resultados, escreva-a no topo e deixe-a quieta;
- quando um resultado depende de aleatoriedade, rode-o com várias sementes, como a seção do
  bootstrap fez, e informe a dispersão, não o melhor;
- se uma conclusão muda com a semente, a conclusão era o ruído.

O curso `machine-learning` divide dados em treino e teste com exatamente esse tipo de embaralhamento
semeado, e os mesmos três hábitos valem lá com mais em jogo.
