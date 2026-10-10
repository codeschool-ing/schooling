---
title: Correlação, causa e a frase honesta
version: 1
---

Um diagnóstico termina numa frase com um "porque", e essa palavra afirma mais do que a maioria dos
dados consegue mostrar. **Duas coisas que se mexem juntas são uma correlação. Uma fazendo a outra
acontecer é uma causa.** A distância entre as duas é onde a maioria dos diagnósticos confiantes erra,
e um analista de BI precisa reconhecê-la sem a estatística que a mede, que é a aula 18 de
`statistics`.

## Duas coisas que se mexem juntas

Eis uma correlação que os dados da Varanda mostram todo ano. Os meses em que a empresa mais gasta com
publicidade online, novembro e dezembro, são também os seus dois melhores meses de vendas. Ponha o
gasto e as vendas lado a lado e os dois sobem e descem juntos.

A leitura tentadora é que a publicidade causou as vendas, então mais publicidade em março faria março
parecer dezembro. **Os dados não conseguem dizer isso, porque uma outra coisa move os dois.** A
Varanda gasta mais em novembro e dezembro *porque* esses são os meses em que as pessoas compram
móveis e presentes; a estação aumenta as vendas e a estação aumenta a verba. Uma terceira coisa que
move as duas que você está comparando se chama **fator de confusão**, e a estação é o mais comum no
varejo. Se ela fosse retirada, a correlação entre gasto e vendas poderia encolher quase a nada, ou
não. O lado a lado não diz qual dos dois.

A mesma armadilha estava aberta em outubro. Na reunião de segunda, alguém culpou a chuva. Suponha
que outubro de 2025 tenha sido o mais chuvoso dos dois: então a chuva e a queda dos pedidos online se
mexeram juntas. Mas a chuva empurraria as pessoas das lojas para o site, e não o contrário, e as
lojas cresceram. A
campanha explicou a queda dia a dia; a chuva não explicou nada que a campanha já não tivesse
explicado.

## O que torna uma causa mais crível

Sem um experimento, um diagnóstico nunca prova uma causa. Ele a torna mais ou menos provável, e o que
a torna mais provável é o que a Lívia usou:

- o momento bate: os pedidos que faltam batem com os onze dias de campanha, e reaparecem em
  novembro, para onde a campanha foi;
- o lugar bate: a queda está no canal em que a campanha roda, e em nenhum outro;
- o mecanismo bate: menos pedidos com o mesmo tíquete é a cara de perder uma campanha, e uma mudança
  de preço ou um pipeline quebrado teriam outra cara;
- os outros suspeitos foram testados, e caíram.

Um experimento é a evidência mais forte: rodar a campanha para metade dos clientes e não para a outra
metade, e comparar. A aula 18 faz isso com um grupo de controle. Um diagnóstico de algo que já
aconteceu quase nunca tem um, e é por isso que a forma de dizer importa.

## A frase honesta

Compare duas versões da conclusão da Lívia:

| | a frase |
|---|---|
| afirma demais | "Outubro caiu porque a campanha foi para novembro." |
| honesta | "A queda de outubro está só nos pedidos online, com o tíquete igual, e bate com os onze dias de campanha de outubro de 2024; os dias comuns cresceram 12,4%. Conferimos calendário, preços, estoque e o pipeline de dados, e nada disso mudou. Outubro e novembro juntos cresceram 3,9%, abaixo dos 5,7% do ano, e essa diferença ainda não está explicada." |

A segunda é mais longa e é a que a Helena consegue usar. Ela diz **o que foi encontrado, com o que
isso é compatível, o que foi conferido e descartado, e o que continua em aberto**. "Compatível com"
não é cautela à toa. Diz ao leitor que a evidência se encaixa nessa causa e que ninguém fez um
experimento. E "conferimos" transforma uma lista de suspeitos numa lista de fatos. A aula 8 leva o
mesmo hábito para a frente no tempo: uma previsão, como um diagnóstico, precisa dizer o quanto é
segura.
