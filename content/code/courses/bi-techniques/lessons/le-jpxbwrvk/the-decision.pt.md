---
title: A decisão, e os motivos dela
version: 1
---

O plano da aula 7 dizia: lançar se a conversão subir de forma significativa a 5 por cento e nenhuma
métrica de proteção ficar claramente pior. Nas três semanas, a conversão subiu com p = 0,032. Lida
mecanicamente, a decisão está tomada.

As outras duas leituras a complicam, e um bom relatório diz isso em vez de esconder.

- **O intervalo** diz que a alta duradoura pode estar em qualquer lugar entre quase nada e 0,76
  ponto.
- **O padrão semanal** da aula 9 diz que a maior parte da alta veio na primeira semana, e as duas
  últimas semanas sozinhas mostram +0,07 ponto, não significativo, com um intervalo de −0,36 a +0,51.

Então a decisão defensável é **seguir o plano e lançar, dizendo que o efeito duradouro provavelmente
é menor que o número das três semanas**, e continuar medindo a conversão depois do lançamento contra a
previsão do que ela teria sido sem a mudança. As aulas 1 a 6 são exatamente as ferramentas para essa
previsão. Mudar a regra depois de ver o dado, em qualquer direção, seria o erro: declarar derrota
porque as últimas semanas parecem planas é tão decisão posterior quanto declarar uma vitória maior
porque a semana 1 parece ótima.

O que o relatório diz, em quatro linhas:

> O checkout de um passo subiu a conversão de primeiro pedido de 4,28% para 4,67% em três semanas
> (+0,40 ponto, intervalo de 95% de +0,03 a +0,76, p = 0,032). A divisão e as métricas de proteção
> estavam limpas. A maior parte da alta veio na primeira semana; nas semanas 2 e 3 a diferença foi de
> +0,07 ponto (−0,36 a +0,51). Vamos lançar como planejado e acompanhar a conversão contra a previsão
> por oito semanas.

**Todo número está lá, toda dúvida tem nome, e a decisão segue a regra escrita antes do teste.** É
isso que ler um resultado quer dizer.

## A verdade, desta vez

O `panela.py` montou o teste: a página nova soma 0,4 ponto para sempre, mais um bônus de novidade que
começa em 1,2 ponto e cai cerca de dois terços a cada três dias. Então o efeito duradouro é de fato
0,4 ponto, dentro dos dois intervalos. A estimativa das três semanas, 0,40, por acaso bate com ele,
puxada para cima pela novidade e para baixo pelo ruído; a estimativa das duas semanas, 0,07, foi
puxada para baixo pelo ruído. Nenhum leitor tinha como saber qual, e é por isso que se relatam
intervalos e que o plano era medir depois do lançamento.
