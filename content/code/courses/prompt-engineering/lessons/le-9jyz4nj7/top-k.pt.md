---
title: "Top-k: manter as k melhores"
version: 1
---

A temperatura remodela a lista inteira de próximas palavras, e a cauda continua nela: na
temperatura 1, `bitter` ainda tem 3,7% depois de `the coffee is`, e no vocabulário de muitos
milhares de tokens de um modelo grande a cauda é enorme. Cada palavra dela é improvável, e juntas
não são. **Top-k e top-p tiram a cauda antes do sorteio em vez de encolhê-la.** O top-k é o mais
simples dos dois.

**O top-k mantém as k palavras de nota mais alta, joga fora o resto e divide 100% entre as que
sobraram.** Com k igual a 2:

```
ana@lab:~/pe$ toylm dist "the coffee is" --top-k 2
context: trigram after 'coffee is'
  hot       76.2%  ##############################
  strong    23.8%  ##########
```

`hot` e `strong` tinham 59,3% e 18,5%. Somados dão 77,8%, e cada um é dividido por isso, então
`hot` vira 76,2% e `strong` 23,8%. Esse passo se chama **renormalizar**: as frações do que
sobreviveu são aumentadas até somarem 100% de novo, e a ordem entre elas não muda. `ready`, `cold`
e `bitter` não podem mais ser sorteadas.

Seis sorteios só podem cair nas duas que sobraram:

```
ana@lab:~/pe$ toylm generate "the coffee is" --top-k 2 --samples 6
[seed 1] hot.
[seed 2] strong.
[seed 3] hot.
[seed 4] hot.
[seed 5] hot.
[seed 6] strong.
```

Com k igual a 1, o top-k mantém uma palavra só, e isso é a decodificação gulosa por outro caminho:

```
ana@lab:~/pe$ toylm dist "the coffee is" --top-k 1
context: trigram after 'coffee is'
  hot      100.0%  ########################################
```

## O que o k não sabe

O número é fixo, e a lista que ele corta não é. Depois de `the coffee is`, manter 2 descarta três
palavras a que o modelo deu 22,2% somadas. Depois de `at seven` o modelo dá 100% ao ponto final, e
k = 2 mantém uma palavra porque só existe uma. No começo de uma frase, depois de `the`, há oito
candidatas:

```
ana@lab:~/pe$ toylm next "the"
context: trigram after '<s> the'
  coffee    29.9%  ############
  café      18.2%  #######
  bread     15.6%  ######
  cat       11.7%  #####
  tea       10.4%  ####
  cake       6.5%  ###
  soup       5.2%  ##
  menu       2.6%  #
```

Aqui k = 2 mantém `coffee` e `café`, 48,1% somadas, e joga fora mais da metade do que o modelo
considerou provável, `bread`, `cat` e `tea` incluídas.

**O top-k corta o mesmo número de palavras esteja o modelo seguro ou dividido.** Um k certo para um
contexto é apertado demais para o seguinte e frouxo demais para o outro. É esse o problema que a
próxima seção resolve.
