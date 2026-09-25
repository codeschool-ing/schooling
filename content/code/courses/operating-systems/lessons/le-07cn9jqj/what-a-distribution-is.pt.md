---
title: O que é uma distribuição
version: 1
---

A aula 1 disse que o Linux, a rigor, é só o **kernel**. Ninguém instala um kernel sozinho. Uma
**distribuição** é o kernel junto com tudo o que um sistema funcionando precisa em volta dele,
escolhido, compilado e testado por um grupo de pessoas, e publicado com uma promessa de por quanto
tempo elas vão continuar corrigindo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Uma distribuição desenhada como cinco camadas, de baixo para cima. O kernel, o Linux do kernel.org, o mesmo projeto em todo lugar. Ferramentas e bibliotecas, como GNU coreutils, bash e glibc, quase iguais. O gerenciador de pacotes, neste servidor o apt e os pacotes .deb, que muda por família. Os repositórios, neste servidor o archive.ubuntu.com, que mudam por distribuição. E versões e suporte, aqui uma versão LTS a cada dois anos, que é a parte que você de fato escolhe.\"><defs><marker id=\"ly-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"16\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">camada</text><text x=\"250\" y=\"16\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">neste servidor</text><text x=\"480\" y=\"16\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">entre distribuições</text><rect x=\"20\" y=\"30\" width=\"680\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">versões e suporte</text><text x=\"250\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">uma LTS a cada dois anos</text><text x=\"480\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">a parte que você escolhe</text><rect x=\"20\" y=\"72\" width=\"680\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"89\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">os repositórios</text><text x=\"250\" y=\"89\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">archive.ubuntu.com</text><text x=\"480\" y=\"89\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">muda por distribuição</text><rect x=\"20\" y=\"114\" width=\"680\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"131\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o gerenciador de pacotes</text><text x=\"250\" y=\"131\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">apt e .deb</text><text x=\"480\" y=\"131\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">muda por família</text><rect x=\"20\" y=\"156\" width=\"680\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"173\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">ferramentas e bibliotecas</text><text x=\"250\" y=\"173\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">GNU coreutils, bash, glibc</text><text x=\"480\" y=\"173\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">quase iguais</text><rect x=\"20\" y=\"198\" width=\"680\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"215\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o kernel</text><text x=\"250\" y=\"215\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Linux, do kernel.org</text><text x=\"480\" y=\"215\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o mesmo projeto em todo lugar</text></svg>", "caption": "Subindo, as camadas diferem mais. Escolher uma distribuição é principalmente escolher as duas de cima: de onde vem o software, e por quanto tempo alguém o corrige.", "same": ["GNU coreutils, bash, glibc", "archive.ubuntu.com"]}
```

O servidor sabe dizer qual é a dele. Toda distribuição moderna escreve a resposta no mesmo arquivo:

```
ana@server:~$ cat /etc/os-release
PRETTY_NAME="Ubuntu 24.04.5 LTS"
NAME="Ubuntu"
VERSION_ID="24.04"
VERSION="24.04.5 LTS (Noble Numbat)"
VERSION_CODENAME=noble
ID=ubuntu
ID_LIKE=debian
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
UBUNTU_CODENAME=noble
LOGO=ubuntu-logo
```

Três dessas linhas são para programas, não para pessoas:

- **`ID=ubuntu`** é a distribuição, numa forma que um script consegue comparar.
- **`ID_LIKE=debian`** é a família a que ela pertence. Um script que sabe instalar algo no Debian pode
  ler essa linha e concluir que os mesmos comandos funcionam aqui. Isso é a seção 02.
- **`VERSION_CODENAME=noble`** é a versão, pelo nome. Os codinomes do Ubuntu seguem o alfabeto, então
  a letra diz mais ou menos a idade de uma versão.

O `/etc/os-release` existe também no Fedora, no Debian, no Arch, no SUSE e no Alpine, com as mesmas
chaves. É a primeira coisa a ler numa máquina que outra pessoa configurou, antes de digitar qualquer
comando que instale alguma coisa.

## Por que as diferenças importam

O kernel e os comandos básicos são quase idênticos em todo lugar, e é por isso que a maior parte dos
comandos da aula 12 funciona em qualquer uma. O que muda são as **camadas de cima**: o comando que
instala software, o nome de um pacote, o caminho de um arquivo de configuração e, acima de tudo, **por
quanto tempo a versão à sua frente vai receber correções de segurança**. Um tutorial que diz
`dnf install` não serve neste servidor, e uma resposta de fórum para o Arch pode supor, sem avisar, uma
versão mais nova de tudo.
