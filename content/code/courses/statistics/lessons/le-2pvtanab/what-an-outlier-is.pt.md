---
title: Três tipos de valor atípico
version: 1
---

Um **valor atípico**, ou outlier, é uma observação que fica anormalmente longe das outras. A definição é
vaga de propósito, porque "anormalmente longe" depende dos dados, e o resto desta aula trata de torná-la
precisa. O que importa primeiro é que um valor atípico é uma **pergunta**, não um veredito. Ele pergunta:
por que este valor está aqui?

Há três respostas comuns, e elas pedem três reações diferentes.

## Um erro

O valor não descreve nada real. Uma vírgula escorregou e R$ 212,60 virou R$ 2.126,00. Um tempo de entrega
foi registrado em segundos em vez de minutos. Um pedido de teste de R$ 0,01, feito por um desenvolvedor
conferindo a página de pagamento, foi parar na tabela de vendas.

Erros são o caso fácil, em princípio: devem ser **corrigidos**, e, se o valor verdadeiro não puder ser
recuperado, removidos. Na prática, a dificuldade é provar que é um erro. R$ 2.126,00 pode ser um erro de
digitação ou um pedido real, e o número sozinho não diz qual.

## Um visitante de outra população

O valor é real, mas pertence a um grupo diferente do que está sendo estudado. A Horta vende para casas. Num
mês, um restaurante pede 80 kg de tomate e uma caixa de óleo: um pedido real, registrado corretamente, de
um cliente que não é o tipo de cliente de que a análise trata.

Visitantes em geral devem ser **analisados separadamente**. Misturar as compras de um restaurante com as
das casas distorceria o quanto uma casa típica gasta, e deixá-las de fora por completo perderia o fato de
que restaurantes estão comprando. Separá-los muitas vezes é a coisa mais útil que um valor atípico revela:
a aula 7 disse o mesmo sobre dois picos.

## Um extremo genuíno

O valor é real e pertence à mesma população. Uma família fazendo a compra de fim de ano gasta R$ 421,78.
Uma entrega numa noite de chuva, com catorze itens, leva 45,5 minutos num bairro onde 30 é o normal.

Extremos genuínos devem ser **mantidos**. Fazem parte da população, e qualquer descrição honesta da
população os inclui. A aula 4 mostrou o que acontece com um orçamento de folha que deixa o fundador de
fora: ele volta.

## A ordem das perguntas

O hábito útil é fazer as perguntas em ordem. Isto pode ser um erro? Confira a origem. Se é real, pertence
à população que estou descrevendo? Se pertence, fica. A maior parte do trabalho está na conferência, e as
próximas seções dão as ferramentas para achar os candidatos a conferir.
