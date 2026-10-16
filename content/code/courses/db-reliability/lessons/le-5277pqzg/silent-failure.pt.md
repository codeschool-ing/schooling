---
title: O backup que deu certo e não guarda nada
version: 1
---

Aqui está o comando de backup mais comum da internet, com um erro de digitação. O banco se chama
`shop` e o comando diz `shpo`:

```
ana@vm:~$ pg_dump shpo | gzip > shop.sql.gz
pg_dump: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  database "shpo" does not exist
ana@vm:~$ echo $?
0
ana@vm:~$ ls -l shop.sql.gz
-rw-r--r-- 1 ana ana 20 Oct 10 03:23 shop.sql.gz
```

O `pg_dump` falhou, disse isso, e **o comando como um todo relatou sucesso**. O status de saída de um
pipeline do shell é o status do último programa, e o último programa era o `gzip`, que comprimiu
perfeitamente o que recebeu. Ele não recebeu nada. O resultado é um arquivo gzip válido de vinte
bytes, com a data de hoje, no lugar certo, com o nome certo.

Agora imagine essa linha numa rotina noturna escrita dois anos atrás. O banco foi renomeado na
primavera passada. O erro foi para um log que ninguém lê, o status da rotina foi para um dashboard
que mostra verde para código de saída zero, e o diretório de backup guarda uma fileira arrumada de
arquivos de vinte bytes, um por noite. Toda verificação que olha para a rotina passa. **A única
verificação que falha é uma restauração.**

## A correção no shell, e por que ela não é a correção de verdade

Dá para mandar o Bash falhar um pipeline quando qualquer programa nele falha:

```
ana@vm:~$ set -o pipefail
ana@vm:~$ pg_dump shpo | gzip > shop.sql.gz
pg_dump: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  database "shpo" does not exist
ana@vm:~$ echo $?
1
```

`set -o pipefail` vai no topo de todo script de backup que você escrever, junto com `set -e` e
`set -u`, e a lição 5 o coloca lá. Ele transforma esta falha em particular numa rotina vermelha.

Ele não transforma toda falha numa rotina vermelha, e esse é o ponto desta seção. Um dump pode
terminar com sucesso e ainda ser a coisa errada: o banco errado, um schema em cada três, um servidor
que era uma réplica e estava meses atrasado. O tamanho do arquivo é uma pista melhor que o código de
saída (vinte bytes, meio megabyte), e ainda é só uma pista. O que pega todas elas é o que a seção
anterior fez: **pôr os dados de volta e fazer a eles as perguntas que só os dados reais respondem.**

## O que uma rotina deveria verificar, no mínimo

Toda rotina de backup deste curso termina com três verificações, a mais barata primeiro:

1. **Todos os programas dela deram certo**, com `pipefail` e `set -e` para que uma falha pare a
   rotina.
2. **A saída é plausível**: existe, não é minúscula, e não é muito menor que a da noite anterior.
   Uma ferramenta pode fazer isso por você, e a da lição 5 faz.
3. **Ela foi restaurada em algum lugar e verificada**, com frequência suficiente para que uma falha
   seja encontrada enquanto a cópia boa anterior ainda existe. A lição 7 decide que frequência é
   essa.

As duas primeiras são monitoramento. Só a terceira é um backup.
