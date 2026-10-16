---
title: O que a regra não diz
version: 1
---

**Os testes caixa preta mais valiosos costumam ser os que o requisito não pediu.** As frases 2 e 3
descrevem, cada uma, um desconto. Nenhuma diz o que acontece quando os dois valem. A Lia rodou os três
clientes mais propensos a encontrar os dois: um estudante, uma criança e uma pessoa idosa, numa quarta.

```
lia@lab:~/aurora$ python tickets.py 20 yes wed 20:00
R$ 9,00
lia@lab:~/aurora$ python tickets.py 8 no wed 14:00
R$ 7,00
lia@lab:~/aurora$ python tickets.py 70 no wed 20:00
R$ 9,00
```

**R$ 9,00 para um estudante numa quarta à noite: um quarto do preço cheio.** O programa aplicou a meia da
quarta e depois a meia do estudante por cima. Uma criança numa matinê de quarta paga R$ 7,00, e uma pessoa
de setenta anos numa quarta à noite também paga R$ 9,00.

## Isso é um defeito?

Aqui o teste caixa preta chega ao limite do que consegue decidir sozinho. O resultado esperado para essa
entrada não está escrito em lugar nenhum. Duas leituras da regra são possíveis:

- **os descontos se somam:** meia pela quarta, meia de novo por ser estudante, R$ 9,00. O programa está
  certo;
- **meia é meia:** um ingresso é meia ou não é, e um estudante numa quarta paga R$ 18,00 como todo mundo
  nesse dia. O programa está errado.

A Lia não consegue decidir isso testando mais. Nenhuma execução diz a ela o que a Joana quis dizer, porque
a Joana nunca disse. O que ela pode fazer é o que a aula 2 chamou de entrega: **anotar como uma pergunta
para a dona do produto, com o caso que a levanta.**

> As frases 2 e 3 não dizem o que acontece quando as duas valem. Hoje um estudante numa quarta à noite
> paga R$ 9,00, um quarto do preço cheio (`python tickets.py 20 yes wed 20:00`). Isso é intencional?

A resposta da Joana veio na mesma tarde e encerrou o assunto: **meia é o maior desconto que um ingresso
recebe.** A Célia sempre vendeu assim, já que um ingresso a um quarto do preço não cobriria a parte da
distribuidora. A regra ganhou uma quinta frase, e o programa tinha um defeito que tinha desde o primeiro
dia, e que nenhum teste das quatro frases originais poderia ter achado.

## Por que a lacuna estava lá

O defeito não está no código, a rigor. O Rafael implementou exatamente o que estava escrito: dois
descontos, cada um aplicado quando sua condição vale. **O defeito está no que não foi escrito**, e passou
despercebido pelo mesmo motivo que o defeito das 9:30 na aula 4: nenhum teste exercitou a combinação,
porque nenhuma frase a descrevia.

Este é um dos hábitos mais produtivos do teste caixa preta. Para cada par de condições de uma regra,
pergunte o que acontece quando as duas valem. A regra do Cine Aurora tem três descontos, ser estudante, uma
idade e a quarta, e portanto três pares; o requisito não respondia nenhum. Os dois que envolvem a quarta
são os de cima. O terceiro, um estudante de sessenta e cinco anos, o programa por acaso cobra com uma
meia, o que concorda com a resposta da Joana; ninguém tinha decidido isso também, e concordar por sorte
não é o mesmo que ter sido testado.

## Uma ambiguidade vira um teste

Olhe a criança na matinê de quarta: R$ 7,00. Antes da resposta da Joana, esse número podia ser defendido
dos dois jeitos. Depois dela, é um defeito com resultado esperado, R$ 14,00, e uma reprodução de um
comando. **Uma pergunta respondida transforma uma ambiguidade num teste.** Esse é todo o caminho de uma
regra não escrita até um defeito que alguém consegue corrigir.
