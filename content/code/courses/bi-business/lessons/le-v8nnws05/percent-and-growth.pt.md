---
title: Porcentagens e crescimento
version: 1
---

Quase toda comparação num relatório descritivo acaba virando porcentagem, e é nas porcentagens que
uma conta certa produz frases erradas. **Uma taxa de crescimento é uma razão, então tem um
denominador, e a maioria dos erros com crescimento é um denominador que ninguém olhou.** Quatro deles
aparecem na Varanda com frequência suficiente para aprender agora.

## Crescimento é o novo sobre o antigo, menos um

A fórmula da seção anterior é tudo: `(novo / antigo − 1) × 100`. A Varanda de 2025 contra 2024 é
98.000 ÷ 92.700 − 1, que dá 5,7%. **O valor antigo é o denominador, e ele decide o tamanho da
porcentagem.** Outubro caiu R$ 60 mil, que são 0,7% dos 8.020 de outubro de 2024. O ano cresceu
R$ 5.300 mil, que são 5,7% dos 92.700 de 2024. Um relatório que dá a variação em reais e não a base
sobre a qual ela é calculada deixa o leitor adivinhar qual dos dois casos é.

## A média dos meses não é o crescimento do ano

Tire a média das doze taxas anuais da coluna D:

```localised
=ARRED(MÉDIA(D2:D13);1)      5,6
```

**5,6, enquanto o ano cresceu 5,7.** Nenhum dos dois é erro de digitação. A média dá um voto a cada
mês, então os 6.510 de fevereiro contam tanto quanto os 12.240 de dezembro. O crescimento do ano pesa
cada mês pelo seu tamanho, porque é calculado sobre os totais. Dezembro cresceu 8,4% e é o maior mês,
então puxa o ano para cima mais do que puxa a média. Quando alguém pergunta quanto o ano cresceu, a
resposta é a dos totais. Uma média de taxas é outro número, e só está certa quando todos os meses têm
o mesmo tamanho.

## O crescimento se acumula

Se a Varanda crescesse 5,7% ao ano durante três anos, quanto maior ela estaria no fim? Não 3 × 5,7,
que dá 17,1. O crescimento de cada ano incide sobre uma base que o ano anterior já aumentou:

```localised
=ARRED((1,057^3-1)*100;1)      18,1
```

**18,1%, um ponto a mais que a soma.** Em três anos a diferença é pequena; em dez é grande, e é por
isso que a aula 16 mede o crescimento ao longo de anos com uma taxa que se acumula. A mesma conta
funciona no sentido contrário, e surpreende mais. Vendas que caem 10% num mês e sobem 10% no seguinte
não voltam para onde estavam:

```localised
=100*0,9*1,1      99
```

A alta foi de 10% sobre 90, não sobre 100. Um gerente de loja que diz "perdemos 10% e recuperamos"
perdeu 1% no caminho.

## Por cento e pontos percentuais

Dezembro foi 12,2% das vendas da Varanda em 2024 e 12,5% em 2025. Quanto cresceu a parcela de
dezembro? Há duas respostas certas, e são números diferentes:

```localised
=ARRED(C13/C14*100-B13/B14*100;1)      0,3
=ARRED((C13/C14)/(B13/B14)*100-100;1)      2,6
```

**A parcela subiu 0,3 ponto percentual, e subiu 2,6 por cento.** O primeiro é a diferença entre duas
porcentagens; o segundo é o crescimento de uma porcentagem sobre a outra. Os dois estão certos, e
escrever "a parcela de dezembro subiu 0,3%" está errado, porque 0,3 está em pontos, não em por cento.
A palavra decide em que número o leitor pensa, e quando a parcela é pequena a distância entre os dois
é grande. A aula 12 volta a isso com números escolhidos para enganar, que é onde a diferença faz
estrago de verdade.
