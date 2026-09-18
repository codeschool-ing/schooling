---
title: Leituras, transações, e um erro que você vai encontrar
version: 1
---

A aula 8 construiu o vocabulário: as anomalias, os níveis de isolamento, o que uma transação
promete. O Oracle implementa esse vocabulário com algumas diferenças reais, e uma delas produz uma
mensagem de erro específica o bastante para valer reconhecer de cara.

## Não existe read uncommitted, e nunca existiu

O Oracle oferece **read committed**, que é o padrão, e **serializable**. Ele não oferece read
uncommitted de jeito nenhum, e não poderia: um leitor nunca enxerga o trabalho não confirmado de
outra transação, por causa de como as leituras são servidas.

Toda mudança é escrita numa área de **undo** antes de o bloco ser modificado, então a versão
anterior de uma linha está sempre disponível. Uma consulta que começa num dado momento lê os dados
**como eles estavam naquele momento**, reconstruindo versões antigas a partir do undo onde um bloco
já avançou. O Oracle chama isso de consistência de leitura, e a garantia prática é a que a aula 8
queria:

> **Um leitor nunca bloqueia um escritor e um escritor nunca bloqueia um leitor.** Um relatório
> longo enxerga um retrato consistente do banco de quando começou, por mais que mude por baixo dele.

O PostgreSQL chega à mesma garantia por outro caminho — ele guarda versões antigas de linha na
própria tabela e o `VACUUM` as remove — e o InnoDB do MySQL usa um log de undo bem como o Oracle. O
comportamento que um desenvolvedor vê é o mesmo nos três.

## `ORA-01555: snapshot too old`

Este é o erro que o undo produz, e reconhecê-lo poupa uma tarde.

Um relatório roda por duas horas. As leituras dele estão sendo servidas como de quando ele começou,
a partir do undo. O undo é um espaço finito que está sendo reciclado por tudo o mais que o sistema
faz. Se a versão de que uma consulta longa precisa já foi sobrescrita, o Oracle não consegue montar
a resposta que prometeu — **e ele recusa em vez de devolver uma errada.** Essa recusa é o
`ORA-01555`.

A mensagem diz, em substância, que um snapshot é velho demais e que os dados de segmento de
rollback de um dado número não estão mais disponíveis. É uma mensagem documentada e não uma
capturada aqui, e a forma é o que reconhecer: **uma consulta longa que falha no meio, com um número
dentro.**

Três coisas decorrem disso, e a primeira é a útil:

**Não é um bug na consulta.** A consulta estava correta e o sistema não conseguiu cumprir sua
promessa. Uma reescrita que deixe a consulta mais rápida resolve; repetir também pode funcionar,
num sistema mais calmo.

**É um problema de dimensionamento de quem roda o banco.** Mais undo, ou uma retenção mais longa.
Isso é do DBA mudar e vale reportar a ele com a instrução e a hora em que começou.

**É um argumento contra transações muito longas**, que é o argumento que a aula 8 já fez por outro
motivo. Um relatório que lê por duas horas está exposto a isso; o mesmo relatório dividido por mês
não está.

## O DDL confirma, como no MySQL

A aula 12 capturou o MySQL mantendo uma coluna que tinha sido acrescentada dentro de uma transação
revertida. O Oracle se comporta do mesmo jeito: **`CREATE`, `ALTER`, `DROP` e `TRUNCATE` emitem um
commit implícito antes e depois de si mesmos.** Uma transação em andamento quando você roda um
deles é confirmada, inclusive a parte sobre a qual você ainda não tinha decidido.

Então a regra de migração da aula 11 é a regra do Oracle também: **um passo reversível por vez, e
uma ferramenta que saiba retomar**, porque um script de seis `ALTER TABLE` que falha no quarto já
aplicou três.

## Travas, e a única coisa a anotar

Travas de linha são mantidas até o commit ou o rollback, como em todo o resto deste curso, e um
escritor bloqueia um escritor na mesma linha. `SELECT … FOR UPDATE` toma a trava explicitamente, o
que o procedimento da seção anterior fez. `FOR UPDATE NOWAIT` falha na hora em vez de esperar, e
isso é muitas vezes o que uma tela quer: um usuário a quem se diz "outra pessoa está editando isto"
é melhor servido que um olhando para um indicador de carregamento.

Deadlocks são detectados e uma transação é escolhida e revertida com `ORA-00060`. **A regra da aula
8 não muda: tome travas numa ordem consistente, e esteja pronto para repetir.**

## Uma surpresa em forma de transação

**O Oracle não tem autocommit no servidor.** Toda instrução abre uma transação e ela fica aberta
até um `COMMIT` ou um `ROLLBACK`. Os clientes diferem em mandar ou não um commit por você — o
SQL\*Plus não manda por padrão, e muitos drivers mandam — então uma sessão deixada com um `UPDATE`
não confirmado segura as travas de linha dela até alguém notar.

Essa é a origem de um chamado de suporte clássico: uma aplicação trava, o DBA acha que ela está
esperando numa trava, e a trava é de um colega que rodou um `UPDATE` numa janela de cliente antes
do almoço e não confirmou. O hábito que vale ter no Oracle é **terminar o que você começou numa
janela de cliente**, toda vez, com um `COMMIT` ou um `ROLLBACK`.
