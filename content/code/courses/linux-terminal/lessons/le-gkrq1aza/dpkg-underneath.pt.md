---
title: O `dpkg`, a camada que faz exatamente o que você diz
version: 1
---

O `apt` é um programa que decide o que fazer e então chama o `dpkg` para fazer. Tudo nesta seção é
sobre usar o `dpkg` diretamente, o que você vai fazer, porque mais cedo ou mais tarde alguém te
entrega um `.deb`.

**O `dpkg` nunca ouviu falar de repositório.** Ele instala o arquivo que você der e nada mais. Isso
não é uma limitação a contornar; é o empilhamento, e esta seção inteira é uma demonstração do que
isso custa e de como devolver o custo.

## A falha, do começo ao fim

```
root@vm:~# cd /tmp && apt-get download cowsay
Get:1 http://archive.ubuntu.com/ubuntu noble/universe amd64 cowsay all 3.03+dfsg2-8 [18.6 kB]
Fetched 18.6 kB in 0s (39.3 kB/s)
root@vm:/tmp# ls *.deb
cowsay_3.03+dfsg2-8_all.deb
root@vm:/tmp# dpkg -i cowsay_3.03+dfsg2-8_all.deb
Selecting previously unselected package cowsay.
(Reading database ... 58861 files and directories currently installed.)
Preparing to unpack cowsay_3.03+dfsg2-8_all.deb ...
Unpacking cowsay (3.03+dfsg2-8) ...
dpkg: dependency problems prevent configuration of cowsay:
 cowsay depends on libtext-charwidth-perl; however:
  Package libtext-charwidth-perl is not installed.

dpkg: error processing package cowsay (--install):
 dependency problems - leaving unconfigured
Errors were encountered while processing:
 cowsay
```

Leia na ordem em que aconteceu. **O `Unpacking` deu certo** — os arquivos estão no disco agora. **O
configurar não**, porque a dependência da seção 104 está faltando. O dpkg diz isso com precisão,
nomeia o pacote, e para.

O `apt-get download` vale ser notado por si só: ele busca um `.deb` para o diretório atual e não
instala nada. É assim que você consegue um arquivo de pacote para inspecionar, para copiar para uma
máquina sem rede, ou — como aqui — para quebrar algo de propósito.

## O estado que resulta

```
root@vm:/tmp# dpkg -l cowsay | tail -1
iU  cowsay         3.03+dfsg2-8 all          configurable talking cow
```

**`iU`**, e as duas letras são os dois passos da seção 106:

| | |
|---|---|
| `i` | **desejado**: alguém quer isto instalado |
| `U` | **estado**: desempacotado, e não configurado |

A legenda da seção 107 soletra isso toda vez que o `dpkg -l` roda, e este é o momento em que ela
ganha as três linhas dela. **Uma segunda letra maiúscula é ruim**, o que a legenda também diz.

## E meio instalado não é teórico

```
root@vm:/tmp# cowsay hi
Can't locate Text/CharWidth.pm in @INC (you may need to install the Text::CharWidth module) (@INC en
tries checked: /etc/perl /usr/local/lib/x86_64-linux-gnu/perl/5.38.2 /usr/local/share/perl/5.38.2 /u
sr/lib/x86_64-linux-gnu/perl5/5.38 /usr/share/perl5 /usr/lib/x86_64-linux-gnu/perl-base /usr/lib/x86
_64-linux-gnu/perl/5.38 /usr/share/perl/5.38 /usr/local/lib/site_perl) at /usr/games/cowsay line 14.
BEGIN failed--compilation aborted at /usr/games/cowsay line 14.
```

**Quatro linhas de perl, e nenhuma delas diz "pacote".** O comando existe, ele roda, e falha dentro
de si mesmo procurando uma biblioteca que não está lá.

É esse o motivo de esta seção valer o espaço. Encontrado sozinho — num log, na máquina de outra
pessoa, uma semana depois — este erro parece um bug no `cowsay`. Não é. É um pacote que nunca foi
configurado, e o `dpkg -l` diz isso em duas letras.

**Quando um programa falha procurando algo que deveria ter, confira o estado do pacote antes de
qualquer outra coisa.** Custa um comando.

## O conserto

```
root@vm:/tmp# apt-get -y -qq --fix-broken install
debconf: delaying package configuration, since apt-utils is not installed
Selecting previously unselected package libtext-charwidth-perl:amd64.
(Reading database ... 58922 files and directories currently installed.)
Preparing to unpack .../libtext-charwidth-perl_0.04-11build3_amd64.deb ...
Unpacking libtext-charwidth-perl:amd64 (0.04-11build3) ...
Setting up libtext-charwidth-perl:amd64 (0.04-11build3) ...
Setting up cowsay (3.03+dfsg2-8) ...
root@vm:/tmp# dpkg -l cowsay | tail -1
ii  cowsay         3.03+dfsg2-8 all          configurable talking cow
root@vm:/tmp# cowsay hi
 ____
< hi >
 ----
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
```

**O `apt-get --fix-broken install` — muitas vezes escrito `apt-get -f install` — é o comando a
conhecer.** Ele olha o que está desconfigurado, descobre o que falta, busca, e então termina a
configuração que estava esperando. Dois pacotes configurados, `iU` vira `ii`, e o programa funciona.

Há um jeito mais curto de evitar isso tudo:

```
apt install ./cowsay_3.03+dfsg2-8_all.deb
```

**Um caminho com uma `/` diz ao `apt` para instalar um arquivo local** — com resolução de
dependências, a partir dos repositórios, do jeito que ele faz com qualquer coisa. O `./` é
obrigatório; sem ele o apt procura um pacote com aquele nome.

**Então: use `apt install ./arquivo.deb` para um pacote local, e guarde o `dpkg -i` para quando você
quiser mesmo.**

## O resto do `dpkg`

```
dpkg -i file.deb           # install this file, and nothing else
dpkg -r thing              # remove, keeping configuration
dpkg -P thing              # purge
dpkg -l [pattern]          # what is installed, with status letters
dpkg -L thing              # files this package owns
dpkg -S /path/to/file      # which package owns this file
dpkg -c file.deb           # what is in this file, without installing
dpkg -I file.deb           # this file's metadata
dpkg --configure -a        # finish configuring everything that is half done
```

**O `dpkg --configure -a` é o outro conserto**, e é para outra causa: uma instalação interrompida —
um reboot, um disco cheio, um `Ctrl+C` — deixando pacotes desempacotados e não configurados sem nada
de fato faltando. Ele repete o passo de configuração para todos eles.

A regra prática entre os dois: **`--configure -a` quando nada falta e algo foi interrompido,
`--fix-broken install` quando algo falta.** Rodar o errado primeiro é inofensivo; ele vai te dizer.

O `rpm` é a mesma camada na outra família, com a mesma propriedade — o `rpm -i` também não resolve
dependências — e a seção 112 o mostra recusando pelo mesmo motivo.
