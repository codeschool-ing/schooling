---
title: TestRail e qTest, dois gerenciadores de casos comerciais
version: 1
---

**TestRail e qTest são gerenciadores de casos dedicados: aplicações web cujo assunto inteiro são
casos, execuções e resultados, vendidas por assinatura, que ficam ao lado de um rastreador de
defeitos e não dentro dele.** Um time que usa qualquer um dos dois guarda histórias e defeitos no
rastreador da aula 17 e casos e execuções aqui, e os dois são ligados para que um resultado que
falhou aponte para um defeito e vice-versa. Este curso não rodou nenhum dos dois. O que vem a
seguir descreve que tipo de ferramenta cada um é e as palavras que cada um usa, que é o que você
precisa para se achar em um deles no primeiro dia.

## TestRail

O TestRail organiza o repositório em **suítes** divididas em **seções**, e cada caso mora numa
seção. Um **test run** é uma seleção de casos contra uma versão, e cada caso nele recebe um
resultado conforme o testador avança. Um **test plan** agrupa várias execuções que andam juntas, e
o motivo comum são as configurações: um plano para uma versão, com uma execução por navegador, é a
forma que a matriz de compatibilidade da aula 7 toma dentro de uma ferramenta. Os **milestones**
amarram execuções e planos a uma data de entrega, então a pergunta "quanto da 1.1 já
percorremos?" tem uma página que responde.

Duas coisas nele importam mais que o vocabulário. Ele se integra aos rastreadores que os times já
usam, o Jira entre eles, então quem marca um caso como falhou pode abrir o defeito na mesma tela e o
resultado guarda o vínculo. E ele tem uma API, então resultados de testes automatizados podem cair
nas mesmas execuções que os manuais. É assim que um time com metade da regressão automatizada ainda
tem uma resposta só para "a 1.1 passou?", e não duas.

Ele é oferecido como serviço hospedado e como software que a empresa roda nos próprios servidores.

## qTest

O qTest pertence à Tricentis, uma empresa que vende uma família de produtos de teste, e o qTest é a
parte dessa família que gerencia casos e execuções. Suas telas seguem o caminho de uma versão:
**requisitos**, que muitas vezes vêm do Jira em vez de serem escritos duas vezes; **desenho de
teste**, onde os casos são escritos e agrupados em módulos; e **execução de teste**, onde as versões
contêm **ciclos de teste**, e os ciclos contêm os **test runs** que carregam os resultados.

A diferença em relação ao TestRail que um testador nota primeiro é o quanto do trabalho gira em
torno do requisito. Como os requisitos estão na ferramenta, a cobertura é uma visão, e não um
relatório que alguém monta: que requisitos têm casos, que casos rodaram neste ciclo, quais
falharam. Ele foi feito para organizações que testam muitos produtos com muitos times, onde essa
visão é o que os gestores pedem toda semana.

## O que os dois têm em comum, e o que procurar

Os dois mantêm separadas as quatro coisas da seção 01: o repositório, as execuções, o histórico, os
vínculos. Os dois têm os mesmos quatro status, com nomes próprios e com extras que cada time pode
acrescentar. E os dois transformam os resultados em gráficos: progresso de uma execução, resultados
por status, defeitos por requisito.

**Nenhum dos dois deixa um caso melhor que o texto que o testador escreve nele.** O trabalho que
você faz em um deles é o trabalho das aulas 2 a 5: escrever um caso que um estranho consegue rodar,
escolher os valores nas fronteiras, citar o requisito. O que muda em relação a uma planilha é que a
execução, o resultado e o vínculo com o defeito são registrados do mesmo jeito por todo mundo, e é
daí que vêm os números da aula 19.

Escolher entre os dois raramente é uma questão de funcionalidades. Uma empresa escolhe o que combina
com o rastreador que já tem, com onde aceita hospedar seus dados e com quanto custa, coisa que este
curso não compara porque muda.
