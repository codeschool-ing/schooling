---
title: Nove bits, e o único arquivo que precisava deles
version: 1
---

**Todo arquivo no Linux traz três conjuntos de permissões: para o dono, para o grupo e para todos os
outros.** Cada conjunto diz se aquela classe de usuário pode ler, gravar ou executar. São nove bits,
impressos pelo `ls -l` como `rwxrwxrwx`, e para a maioria dos arquivos são todo o controle de acesso
que existe. O resto desta aula trata de onde nove bits não bastam, mas primeiro um arquivo em que
bastavam e estavam errados.

Suba o laboratório com `sudo bash hostlab.sh up web`. A aula 1 anotou, ao montar o portal, um script
de backup que o root roda toda noite. Peça ao sistema de arquivos todo arquivo que qualquer um pode
gravar:

```
ana@web:~$ sudo find / -xdev -type f -perm -0002 2>/dev/null
/opt/portal/backup.sh
ana@web:~$ ls -l /opt/portal/backup.sh; cat /etc/cron.d/portal-backup
-rwxrwxrwx 1 root root 54 Oct 23 09:11 /opt/portal/backup.sh
30 2 * * * root /opt/portal/backup.sh
```

Um arquivo, e no pior lugar possível. O script é do root e roda como root às 02:30 toda noite pelo
`/etc/cron.d/portal-backup`, e os três últimos bits dele são `rwx`: **qualquer conta da máquina pode
mudar o que o root vai rodar hoje à noite.** Isso inclui o `portal`, a conta com que a aplicação web
roda, então uma falha no portal que deixasse alguém gravar um arquivo entregaria o root na manhã
seguinte. Pergunte ao sistema se o `portal` consegue mesmo, sem mudar nada:

```
ana@web:~$ sudo -u portal test -w /opt/portal/backup.sh && echo "portal may change a script root runs"
portal may change a script root runs
```

`test -w` responde se o usuário com que roda pode gravar o arquivo, e `sudo -u portal` o roda como
`portal`. A resposta é sim. A correção é a permissão que o arquivo deveria ter tido desde o começo:
dono root, gravável só pelo root.

```
ana@web:~$ sudo chown root:root /opt/portal/backup.sh && sudo chmod 755 /opt/portal/backup.sh && ls -l /opt/portal/backup.sh
-rwxr-xr-x 1 root root 54 Oct 23 09:11 /opt/portal/backup.sh
ana@web:~$ sudo -u portal test -w /opt/portal/backup.sh || echo "portal may not change it"
portal may not change it
```

## A regra por trás da correção

Um programa que roda com privilégio não pode ser gravável por ninguém com menos privilégio. O mesmo
vale para cada arquivo que esse programa lê para decidir o que fazer: os scripts em `/etc/cron.d`, o
arquivo de unidade de um serviço, a configuração do `sudo`, os diretórios em que eles moram. O `find`
acima é uma linha que vale rodar em toda máquina herdada, e a aula 18 o põe no inventário. Os primos
dele acham arquivos com o bit set-user-id, que rodam com o privilégio do dono seja quem for que os
inicie (`-perm -4000`), e diretórios que qualquer um pode gravar sem o sticky bit que o `/tmp` tem.

## Onde nove bits não bastam

Os bits de permissão citam exatamente um usuário e exatamente um grupo. Os documentos de clientes da
Jatobá precisam de mais: os contadores leem e gravam, uma auditora externa lê e nunca grava, e o
portal lê para deixar cada cliente baixar os seus. Três tipos de acesso a um diretório, e só uma vaga
de grupo para dar. A próxima seção mostra os bits falhando nisso, e a extensão que não falha.
