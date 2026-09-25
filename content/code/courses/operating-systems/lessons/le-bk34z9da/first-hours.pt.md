---
title: A primeira hora depois de instalar
version: 1
---

A cópia do instalador é tão velha quanto a ISO, então o primeiro trabalho é o mesmo do Windows:
atualizações. No Ubuntu são dois comandos. O primeiro pergunta aos repositórios o que há de novo:

```
ana@server:~$ sudo apt update
Hit:1 http://security.ubuntu.com/ubuntu noble-security InRelease
Hit:2 http://archive.ubuntu.com/ubuntu noble InRelease
Hit:3 http://archive.ubuntu.com/ubuntu noble-updates InRelease
Hit:4 http://archive.ubuntu.com/ubuntu noble-backports InRelease
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
50 packages can be upgraded. Run 'apt list --upgradable' to see them.
ana@server:~$ apt list --upgradable 2>/dev/null | head -6
Listing...
apt/noble-updates 2.8.3 amd64 [upgradable from: 2.7.14build2]
base-files/noble-updates 13ubuntu10.5 amd64 [upgradable from: 13ubuntu10]
coreutils/noble-updates,noble-security 9.4-3ubuntu6.3 amd64 [upgradable from: 9.4-3ubuntu6]
diffutils/noble-updates,noble-security 1:3.10-1ubuntu0.1 amd64 [upgradable from: 1:3.10-1build1]
dpkg/noble-updates,noble-security 1.22.6ubuntu6.6 amd64 [upgradable from: 1.22.6ubuntu6]
```

O `sudo apt update` só **atualiza a lista**: ele baixou o catálogo atual dos servidores do Ubuntu (as
quatro linhas `Hit`) e comparou com o que está instalado. Cinquenta pacotes têm versões mais novas, e o
segundo comando os lista: o `apt`, a própria ferramenta de pacotes, os arquivos base, os utilitários
principais. A aula 11 trata do `apt` em detalhe.

O segundo comando os instala:

```
ana@server:~$ sudo apt upgrade -y > upgrade.log 2>&1; tail -3 upgrade.log
Setting up e2fsprogs (1.47.0-2.4~exp1ubuntu4.1) ...
e2scrub_all.service is a disabled or a static unit not running, not starting it.
Processing triggers for libc-bin (2.39-0ubuntu8.9) ...
ana@server:~$ apt list --upgradable 2>/dev/null
Listing...
```

O `sudo apt upgrade` baixa e instala cada versão mais nova. As últimas linhas do log dele são pacotes
sendo configurados, e depois a lista de pacotes para atualizar fica vazia. Ao contrário do Windows, a
maior parte disso **não precisa reiniciar**; um kernel novo é a principal exceção, e o Ubuntu avisa
quando chega um.

## sudo: administrador para um comando

No Linux, o administrador é um usuário chamado **root**. O Ubuntu não deixa você entrar como root. Em
vez disso, a primeira conta pertence ao **grupo `sudo`**, que a deixa rodar um comando de cada vez como
root:

```
ana@server:~$ id
uid=1000(ana) gid=1000(ana) groups=1000(ana),27(sudo)
ana@server:~$ sudo whoami
root
```

O `id` mostra que a Ana está no grupo 27, `sudo`. O `sudo whoami` roda o `whoami` como administrador, e
a resposta é `root`. O `sudo` pede **a senha da própria Ana**, não a do root, lembra dela por alguns
minutos e anota cada uso num log. Nesta máquina de teste ele foi configurado para não pedir, e por isso
o registro não mostra o pedido; uma instalação de verdade pede. A aula 10 o compara com o UAC do Windows, que é a mesma ideia com um
botão no lugar do pedido de senha.

O hábito para levar daqui: trabalhe como você mesmo, e ponha `sudo` na frente dos poucos comandos que
mudam o sistema. Os comandos deste curso que precisam dele dizem isso.
