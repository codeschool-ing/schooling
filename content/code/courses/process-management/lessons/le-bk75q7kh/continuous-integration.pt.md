---
title: Integrando continuamente
version: 1
---

**Integração contínua** quer dizer que todo mundo no time junta o próprio trabalho na linha principal compartilhada pelo menos uma vez por dia, e que cada junção é compilada e testada automaticamente. Grady Booch usou a expressão em 1991; o XP a transformou em prática diária; o artigo de Martin Fowler sobre ela, publicado pela primeira vez em 2000, ainda é a referência habitual.

## O problema que ela resolve

Duas pessoas passam duas semanas cada uma num branch. Cada branch funciona. No dia em que juntam, os branches discordam sobre uma função que os dois mudaram, a junção leva um dia, e o código combinado falha em testes que passavam dos dois lados. O custo de integrar cresce com o tempo desde a última integração, e cresce mais rápido que linearmente, porque cada dia acrescenta mudanças que podem conflitar com as de todos os outros dias.

O remédio é deixar o intervalo pequeno. **Integre todo dia, ou várias vezes por dia**, e cada junção fica pequena o bastante para ser entendida. Um conflito que levaria um dia para desembaraçar depois de duas semanas leva dez minutos depois de duas horas.

## O que ela exige

Integração contínua é uma prática, não uma ferramenta. Um servidor que compila todo branch é uma ferramenta de CI; um time que mantém branches abertos por semanas não está fazendo integração contínua, tenha a ferramenta o nome que tiver. Quatro coisas precisam ser verdade:

- **Uma linha principal** em que todos juntam pelo menos uma vez por dia. Branches curtos, de um dia ou menos, são compatíveis com ela; branches de funcionalidade que vivem muito não são.
- **Compilação e testes automáticos** que rodam a cada junção, que é o que a prática do teste primeiro da seção anterior fornece.
- **Uma compilação rápida.** A segunda edição do XP a chama de *compilação de dez minutos*: se compilar e testar leva uma hora, as pessoas param de esperar, e código quebrado se acumula atrás de uma falha que ninguém viu.
- **Consertar a compilação quebrada vem primeiro.** Quando a linha principal falha, quem a quebrou conserta ou reverte a mudança, antes de qualquer pessoa fazer qualquer outra coisa. Uma linha principal que fica vermelha por um dia deixa de ser linha principal.

## Trabalho inacabado na linha principal

A objeção habitual é que uma funcionalidade leva duas semanas, então não dá para juntar todo dia. A resposta é juntar **inacabado, mas escondido**: atrás de uma feature flag que a mantém desligada para os usuários, ou construído de dentro para fora para que nada chame o código novo até ele estar pronto. Isso mantém a integração contínua sem expor meia funcionalidade. Também separa duas decisões que branches longos amarram: quando o código é juntado, que o time decide, e quando a funcionalidade é liberada, que o product owner decide.

## Por que ela está num curso de gestão

A integração contínua é a prática por trás de duas das medidas de entrega da aula 13: com que frequência um time faz deploy e quanto tempo uma mudança leva para chegar à produção. Um time que integra uma vez por quinzena não consegue fazer deploy diário, use o processo que usar. Quando uma parte interessada pergunta por que as liberações são lentas e arriscadas, a primeira pergunta a fazer é quanto tempo vivem os branches do time.
