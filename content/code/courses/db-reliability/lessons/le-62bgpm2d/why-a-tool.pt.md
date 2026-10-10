---
title: O que um script feito em casa deixa de fora
version: 1
---

As lições 3 e 4 montaram um backup com peças: `pg_basebackup` para os arquivos, `cp` no
`archive_command` para o log, e ainda nada para apagar qualquer um dos dois. Esse conjunto funciona,
e uma equipe que escreve o próprio script em volta dele costuma descobrir as peças que faltam um
incidente de cada vez. A lista é longa o bastante para que ninguém devesse escrevê-la de novo:

- **Retenção que entende dependências.** Apagar base backups antigos é fácil. Apagar os segmentos
  arquivados de que só esses backups precisavam, e nenhum de que um backup mais novo ainda precisa,
  é a parte que as pessoas erram, e o erro aparece meses depois, como uma recuperação que para numa
  lacuna.
- **Cópias só do que mudou.** Uma cópia completa de um banco de 2 TB toda noite são 2 TB de leitura
  e escrita toda noite. Um backup que copia só o que mudou desde o anterior é a maior parte da
  economia.
- **Compressão e paralelismo.** Tanto para os arquivos quanto para cada segmento arquivado.
- **Prova de que o arquivo chegou ao disco**, coisa que o `cp` nunca deu.
- **Verificação**: um checksum para cada arquivo na hora do backup, e um comando que relê o
  repositório inteiro e confere cada arquivo com ele.
- **Uma restauração que sabe onde está cada coisa**, inclusive quais segmentos buscar.

Várias ferramentas fazem isso para o PostgreSQL. O **pgBackRest** é a que este curso usa: está nos
pacotes do próprio Ubuntu, faz tudo o que está nessa lista, e há anos é a escolha padrão de muitas
equipes de PostgreSQL. O **Barman** é a outra comum, construída em torno de um servidor de backup
separado que puxa os dados do banco; o **WAL-G** é popular entre equipes que guardam tudo em object
storage. As ideias desta lição (tirando as stanzas, que são palavra do pgBackRest) valem para as
três, e as falhas também.

Uma coisa a ferramenta não muda: **o backup continua sendo só uma afirmação até ser restaurado.** O
pgBackRest torna as cópias melhores, mais rápidas e verificáveis. Ele não tem como saber se o banco
restaurado é o de que a aplicação precisa, e uma seção mais adiante nesta lição encontra um ponto em que até
a verificação dele precisa ser lida com cuidado.
