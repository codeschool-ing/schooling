---
title: A hierarquia, diretório por diretório
version: 1
---

A seção 13 te deu oito nomes para você parar de se sentir perdido. Este é o mapa inteiro, e o
objetivo dele não é decorar — é que **a forma é padronizada**, então um diretório que você nunca
viu, numa distribuição que você nunca usou, ainda assim te diz o que tem dentro.

O documento se chama Filesystem Hierarchy Standard. Ninguém lê. Todo mundo segue.

```
ana@vm:~$ ls -ld /bin /boot /dev /etc /home /lib /media /mnt /opt /proc /root /run /sbin /srv /sys /tmp /usr /var
lrwxrwxrwx  1 root root     7 Apr 22  2024 /bin -> usr/bin
drwxr-xr-x  2 root root  4096 Apr 22  2024 /boot
drwxr-xr-x  6 root root  2260 Sep 14 21:52 /dev
drwxr-xr-x 75 root root  4096 Sep 14 13:00 /etc
drwxr-xr-x  6 root root  4096 Sep 14 13:00 /home
lrwxrwxrwx  1 root root     7 Apr 22  2024 /lib -> usr/lib
drwxr-xr-x  2 root root  4096 Feb 17  2026 /media
drwxr-xr-x  6 root root  4096 Sep 14 19:46 /mnt
drwxr-xr-x 18 root root  4096 Sep 14 12:59 /opt
dr-xr-xr-x 87 root root     0 Sep 14 21:50 /proc
drwx------ 17 root root  4096 Sep 14 21:52 /root
drwxr-xr-x 15 root root  4096 Sep 14 20:52 /run
lrwxrwxrwx  1 root root     8 Apr 22  2024 /sbin -> usr/sbin
drwxr-xr-x  2 root root  4096 Feb 17  2026 /srv
dr-xr-xr-x 12 root root     0 Sep 14 21:58 /sys
drwxrwxrwt 38 root root 36864 Sep 14 21:59 /tmp
drwxr-xr-x 12 root root  4096 Feb 17  2026 /usr
drwxr-xr-x 11 root root  4096 Feb 17  2026 /var
```

Antes da tabela, duas coisas que essa listagem já te contou de graça.

**Quatro deles são setas.** `/bin`, `/lib`, `/sbin` e `/lib64` não são diretórios: são links
simbólicos apontando para dentro de `/usr`. Isso é o *usr merge*, concluído em todas as
distribuições de peso entre 2012 e 2023, e a seção 46 explica o que é um link simbólico. Por
enquanto: `/bin/ls` e `/usr/bin/ls` são o mesmo arquivo alcançado por dois nomes.

**`/proc` e `/sys` têm tamanho zero.** Não vazio — zero. Nada ali está em disco. A seção 49 é sobre
o que eles realmente são.

## O mapa inteiro

| | o que tem dentro | você vai lá |
|---|---|---|
| `/bin`, `/sbin` | comandos. `sbin` é a metade administrativa | raramente pelo nome — o `$PATH` acha por você |
| `/boot` | o kernel e o carregador de boot | quase nunca, e com cuidado |
| `/dev` | dispositivos, como arquivos | para nomear um disco ou o `/dev/null` |
| `/etc` | configuração da máquina inteira, em texto | **o tempo todo** |
| `/home` | um diretório por pessoa | você mora aqui |
| `/lib`, `/lib64` | bibliotecas compartilhadas que os programas carregam | não |
| `/media` | coisas removíveis, montadas automaticamente | quando um pendrive aparece |
| `/mnt` | um lugar para montar algo na mão | quando você monta algo na mão |
| `/opt` | software instalado fora do gerenciador de pacotes | quando um fornecedor colocou ali |
| `/proc` | o kernel e cada processo rodando, como arquivos | para ler um número por vez |
| `/root` | a casa do administrador. **Não** é `/` | como root |
| `/run` | estado do que está rodando *agora*; vazio no boot | para achar um PID ou um socket |
| `/srv` | dados servidos por esta máquina — um site, um compartilhamento | se quem montou usou |
| `/sys` | dispositivos e ajustes do kernel, como arquivos | para ler um sensor, mexer num botão |
| `/tmp` | rascunho. Qualquer um escreve. Limpo no boot | para um arquivo descartável |
| `/usr` | tudo que está instalado: programas, bibliotecas, dados | para olhar o que você tem |
| `/var` | o que **muda** enquanto a máquina roda — logs acima de tudo | **o tempo todo** |

