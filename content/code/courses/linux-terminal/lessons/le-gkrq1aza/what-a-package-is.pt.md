---
title: Um pacote é um arquivo compactado mais uma lista de promessas
version: 1
---

Tire a ferramenta da frente e um pacote é um arquivo compactado pequeno com metadados junto. O
arquivo guarda arquivos e para onde eles vão. Os metadados dizem como ele se chama, que versão é,
**do que ele precisa**, e o que ele oferece a outros pacotes.

É esse o formato inteiro, nas duas famílias:

| | | |
|---|---|---|
| **Debian, Ubuntu** | `.deb` | o `dpkg` cuida de um; o `apt` cuida do resto |
| **RHEL, Rocky, Alma, Fedora, SUSE** | `.rpm` | o `rpm` cuida de um; o `dnf` ou o `zypper` cuida do resto |

**A divisão em duas camadas é a primeira coisa a entender**, porque quase toda mensagem confusa
desta aula vem de usar a camada de baixo esperando a de cima.

| | |
|---|---|
| **baixa: `dpkg`, `rpm`** | um pacote, de um arquivo que você já tem. Faz exatamente o que você diz |
| **alta: `apt`, `dnf`, `zypper`** | conhece os repositórios, resolve dependências, baixa |

O `dpkg -i coisa.deb` não busca nada. Ele não pode: nunca ouviu falar de repositório. A seção 109 é
essa falha por inteiro, e ela termina com o único comando que a conserta.

## O que tem de fato dentro de um

Um `.deb` é um arquivo `ar` contendo dois tarballs e um marcador de versão. Um `.rpm` é um cabeçalho
seguido de um arquivo cpio comprimido. **Nenhum dos dois é interessante de abrir**, e as ferramentas
que os leem valem a pena assim mesmo, porque "o que isto instalaria" é uma pergunta justa de se
fazer antes de instalar:

```
dpkg -c thing.deb          # the file list, without installing
dpkg -I thing.deb          # the metadata: version, dependencies, description
rpm -qlp thing.rpm         # the file list
rpm -qip thing.rpm         # the metadata
```

**O `-p` nos comandos do rpm quer dizer "neste arquivo"** em vez de "num pacote instalado", e é a
diferença entre perguntar sobre um download e perguntar sobre a máquina.

## O banco de dados, a metade que as pessoas esquecem

Instalar faz duas coisas: põe os arquivos onde eles vão, e **anota que fez isso**. Essa segunda
metade é um banco de dados — `/var/lib/dpkg` no Debian, `/var/lib/rpm` do lado rpm — e é o que torna
toda pergunta da seção 109 respondível.

```
root@vm:~# dpkg --get-selections | wc -l
748
root@vm:~# dpkg -l | grep -c "^ii"
748
```

Setecentos e quarenta e oito pacotes numa máquina em que um punhado foi instalado à mão. Esse é um
número normal, e quase tudo ali chegou como dependência de outra coisa.

**O banco de dados é por que o `dpkg -S` consegue responder "o que pôs este arquivo aqui".** Nada
varre o disco; é uma consulta.

## O que um pacote promete

Quatro campos fazem a maior parte do trabalho, e os quatro estão visíveis no `apt show`:

```
root@vm:~# apt show cowsay 2>/dev/null | head -14
Package: cowsay
Version: 3.03+dfsg2-8
Priority: optional
Section: universe/games
Origin: Ubuntu
Maintainer: Ubuntu Developers <ubuntu-devel-discuss@lists.ubuntu.com>
Original-Maintainer: James McDonald <james@jamesmcdonald.com>
Bugs: https://bugs.launchpad.net/ubuntu/+filebug
Installed-Size: 93.2 kB
Depends: libtext-charwidth-perl, perl:any
Suggests: filters, cowsay-off
Homepage: https://web.archive.org/web/20120527202447/http://www.nog.net/~tony/warez/cowsay.shtml
Download-Size: 18.6 kB
APT-Sources: http://archive.ubuntu.com/ubuntu noble/universe amd64 Packages
```

| | |
|---|---|
| `Depends` | **precisa** estar lá, ou isto não vai ser configurado |
| `Recommends` | instalado por padrão, e não obrigatório. O `--no-install-recommends` pula |
| `Suggests` | mencionado e nunca instalado automaticamente |
| `APT-Sources` | de qual repositório esta versão veio — seção 105 |

**O `Recommends` é o campo que explica por que uma instalação de uma linha baixou quarenta
megabytes.** Ele vem ligado por padrão no Debian e no Ubuntu, e desligá-lo é a maior diferença entre
uma imagem de contêiner pequena e uma grande.

O `Depends: libtext-charwidth-perl` é a promessa que a seção 109 quebra de propósito.

## Versões, e por que elas são assim

`3.03+dfsg2-8` são três coisas juntas:

| | |
|---|---|
| `3.03` | a versão **upstream** — o que os próprios autores do programa chamaram |
| `+dfsg2` | o marcador da distribuição, aqui "removemos algo não redistribuível" |
| `-8` | a revisão de **empacotamento**: a oitava tentativa de empacotar aquele mesmo 3.03 |

**O último número muda sem o programa mudar nada.** Um `-8` onde você tinha `-7` pode ser uma falha
de segurança corrigida e nada mais, que é exatamente para o que a versão estável de uma distribuição
serve: o número da versão fica parado e as correções chegam por baixo.

O `5:29.3.1-1~ubuntu.24.04~noble` da seção 111 tem uma quarta parte — o `5:` é um **epoch**, um
número que sobrepõe a comparação normal de versões quando a numeração do upstream andou para trás.
Você raramente vai escrever um e vai ver vários.
