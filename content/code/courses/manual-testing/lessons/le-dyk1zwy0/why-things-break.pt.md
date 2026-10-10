---
title: Por que o que funcionava para de funcionar
version: 1
---

Uma mudança num programa costuma ser imaginada como local: o desenvolvedor edita as linhas que
estavam erradas, essas linhas agora estão certas, e o resto do programa continua como estava. **Se
isso fosse verdade, conferir a correção seria todo o teste de uma versão**, e a verificação de
sanidade da aula 9 sobre o boxoffice 1.1 teria bastado. Não é verdade com frequência suficiente para
confiar nisso, e o defeito que daí nasce tem nome próprio.

Uma **regressão** é um defeito em algo que funcionava, trazido por uma mudança. O **teste de
regressão** roda de novo os testes do que já funcionava, na versão nova, para encontrar esses
defeitos. Não é o reteste da aula 9, que roda o único caso que falhou antes; ele roda os casos que
passaram antes, esperando que passem de novo.

## Quatro jeitos de uma mudança ir além das suas linhas

**Código compartilhado.** Uma função atende várias funcionalidades, e uma edição feita para quem a
chama de um lado muda o que todos os outros recebem. No boxoffice, `discount` decide o preço de todo
pedido que o teatro vende: sócios, pedidos grandes, estudantes, todo mundo. O defeito da aula 5 era
sobre uma combinação, um sócio reservando cinco ou mais, e a correção entrou na função por onde
todas as outras passam.

**Uma reescrita em vez de um remendo.** Um remendo muda uma linha e deixa o resto em paz. Uma
reescrita diz tudo de novo do zero, e precisa reafirmar cada caso que o código antigo tratava,
inclusive os que ninguém lembra de ter pedido. As notas do Rui dizem que `discount` foi reescrita.
Nada nisso é errado em si, e é exatamente o tipo de mudança depois da qual um testador confere todo
caso que a versão antiga tratava.

**Suposições em outro lugar.** Outras partes de um programa foram construídas em volta de como a
parte mudada se comportava. Antes da 1.1, o máximo que um pedido podia tirar de um espetáculo era
cinco lugares; agora são seis. A contagem de lugares nunca tinha visto um pedido de seis antes desta
versão, e nada nas notas do Rui diz que alguém olhou para ela. Na maioria das vezes uma suposição
assim se sustenta; a suíte de regressão é onde alguém confere que se sustentou.

**Nada no programa mudou.** Uma versão nova do Python, uma atualização do navegador, outro sistema
operacional ou outro servidor podem quebrar um programa em que ninguém mexeu. Também são regressões,
porque algo funcionava e parou, e a aula 21 trata dos ambientes que as causam.

E mais uma, comum o bastante para ter nome: **um defeito antigo volta.** Um desenvolvedor trabalha
numa cópia de um arquivo feita antes da correção, ou desfaz uma mudança para resolver outro
problema, e a correção vai embora junto, em silêncio. É por isso que o reteste de todo defeito
corrigido entra na suíte de regressão assim que passa, que é o que a seção 05 desta aula faz para a
1.1.

## Uma regressão precisa de um antes

Quando um caso falha numa versão nova, três coisas diferentes podem estar acontecendo, e elas são
relatadas de jeitos diferentes:

| o caso | na última versão | nesta versão | o que é |
|---|---|---|---|
| testa algo que já existia | passou | falha | uma **regressão** |
| testa algo que já existia | falhou, e foi relatado | falha | um defeito conhecido, ainda aberto |
| testa algo novo nesta versão | não existia | falha | um defeito novo, não uma regressão |

A primeira linha é aquela para a qual o teste de regressão existe, e a palavra diz do que ela
precisa: um resultado anterior. "Falha agora" é uma constatação; "passava na 1.0 e falha na 1.1" é
uma regressão, e a diferença muda a urgência e quem olha primeiro, porque algo de que os clientes
dependiam acabou de ser tirado. Então uma afirmação de regressão é conferida contra a versão
anterior quando ela ainda existe, e é por isso que a aula 9 pediu que você guardasse o
`boxoffice-1.0.py`.

A segunda linha importa tanto quanto na prática. As notas do Rui listam dois defeitos como
conhecidos e não corrigidos: a página de erro para um campo de ingressos que não é número, e um
pedido usado que ainda pode ser reembolsado. Uma rodada de regressão na 1.1 encontra os dois de novo
e eles falham de novo. **Uma falha conhecida é um resultado a registrar, e não um defeito a relatar
pela segunda vez**: o relatório já existe, e um segundo custa a alguém uma hora para descobrir que é
o primeiro.

A seção 03 desta aula decide que casos rodar na 1.1, e a seção 04 os roda.
