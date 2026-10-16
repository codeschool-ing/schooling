---
title: Os arquivos em que ninguém mexe à mão
version: 1
---

Tudo no diretório de dados pode ser lido, e quase nada nele pode ser mudado por outra coisa que não
o servidor. A lista abaixo é curta, e cada item dela é a noite ruim de alguém.

**Nunca apague arquivos do `pg_wal` para liberar espaço.** É a primeira coisa que as pessoas tentam
quando um disco enche, porque o diretório é grande e os nomes parecem logs. Não são logs no sentido
de algo que uma pessoa lê: o servidor precisa de todo segmento desde o último checkpoint para deixar
os arquivos de dados consistentes depois de uma queda, e uma réplica ou um arquivo de WAL podem
ainda precisar dos mais antigos. Apague o errado e o cluster pode não subir mais. A lição 7 diz por
que o diretório cresce, e a lição 24 escreve o runbook de um disco cheio que não começa com `rm`.

**Nunca apague nada em `pg_xact`, `pg_multixact` ou `global`** porque é pequeno e o propósito não é
claro. O `pg_xact` é o registro de quais transações fizeram commit; sem ele, toda linha de toda
tabela tem um estado desconhecido.

**Nunca copie o diretório de dados de um servidor rodando** e chame isso de backup. Os arquivos mudam
enquanto o `cp` os lê, e a cópia é uma mistura de momentos que nenhum servidor consegue entender. Uma
cópia feita com o servidor parado é consistente; um servidor rodando se copia com ferramentas feitas
para isso, e isso é a lição 3 de `db-reliability`.

**Nunca apague o `postmaster.pid` para fazer um servidor subir.** Se o servidor se recusa porque o
arquivo existe, ou ele está mesmo rodando — e dois servidores num diretório o destroem — ou o
processo antigo sumiu e o servidor já trata isso sozinho. A mensagem que ele imprime diz qual dos
dois.

**Nunca edite um arquivo em `base/`**, nem mova um. O catálogo registra qual arquivo é qual tabela;
um arquivo movido à mão é uma tabela que o servidor não acha, ou pior, uma que ele lê no lugar
errado.

**Nunca mude dono ou permissões dentro do diretório.** O servidor se recusa a subir se o diretório de
dados estiver aberto às outras contas da máquina, e essa recusa é a única coisa entre os dados e
todas as outras contas.

O que você pode fazer é tudo o que esta lição fez: listar, medir, ler o `PG_VERSION` e o
`postmaster.pid`, e perguntar ao servidor, com o `pg_relation_filepath` e as funções de tamanho,
qual arquivo é o quê. **Quando você quer que algo no diretório de dados mude, o pedido passa pelo
servidor**: SQL, `pg_ctlcluster`, ou uma das ferramentas que as próximas lições apresentam. É esse
hábito que mantém o diretório num estado em que o servidor pode confiar.
