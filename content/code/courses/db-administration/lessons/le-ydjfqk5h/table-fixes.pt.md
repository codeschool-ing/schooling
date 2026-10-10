---
title: Duas formas de devolver o espaço, e a trava que cada uma toma
version: 1
---

Recuperar o espaço é escrever as linhas vivas num arquivo novo e compacto e jogar o antigo fora. As
duas ferramentas aqui fazem isso. **A diferença é quem consegue usar a tabela enquanto acontece.**

## VACUUM FULL

O `VACUUM FULL` copia as linhas vivas para um arquivo novo, reconstrói todos os índices nele e troca
os arquivos. Faz parte do PostgreSQL e não precisa de nada instalado. Ele mantém uma trava `ACCESS
EXCLUSIVE` na tabela do começo ao fim, e essa trava conflita com tudo, inclusive um `SELECT` simples.

Três terminais mostram isso. O primeiro roda a reconstrução:

@@1@@

Enquanto ela rodava, um segundo terminal tentou contar as linhas:

@@2@@

Uma contagem que normalmente leva uma fração de segundo esperou até a reconstrução terminar. Um
terceiro terminal, olhando o `pg_locks` no meio dela, viu por quê:

@@3@@

**`granted` é a coluna para ler.** O `VACUUM FULL` tem `AccessExclusiveLock`, concedida; o `SELECT`
pediu `AccessShareLock`, a trava mais fraca que existe, e não a recebeu. As duas linhas de
`ShareLock` pertencem às construções de índice dentro da reconstrução, uma delas num worker paralelo
com processo próprio. Numa aplicação, toda consulta que toca a tabela se empilha atrás da primeira
exatamente como aquela contagem, pelo tempo que a reconstrução durar. Na cópia foram segundos. Numa
tabela de 200 GB é tempo suficiente para ser uma indisponibilidade.

De volta ao primeiro terminal, quando ela terminou:

@@4@@

A tabela foi de 117 MB para 52 MB e os índices de 75 MB para 31 MB. É o bloat inteiro, devolvido ao
sistema operacional. **Conte com espaço para as duas cópias enquanto ele roda**: os arquivos novos
são escritos antes de os antigos serem removidos, então um disco cheio por causa de bloat talvez
não tenha espaço para corrigi-lo desta forma.

## pg_repack

O `pg_repack` é uma extensão e um programa de linha de comando, mantido fora do PostgreSQL e
empacotado pelo Ubuntu para cada versão maior. Ele faz a mesma reescrita e **mantém a trava
exclusiva só por um instante no começo e no fim**. No meio, copia as linhas para uma tabela nova
enquanto um trigger registra cada alteração que a aplicação faz, e depois reaplica essas alterações
antes da troca.

Infle a cópia de novo do mesmo jeito e depois instale-o. O pacote vem do repositório do Ubuntu e a
extensão vai para o banco que guarda a tabela:

@@5@@

@@6@@

@@7@@

Depois rode-o pelo shell, como superusuário ou como o papel dono da tabela:

@@8@@

Enquanto ele copiava, outro terminal olhou as travas e depois alterou uma linha:

@@9@@

O `pg_repack` tem `AccessShareLock`, a mesma trava que um `SELECT` toma, então leituras e escritas
continuam. O `SIReadLock` está ali porque ele copia no nível de isolamento `SERIALIZABLE`, para ter
um snapshot consistente. **O `UPDATE` passou direto** e o trigger o levou para a tabela nova. De
volta ao shell, o resultado é o mesmo do `VACUUM FULL`:

@@10@@

Três condições vêm junto. **A tabela precisa de uma chave primária** ou de um índice único em
colunas não nulas, porque a reaplicação encontra as linhas por ele; o `pg_repack` recusa uma tabela
sem isso. Ele precisa da mesma folga de espaço que o `VACUUM FULL`, pelo mesmo motivo. E as travas
exclusivas breves de cada ponta ainda precisam ser concedidas, então uma transação longa segurando a
tabela faz o `pg_repack` esperar na troca, e toda consulta que chega depois dele espera também. Por
padrão ele espera 60 segundos e então cancela as consultas no caminho; `--no-kill-backend` o faz
desistir em vez disso. A lição 22 mostra essa fila em detalhe.

A extensão no banco precisa bater com a versão do programa. Depois de uma atualização do pacote,
`DROP EXTENSION pg_repack; CREATE EXTENSION pg_repack;` os põe de acordo de novo, e a lição 20
reencontra a extensão no caminho para uma nova versão maior.