## Os quatro onde você vai passar a vida

**`/etc` é configuração, e é texto.** Definição de serviços, usuários, rede, fontes de pacotes,
fuso horário. Não existe registro do Windows. Uma mudança é um diff, o que quer dizer que `/etc`
pode ser lido com `cat`, buscado com `grep`, comparado e versionado no git.

**`/var` é o que muda.** `/var/log` é para onde você vai quando algo quebrou. `/var/lib` é onde os
serviços guardam os dados de trabalho — os arquivos de um banco de dados costumam estar sob
`/var/lib`. `/var/cache` é descartável. A regra de bolso: *se a máquina escreve enquanto roda, está
sob `/var`.*

```
ana@vm:~$ ls /var
backups  cache  lib  local  lock  log  mail  opt  run  spool  tmp
```

**`/usr` é o que foi instalado**, e dentro dele a mesma forma se repete um nível abaixo:

```
ana@vm:~$ ls /usr
bin  games  include  lib  lib64  libexec  local  sbin  share  src
```

`/usr/bin` são os programas, `/usr/lib` é o que eles carregam, `/usr/share` são dados que não
dependem do processador — ícones, manuais, traduções. **`/usr/local` é o que vale lembrar**: é para
software que *você* colocou ali na mão, e o gerenciador de pacotes nunca encosta. Essa separação é o
que permite uma ferramenta compilada à mão e uma empacotada conviverem.

**`/home` são as pessoas.** Um diretório para cada, e normalmente o único onde você escreve.

## Os três que se parecem e não são

**`/tmp`, `/var/tmp` e `/run`.** Os três são rascunho, e a diferença é quanto tempo o rascunho dura:

| | sobrevive a um reboot | uso típico |
|---|---|---|
| `/tmp` | não | um arquivo que existe pela duração de um comando |
| `/var/tmp` | **sim** | um arquivo de que um programa precisa depois de reiniciar |
| `/run` | não — nem existe antes do boot | PIDs, sockets e travas de serviços em execução |

**`/mnt` e `/media`.** `/media` é onde o sistema monta o que ele encontrou — um pendrive aparece
como `/media/ana/KINGSTON`. `/mnt` é onde *você* monta algo de propósito. Nada obriga; é convenção,
e seguir a convenção significa que a próxima pessoa consegue adivinhar.

**`/opt` e `/usr/local`.** Os dois guardam software fora do gerenciador de pacotes. `/opt` é a
árvore do fornecedor, tudo num diretório só — `/opt/algumfornecedor/`, com `bin` e `lib` próprios
lá dentro. Algumas distribuições levam a diferença a sério. A maioria das pessoas usa o que o
instalador escolheu.

## Dois nomes que enganam todo mundo exatamente uma vez

**`/usr` não é "user".** Historicamente era — diretórios pessoais moravam ali —, mas há quarenta
anos quer dizer *Unix System Resources*. As pessoas estão em `/home`.

**`/root` não é `/`.** `/` é o topo da árvore. `/root` é o diretório pessoal do administrador,
sentado dentro dela. E você não pode olhar:

```
ana@vm:~$ cd /root
bash: cd: /root: Permission denied
```

O que é a aula 4, chegando no horário.

## Uma máquina de verdade tem mais que isso

A listagem lá em cima nomeou dezoito diretórios porque pediu dezoito pelo nome. Um `ls /` simples
numa máquina que você não montou vai mostrar extras: `lost+found` num sistema de arquivos ext4,
`snap` no Ubuntu, `swapfile`, um `data` que alguém montou, às vezes um diretório que um runtime de
contêiner colocou ali.

**Isso é normal e não é problema.** O padrão diz o que precisa estar lá e para que serve; ele não
proíbe o resto. Quando você encontrar um nome desconhecido na raiz de uma árvore, dê um `ls -l` e
olhe quem é o dono — isso responde a pergunta mais vezes do que procurar o nome na internet.
