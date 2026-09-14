---
title: Um primeiro mapa da árvore
version: 1
---

A árvore tem um formato, e é o mesmo formato em toda distribuição — é para isso que serve o
Filesystem Hierarchy Standard. A aula 3 percorre diretório por diretório. **Esta seção é o mapa de
que você precisa para parar de se sentir perdido**, e são umas oito palavras.

## As oito que importam agora

| | o que tem dentro |
|---|---|
| `/etc` | **configuração**, da máquina inteira. Arquivos de texto, tudo |
| `/home` | um diretório por pessoa. O seu é `/home/voce`, e `~` é o atalho dele |
| `/var` | coisas que **mudam enquanto a máquina roda** — logs acima de tudo |
| `/usr` | os programas e os dados deles. Quase tudo que está instalado mora aqui |
| `/tmp` | rascunho, apagado no boot |
| `/root` | a casa do administrador. **Não** é a raiz da árvore, que é `/` |
| `/opt` | software instalado fora do gerenciador de pacotes |
| `/dev`, `/proc` | os dispositivos e o kernel, como arquivos — seção 09 |

## Como eles são de verdade

**O `/etc` é configuração, e é tudo texto.**

```
ana@vm:~$ ls /etc | head -12
PackageKit
X11
adduser.conf
alternatives
apparmor.d
apt
bash.bashrc
bash_completion.d
bazel.bazelrc
bindresvport.blacklist
binfmt.d
ca-certificates
```

Diretórios e arquivos, nomeados conforme o que configuram. **Não existe registro.** Tudo que decide
como esta máquina se comporta é um arquivo que você pode ler com `cat`, buscar com `grep`, comparar
com `diff` e guardar no git. Esse último não é metáfora: pôr o `/etc` sob controle de versão é uma
coisa normal de se fazer, e só é possível por causa do que esses arquivos são.

**O `/var` é o que muda.**

```
ana@vm:~$ ls /var
backups
cache
lib
local
lock
log
mail
opt
run
spool
tmp
```

O `log` é onde você vai morar. A aula 5 lê ele direito; a aula 11 vai lá quando algo está errado. A
regra de bolso que faz o `/var` fazer sentido: *se a máquina escreve enquanto roda, está aqui.*

**O `/usr` é o que foi instalado.**

```
ana@vm:~$ ls /usr
bin
games
include
lib
lib64
libexec
local
sbin
share
src
```

`bin` são programas, `lib` é o que eles carregam, `share` são dados que não dependem do processador
— ícones, documentação, traduções. O `local` é a exceção que vale conhecer: `/usr/local` é para
software que **você** instalou na mão, mantido separado para o gerenciador de pacotes nunca brigar
com você por ele.

**O `/home` são pessoas.**

```
ana@vm:~$ ls /home
ana
claude
ubuntu
user
```

Quatro contas nesta máquina, quatro diretórios. O seu é o único em que você pode escrever, e quase
sempre o único que você pode ler — a seção 14 é sobre o porquê.

## Contra o Windows, onde é a mesma ideia arrumada de outro jeito

| | Linux | Windows |
|---|---|---|
| seus documentos | `/home/voce` | `C:\Users\voce` |
| configuração da máquina | `/etc`, em texto | o registro, num banco binário |
| suas preferências | dotfiles em `/home/voce` | `AppData`, e o registro |
| programas instalados | `/usr`, espalhado por tipo | `C:\Program Files`, uma pasta cada |
| logs | `/var/log`, em texto | Visualizador de Eventos |
| rascunho | `/tmp` | `C:\Windows\Temp`, `%TEMP%` |

**A diferença que importa não são os nomes, é o formato.** Configuração no Linux é texto em
arquivos, então toda ferramenta da aula 8 funciona nela, e uma mudança é um diff que alguém
consegue ler. Configuração no Windows é em boa parte um banco binário alcançado pelas ferramentas
dele.

É por isso que este curso gasta uma aula inteira com texto: no Linux, texto *é* a interface de
administração.

## Duas coisas que as pessoas erram na hora

**`/root` não é `/`.** O `/` é o topo da árvore. O `/root` é o diretório pessoal do administrador,
que fica dentro dela, e são duas palavras diferentes que por acaso compartilham uma sílaba.

**`/usr` não é "usuário".** É onde moram os programas, não as pessoas. As pessoas estão em `/home`.
O nome é histórico e engana todo mundo exatamente uma vez.
