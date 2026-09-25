---
title: De onde vem o software
version: 1
---

No Windows um programa costuma ser baixado do site de quem o faz. Numa distribuição Linux ele costuma
vir dos **repositórios da própria distribuição**: servidores com cada pacote que ela compilou,
assinados com a chave dela. A lista deles no servidor é um arquivo só:

```
ana@server:~$ cat /etc/apt/sources.list.d/ubuntu.sources
Types: deb
URIs: http://archive.ubuntu.com/ubuntu/
Suites: noble noble-updates noble-backports
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb
URIs: http://security.ubuntu.com/ubuntu/
Suites: noble-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
ana@server:~$ apt-cache show bash cowsay | grep -E '^(Package|Section)'
Package: bash
Section: shells
Package: cowsay
Section: universe/games
```

- **`URIs`** são os servidores. O `security.ubuntu.com` é separado para que as correções de segurança
  cheguem às máquinas mesmo quando um espelho do arquivo principal está atrasado.
- **`Suites`**: `noble` é a versão como saiu, `noble-updates` as correções desde então, e
  `noble-security` as correções de segurança. O `noble-backports` oferece algumas versões mais novas, e
  o apt não pega nada dele a não ser que alguém peça.
- **`Signed-By`** é a chave com que toda lista de pacotes tem de estar assinada. Um download que não
  bate com ela é recusado, que é o checksum da aula 3 feito pelo apt toda vez.
- **`Components`** são quatro seções do arquivo, e elas diferem em **quem corrige o software**:

| componente | o que guarda | correções de segurança de |
|---|---|---|
| `main` | software livre que a Canonical suporta | a Canonical, suporte padrão |
| `restricted` | drivers proprietários | a Canonical, onde ela consegue |
| `universe` | software livre mantido pela comunidade | a comunidade; o Ubuntu Pro acrescenta a Canonical |
| `multiverse` | software com restrições de licença | ninguém promete |

O último comando mostra isso em dois pacotes: o `bash` está no `main`, então a seção dele não tem
prefixo, e o `cowsay` é `universe/games`. O componente é como você sabe, antes de instalar, de quem é
a promessa que as datas de suporte da seção 04 representam.

## Fora dos repositórios

Algum software não está neles, ou está velho demais lá. Os caminhos alternativos, em ordem de quanta
confiança pedem:

- **Snap** e **Flatpak**, formatos que empacotam um programa com o que ele precisa e rodam em qualquer
  distribuição.
- **O repositório do próprio fabricante**, acrescentado como mais um arquivo `.sources` com a chave
  dele. Navegadores, o Docker e bancos de dados muitas vezes vêm assim.
- **Um PPA**, um *Personal Package Archive*: o repositório de uma pessoa no Launchpad. Ele pode trocar
  qualquer pacote do sistema, e quem o mantém pode empurrar qualquer coisa para toda máquina que confia
  nele.

A aula 11 instala software de cada um desses jeitos.
