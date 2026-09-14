---
title: O primeiro comando em qualquer máquina
version: 1
---

Tudo nesta aula se reduz a um reflexo. Você chega numa máquina que não configurou e, antes de
digitar qualquer coisa que a mude, pergunta o que ela é.

```
ana@vm:~$ cat /etc/os-release
PRETTY_NAME="Ubuntu 24.04.4 LTS"
NAME="Ubuntu"
VERSION_ID="24.04"
VERSION="24.04.4 LTS (Noble Numbat)"
VERSION_CODENAME=noble
ID=ubuntu
ID_LIKE=debian
HOME_URL="https://www.ubuntu.com/"
```

Dois segundos, e ele responde as seis perguntas da seção anterior de uma vez.

## Os dois campos que importam

**`ID`** é a distribuição — `ubuntu`, `debian`, `rocky`, `alpine`, `opensuse-leap`.

**`ID_LIKE`** é a família, e é o que decide o que você digita. Uma distribuição que você nunca ouviu
falar e que diz `ID_LIKE=debian` é uma cujo gerenciador de pacotes é o `apt`, cujo servidor web é o
`apache2`, e cujo arcabouço de segurança é o AppArmor. **Você já sabe operar.**

O `ID_LIKE` não existe nas cabeças de família — o próprio Debian não tem `ID_LIKE`, porque ele não é
parecido com mais nada. A ausência dele também é informação.

**`VERSION_ID`** é o terceiro, e é o que você confere contra a tabela da seção 30 quando quer saber
se aquela máquina ainda tem suporte.

## Por que este arquivo e não os antigos

A seção 25 mostrou uma máquina Ubuntu respondendo à pergunta antiga:

```
ana@vm:~$ cat /etc/debian_version
trixie/sid
```

É a mesma máquina, e lida como "em qual sistema eu estou" ela está errada. `/etc/debian_version`,
`/etc/redhat-release`, `/etc/SuSE-release` são arquivos por família, de antes de haver um padrão.
Eles ainda existem, e cada um responde uma pergunta ligeiramente diferente num formato ligeiramente
diferente.

O `/etc/os-release` foi criado para que **um arquivo, com os mesmos nomes de campo, exista em toda
distribuição**. É a pergunta que sempre funciona, e é por isso que é a de virar hábito.

## Os outros dois, e para que servem

```
ana@vm:~$ uname -a
Linux vm 6.18.44-fc-v24 #1 SMP PREEMPT_DYNAMIC @0 x86_64 x86_64 x86_64 GNU/Linux
```

O `uname` é o **kernel**, não a distribuição. O `6.18.44` é a versão do kernel, `x86_64` é a
arquitetura do processador, e `vm` é o nome da máquina. Ele responde outra pergunta, e é a de se
fazer quando um software diz precisar de um kernel ou uma arquitetura específica.

E a terceira ferramenta, que vale mostrar pelo jeito como ela falha:

```
ana@vm:~$ hostnamectl
System has not been booted with systemd as init system (PID 1). Can't operate.
Failed to connect to bus: Host is down
```

O `hostnamectl` dá um resumo arrumado — distribuição, kernel, arquitetura, nome, hardware — e **faz
parte do systemd**, então dentro de um contêiner ele não consegue responder nada. Mesma causa da
mensagem do `systemctl` na seção 04 da aula 1, e a mesma leitura: nada está quebrado, nada deu
boot.

Que é a razão prática de o `/etc/os-release` ser o reflexo e o `hostnamectl` ser a conveniência:
**um dos dois é um arquivo, e arquivos não precisam de sistema de inicialização rodando.**

## O hábito, em três linhas

```
cat /etc/os-release     # qual distribuição, qual família, qual versão
uname -a                # qual kernel, qual arquitetura
whoami                  # e quem eu sou aqui — aula 1, seção 14
```

Três comandos, e nenhum deles muda nada. Rode antes do quarto, que muda.
