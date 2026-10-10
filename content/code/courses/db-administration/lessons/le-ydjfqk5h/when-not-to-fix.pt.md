---
title: Quando deixar como está
version: 1
---

Uma tabela reconstruída parece uma vitória num gráfico de uso de disco, e para uma tabela atualizada
o dia todo é uma vitória que se desfaz sozinha. **Uma tabela com movimento constante se acomoda
num tamanho próprio**, maior que as suas linhas, e fica nele. O espaço livre é onde as atualizações
de cada dia caem. Tire-o, e as próximas atualizações vão ter de aumentar o arquivo de novo para
achar espaço.

A cópia compacta da seção anterior mostra isso. Atualize um quinto das linhas, rode o vacuum e
olhe; depois faça isso mais duas vezes, com um quinto diferente a cada vez:

@@1@@

A primeira rodada aumentou a tabela de 52 MB para 63 MB, porque uma tabela compacta não tem onde pôr
versões novas a não ser no fim. **A segunda rodada não a aumentou nada**: o VACUUM tinha liberado as
versões antigas da primeira rodada, e as versões novas da segunda foram para esse espaço. A terceira
também não. Esse é o formato de uma tabela saudável sob carga, e 63 MB é o tamanho de trabalho desta
tabela para este movimento. Reconstruí-la para 52 MB de novo recuperaria 11 MB até o próximo lote de
atualizações.

Os índices andaram mais, de 31 MB para 56 MB na primeira rodada, e ficaram a um megabyte disso. O
tamanho compacto deles depois de uma reconstrução só valeu até a primeira onda de atualizações.

Então a pergunta útil não é "quanto espaço livre existe", e sim **se o espaço livre é maior do que o
movimento algum dia vai usar**. Alguns casos em que é:

- uma operação única: um preenchimento, uma correção em massa ou uma limpeza de linhas antigas, como
  a atualização de todas as linhas no começo desta lição. O espaço que ela deixou não vai ser
  reaproveitado no ritmo em que foi criado;
- o disco está acabando e o espaço é necessário em outro lugar agora;
- as varreduras sequenciais da tabela são um problema, e o `pgstattuple` diz que a maior parte do
  que elas leem está vazio.

E alguns em que não é: uma tabela que volta ao mesmo tamanho poucos dias depois de uma reconstrução,
um percentual livre estável de semana para semana, uma tabela que ninguém varre por inteiro. Para
uma tabela com muitas atualizações dá até para pedir mais espaço livre de propósito. `ALTER TABLE
... SET (fillfactor = 90)` faz as inserções deixarem um décimo de cada página vazio, para que uma
atualização ache espaço na mesma página e possa ser HOT, sem nenhuma entrada nova de índice.

## Devolvendo o shop

A cópia e as duas extensões em `shop` eram para esta lição. O pacote continua instalado; não é
preciso removê-lo.

@@2@@
