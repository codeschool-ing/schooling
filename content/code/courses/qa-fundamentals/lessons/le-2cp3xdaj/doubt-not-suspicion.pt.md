---
title: Dúvida, não desconfiança
version: 1
---

**A mentalidade de quem testa costuma ser descrita como negativa: a pessoa que supõe que o software está
quebrado e o desenvolvedor foi descuidado.** Os times que contratam alguém assim aprendem rápido que não
funciona. Os desenvolvedores param de mostrar o trabalho cedo, os relatos viram discussões, e quem testa
passa os dias tendo razão sobre coisas que ninguém queria ouvir.

O que os bons têm é diferente, e tem um nome melhor: **dúvida sistemática**. Dúvida sobre afirmações, não
sobre pessoas.

## Todo "funciona" é uma afirmação

Quando o Rafael diz que a regra de preço funciona, ele está fazendo uma afirmação, e quase sempre honesta.
O que ele quer dizer, exatamente, é: *funcionou para as entradas que eu tentei, nas condições em que eu
tentei.* É uma afirmação mais estreita que "funciona", e o vão entre as duas é onde os defeitos moram. A
aula 1 achou um ali em dois comandos: o Rafael tinha tentado sessenta e um, e ninguém tinha tentado
sessenta.

Duvidar da afirmação não é duvidar do Rafael. A pergunta que quem testa faz nunca é "você errou?"; é
"**isso foi conferido contra o quê, e contra o que não foi?**" A primeira pergunta pede que alguém se
defenda. A segunda pergunta o que se sabe, e todo mundo pode ajudar a respondê-la.

## Por que quem construiu enxerga menos

Há um bom motivo para uma segunda pessoa achar defeitos que quem construiu deixou passar, e não é
habilidade. Os psicólogos chamam de **viés de confirmação**: depois que acreditamos em algo, procuramos
evidência que concorde e lemos a evidência ambígua como concordando. Um desenvolvedor que acabou de
escrever `age > 60` acredita que aquilo quer dizer "maiores de sessenta, como diz a regra", e as quatro
entradas que ele escolhe para experimentar são as que ele espera que passem, porque é isso que ele está
conferindo.

Quem testa é útil em parte porque não escreveu, e por isso ainda não acredita. **O valor está na
distância, não num olho superior**, e a mesma pessoa revisando o próprio plano de teste tem exatamente o
mesmo ponto cego. É também por isso que a dúvida precisa ser sistemática: um hábito aplicado a toda
afirmação, inclusive às suas, e não uma sensação de que algum código parece errado.

## O formato científico disso

Testar bem se parece muito com um experimento, e o vocabulário se transfere bem:

| | na ciência | no teste |
|---|---|---|
| **hipótese** | uma afirmação que pode se revelar falsa | "quem tem sessenta paga inteira" |
| **experimento** | algo que você faz cujo resultado pode refutá-la | rodar o preço para 59, 60 e 61 |
| **evidência** | o que o experimento produziu, registrado | os três preços, exatamente como impressos |
| **reprodução** | outra pessoa obtém o mesmo resultado do mesmo jeito | os dois comandos que o mostram, em qualquer máquina |

Uma hipótese precisa ser capaz de estar errada. "A loja tem um problema com idades" não pode ser refutada
por nenhuma execução, então não é uma. "Sessenta é tratado como menos de sessenta" pode ser refutada por um
único comando, e por isso pode ser testada. **Quanto mais precisa a hipótese, mais barato o experimento
que a decide.**

## O que esta aula faz

O resto da aula pega um relato vago da bilheteria, *uma família foi cobrada a mais no domingo de manhã*, e
o acompanha até dois comandos que qualquer um pode rodar para ver o defeito. Esse caminho, de uma
reclamação a uma reprodução, é a habilidade central do trabalho. Tudo nas aulas seguintes, das abordagens
de caixa à análise de causa raiz, é um refinamento dele.
