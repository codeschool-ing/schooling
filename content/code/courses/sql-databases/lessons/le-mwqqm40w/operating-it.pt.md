---
title: Quem roda isso, e com o quê
version: 1
---

A seção da aula 12 sobre operação fez quatro perguntas — onde mora a segunda cópia, o que significa
um backup, quanto custa uma atualização, e quem está de plantão. O Oracle responde às quatro, e a
resposta da quarta é diferente em espécie: **existe uma pessoa cujo trabalho é este, e não é você.**

## O administrador de banco é um papel, não uma escala

Num sistema PostgreSQL pequeno os desenvolvedores operam o banco entre eles. Um sistema Oracle
corporativo tem administradores de banco de dados: pessoas que guardam as credenciais, aplicam os
patches, rodam os backups, dimensionam o undo, e decidem o que é instalado.

Isso muda como um desenvolvedor trabalha, e a mudança não é uma restrição a contornar:

- **Você não vai ter `SYSDBA`**, e nem deve. A maior parte do que você precisa é um grant.
- **Mudanças de esquema passam por um processo.** Uma migração é um script que alguém revisa e
  roda, que é a disciplina da aula 11 com uma pessoa junto.
- **Os diagnósticos interessantes podem exigir uma licença ou um privilégio**, como a seção da
  licença disse, então o DBA é a primeira pergunta certa em vez do obstáculo.

A postura produtiva é chegar com um pedido específico e a evidência dele. "Esta instrução, este
plano, estas contagens de linha, e acho que precisa de um índice nesta coluna" é uma conversa. "O
banco está lento" não é.

## As ferramentas

**SQL\*Plus** é o cliente de linha de comando, e é o `psql` deste mundo com uma sensibilidade bem
mais antiga: tem comandos próprios para formatar saída, não confirma por você, e está presente em
todo servidor Oracle já instalado. Saber dele o bastante para conectar, rodar uma instrução e
despejar a saída num arquivo vale uma hora.

**SQL Developer** é o cliente gráfico gratuito da Oracle, e **TOAD** é o comercial de longa data.
Num ambiente corporativo você vai receber um dos dois.

**RMAN** é a ferramenta de backup. Ela faz os backups físicos, os incrementais e as restaurações, e
a regra da aula 12 se aplica a ela sem mudança: um backup que ninguém restaurou é um arquivo com um
nome esperançoso, e o ensaio de restauração é o único teste que existe.

**Data Guard** é o standby: um segundo banco mantido em dia a partir do fluxo de redo, para
failover. Ler dele enquanto ele aplica — que é o que você ia querer para relatórios — é o **Active
Data Guard**, uma opção licenciada à parte, que é a seção da licença aparecendo de novo numa decisão
de arquitetura.

**AWR e ASH** são o histórico de desempenho e o amostrador de sessões, e são o Diagnostics Pack.
Quando são licenciados, são genuinamente excelentes, e um relatório do AWR sobre a janela em que
algo esteve lento é o melhor primeiro artefato que existe. Quando não são licenciados, a pergunta
equivalente é respondida pelas views `V$` como sempre foi, e o `V$SQL` e o `V$SESSION` são por onde
começar.

## As views `V$`

O Oracle expõe seu estado interno como views, por convenção chamadas `V$ALGUMACOISA`, e elas são a
parte do sistema que um desenvolvedor curioso pode aprender com proveito. O `V$SQL` guarda as
instruções no shared pool com as contagens de execução e os tempos decorridos, que é o
`pg_stat_statements` da aula 10 com outro nome; o `V$SESSION` mostra quem está conectado e no que
está esperando; o `V$LOCK` mostra as travas.

**Quais destas você pode consultar é uma questão de grants, e as mais profundas, de licença.**
Pergunte antes de construir um hábito sobre uma.

## Atualizações

Atualizações de versão maior são projetos e não tarefas: uma certificação de versão para cada
aplicação que conecta, um ambiente de teste, um ensaio, e uma janela. É parte do motivo de a 19c
estar tão implantada — foi o lançamento de suporte longo, e uma organização que chegou nela tinha um
lugar defensável para parar.

A consequência visível ao desenvolvedor é a que a aula 12 nomeou: **a versão na sua frente decide o
que existe.** `FETCH FIRST n ROWS ONLY` precisa da 12c, colunas de identidade precisam da 12c, um
booleano nativo no SQL precisa da linha 23ai. O conselho que se acha online sobre Oracle atravessa
vinte e cinco anos de lançamentos e muitas vezes não diz sobre qual deles é.
