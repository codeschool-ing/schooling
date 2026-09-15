---
title: Onde os doze bits acabam
version: 1
---

O modelo desta aula tem um limite duro, e ele é fácil de enunciar: **um arquivo tem um dono e um
grupo.** Então ele consegue dizer *a ana, e qualquer um do team, e todo o resto* — e não consegue
dizer *a ana e a carla, e mais ninguém*.

A resposta tradicional é criar um grupo para cada combinação, o que funciona até você ter quatro
pessoas e catorze grupos. Existem dois mecanismos acima dos doze bits, e eles resolvem problemas
diferentes.

## ACLs: nomes extras num arquivo

Uma **lista de controle de acesso** deixa um arquivo carregar permissões para usuários e grupos
nomeados, além das três linhas.

```
ana@vm:~/acl$ ls -l report.txt
-rw-r----- 1 ana ana 11 Sep 14 22:46 report.txt
ana@vm:~/acl$ getfacl report.txt
# file: report.txt
# owner: ana
# group: ana
user::rw-
group::r--
other::---
```

Sem ACL configurada, o `getfacl` imprime o modo comum noutra notação: `user::`, `group::` e
`other::` são as três linhas que você já conhece. Agora acrescente a carla:

```
ana@vm:~/acl$ setfacl -m u:carla:r report.txt
ana@vm:~/acl$ ls -l report.txt
-rw-r-----+ 1 ana ana 11 Sep 14 22:46 report.txt
ana@vm:~/acl$ getfacl report.txt
# file: report.txt
# owner: ana
# group: ana
user::rw-
user:carla:r--
group::r--
mask::r--
other::---
```

Duas coisas mudaram. Há uma linha nova, `user:carla:r--`. E o `ls -l` agora termina o modo com um
**`+`** — que é o único sinal, numa listagem comum, de que o arquivo tem ACL.

E funciona:

```
carla@vm:~$ cat /home/ana/acl/report.txt
the report
```

A carla não é dona, não está no grupo, e o `other` é `---`. Ela lê porque a ACL a nomeia.

`-m` modifica, `-x` remove uma entrada, `-b` remove todas:

```
ana@vm:~/acl$ setfacl -x u:carla report.txt
ana@vm:~/acl$ getfacl report.txt
# file: report.txt
# owner: ana
# group: ana
user::rw-
group::r--
mask::r--
other::---
```

### A linha `mask`, que é onde as pessoas se enrolam

`mask::r--` é um **teto** para toda entrada, exceto a do dono e a de `other`. Uma entrada concedendo
`rw-` sob uma máscara `r--` entrega `r--`. Não é bug; é como um arquivo com ACL continua se
comportando de forma sensata quando alguém roda `chmod` nele.

E essa é a armadilha: **`chmod g+w` num arquivo com ACL altera a máscara, e não a entrada do grupo.**
A linha do meio do `ls -l`, num arquivo com ACL, *é* a máscara, o que significa que a listagem comum
está te contando algo mais sutil do que parece. Leia o `getfacl` quando houver um `+`.

### Para que servem, e o que custam

| | |
|---|---|
| bom para | uma pessoa que precisa de acesso a uma árvore, sem criar grupo |
| | um servidor web que precisa ler um diretório de outra pessoa |
| | permissões padrão para um diretório inteiro — `setfacl -d` |
| custo | invisível no `ls -l`, exceto por um caractere |
| | o `cp` descarta, a menos que você diga `-p` ou `--preserve=all` |
| | o `tar` descarta, a menos que você diga `--acls` |
| | nem todo sistema de arquivos suporta |

**Esse terceiro custo é o que morde.** Um backup que perde as ACLs em silêncio parece bem até a hora
da restauração. Se uma árvore depende de ACLs, a ferramenta que a copia precisa ser avisada.

`setfacl -d -m g:team:rwx /srv/shared` define uma ACL *padrão* — permissões que arquivos novos
naquele diretório herdam. É a resposta das ACLs ao bit setgid da seção 63, e ela consegue mais,
porque consegue nomear indivíduos.

## SELinux e AppArmor: outra pergunta

Tudo até aqui é controle de acesso **discricionário** — *discricionário* porque quem decide é o
dono. A ana é dona do arquivo, então a ana escolhe quem lê.

O controle de acesso **obrigatório** senta acima disso, e o dono não vota. Uma política, escrita por
quem construiu o sistema, diz no que cada programa pode encostar. O processo do nginx pode ler
`/srv/www` e não pode ler `/home` — **nem como root**, e mesmo que os bits permitam.

| | |
|---|---|
| **SELinux** | Red Hat, Fedora, Rocky, Alma. Rótulos em cada arquivo e processo |
| **AppArmor** | Ubuntu, Debian, SUSE. Perfis presos a caminhos de programa |

O objetivo dos dois é contenção e não permissão: se um servidor web for comprometido, o atacante
tem o acesso de um servidor web e não o do root.

### Como saber se um deles está no seu caminho

Uma recusa que não faz sentido — os bits estão certos, o dono está certo, o `namei -l` está limpo, e
ainda falha — é a assinatura.

| | SELinux | AppArmor |
|---|---|---|
| está ligado? | `getenforce` | `sudo aa-status` |
| o que tem qual rótulo? | `ls -Z` | perfis em `/etc/apparmor.d/` |
| o que foi negado? | `sudo ausearch -m avc -ts recent` | `/var/log/syslog`, `dmesg` |
| rerrotular um arquivo | `restorecon -v caminho` | — |

Nesta máquina nenhum dos dois está rodando, e as ferramentas dizem isso sem rodeios:

```
root@vm:~# getenforce
bash: line 7: getenforce: command not found
root@vm:~# ls -Z /etc/hosts
? /etc/hosts
```

`command not found` quer dizer que o espaço de usuário do SELinux nem está instalado, e o `?` onde
o `ls -Z` imprimiria um rótulo quer dizer que o arquivo não carrega nenhum. **Vale saber conferir
isso rápido**, porque metade dos conselhos que você vai ler na internet supõe que um dos dois está
ligado.

### O que não fazer

O primeiro resultado de busca para uma recusa do SELinux é sempre `setenforce 0`. Funciona, no mesmo
sentido em que `chmod 777` funciona: a checagem acabou, junto com todas as outras que a política
estava fazendo.

O movimento certo é achar a recusa no log de auditoria, entender o que estava sendo pedido, e
consertar o rótulo ou acrescentar uma regra. O `audit2allow` até escreve a regra para você a partir
da entrada do log. No Ubuntu o equivalente é o `aa-complain` sobre aquele perfil específico, que
registra em vez de bloquear enquanto você descobre do que ele precisa.
