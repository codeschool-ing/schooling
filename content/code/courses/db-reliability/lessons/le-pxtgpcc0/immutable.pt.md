---
title: Uma cópia que ninguém consegue apagar, e quem esse ninguém inclui
version: 1
---

A criptografia decide quem consegue ler um backup. Ela não faz nada sobre quem consegue **apagar** um,
e apagar é a primeira coisa que o atacante da lição 10 faz: um backup que pode ser removido pela mesma
pessoa, programa ou credencial roubada que consegue danificar o banco é um backup que desaparece junto
com ele.

Uma cópia **imutável** é uma que não pode ser alterada nem apagada, por ninguém, até uma data. No
Linux, um sistema de arquivos consegue marcar arquivos assim com `chattr +i`; torne imutável o backup
full offsite e depois tente apagar parte dele, primeiro à mão e depois pelo pgBackRest, depois de
fazer um full mais novo para que a retenção permita que o mais antigo vá embora:

```
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main --repo=2 backup --type=full
ana@vm:~$ sudo chattr -R +i /srv/offsite/pgbackrest/backup/main/20261015-214449F
ana@vm:~$ sudo lsattr -d /srv/offsite/pgbackrest/backup/main/20261015-214449F
----i---------e------- /srv/offsite/pgbackrest/backup/main/20261015-214449F
ana@vm:~$ sudo rm /srv/offsite/pgbackrest/backup/main/20261015-214449F/backup.manifest
rm: cannot remove '/srv/offsite/pgbackrest/backup/main/20261015-214449F/backup.manifest': Operation not permitted
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main --repo=2 expire --set=20261015-214449F
ERROR: [060]: repo2: unable to remove '/srv/offsite/pgbackrest/backup/main/20261015-214449F/backup.manifest': [1] Operation not permitted
ERROR: [104]: expire command encountered 1 error(s), check the log file for details
```

O `lsattr` mostra a flag `i`. O root não conseguiu remover um único arquivo, e **o próprio `expire`
do pgBackRest falhou no mesmo arquivo**. Essa segunda recusa é o ponto: a retenção, um script com um
bug e um atacante que tomou a conta `postgres` apagam todos pelo mesmo mecanismo, e a flag barra os
três.

O que também significa que a flag tem que combinar com a retenção. Um backup marcado como imutável
por mais tempo do que a retenção o mantém faz o `expire` falhar toda noite, e uma rotina noturna que
falha toda noite é uma que ninguém lê. A imutabilidade é definida por um período, e esse período é
escolhido junto com o `repo2-retention-full`.

## O limite de fazer isso na mesma máquina

```
ana@vm:~$ sudo chattr -R -i /srv/offsite/pgbackrest/backup/main/20261015-214449F
ana@vm:~$ sudo lsattr -d /srv/offsite/pgbackrest/backup/main/20261015-214449F
--------------e------- /srv/offsite/pgbackrest/backup/main/20261015-214449F
```

O root tirou a flag com a mesma facilidade com que a pôs. Numa máquina só, o `chattr +i` protege
contra **erros**: um caminho errado numa limpeza, um script apagando o diretório errado, um `expire`
com o argumento errado. Ele não protege contra alguém que tem root nessa máquina, e alguém que invadiu
o servidor do banco muitas vezes é exatamente isso.

A imutabilidade de verdade fica **onde as credenciais do atacante não chegam**:

- **Object storage com trava de retenção.** O Object Lock do S3 em modo compliance, e os equivalentes
  em outros provedores, se recusam a apagar ou sobrescrever um objeto antes da data de retenção dele,
  sejam quais forem as credenciais usadas, incluindo o administrador da própria conta. O pgBackRest
  escreve num bucket desses como em qualquer outro, e a trava é definida no bucket, por outra pessoa,
  uma vez.
- **Mídia fisicamente offline**: uma fita ou um disco tirado da máquina e posto numa prateleira. Lenta
  para restaurar, e nenhum ataque pela rede chega até ela.
- **Um servidor de backup em que o servidor do banco não consegue entrar**, que é o assunto da
  próxima seção.

Este laboratório não tem nem um bucket com object lock nem uma fita, então eles são descritos aqui em
vez de digitados. O teste de cada um é o mesmo que esta seção fez: tente apagar com a credencial mais
forte que você tem, e espere falhar.
