---
title: O seu computador, pronto para trabalhar
version: 1
---

Da aula 5 em diante, o curso pede que você faça coisas com o seu projeto: commit, tag, teste, push. Antes
de tudo isso, o seu computador precisa de quatro coisas:

- **um terminal**, onde se digita cada comando deste curso;
- **o git**, que guarda a história do projeto, e o **OpenSSH**, que a aula 15 usa para chegar a um servidor;
- **um editor** com que você se sinta à vontade; qualquer um serve, e nada no curso depende de qual;
- **a linguagem em que o seu projeto é escrito**, que a aula 3 ajuda a decidir. O loanbook é Python, e
  você só precisa de Python se o seu projeto também for.

## Três jeitos de ter isso

| caminho | o que você ganha | quanto custa | as transcrições |
|---|---|---|---|
| **instalado** (recomendado) | as ferramentas no computador que você já usa | algumas centenas de megabytes de disco | iguais no Ubuntu 24.04; parecidas no resto |
| **uma máquina virtual** | um Ubuntu 24.04 separado do seu sistema | uns 25 GB de disco, e 2 GB de memória enquanto roda | iguais ao impresso |
| **online** | uma máquina Linux no navegador | nada no seu computador; horas de uma cota mensal | parecidas, não idênticas |

**Instalado é o caminho recomendado.** Um projeto de portfólio mora onde você trabalha todo dia, e git,
OpenSSH e um editor são programas pequenos e comuns, que não mudam mais nada no computador. No
**Windows**, o Git for Windows, do git-scm.com, traz o git e um terminal chamado Git Bash; o Windows 10 e
o 11 já têm o OpenSSH. No **macOS**, `xcode-select --install` no Terminal instala o git, e o OpenSSH já
está lá. No **Ubuntu**, `sudo apt install git openssh-client python3`.

**Uma máquina virtual** é o caminho quando você não pode instalar programas no computador que tem, um
notebook do trabalho, por exemplo. Instale o Ubuntu 24.04 com interface gráfica no VirtualBox, que é
gratuito no Windows, no macOS e no Linux, e trabalhe dentro dele. A aula 15 monta uma segunda máquina
virtual, menor, para o servidor; essa é necessária em qualquer caminho que você escolha aqui.

**Online**, o GitHub Codespaces lhe dá uma máquina Linux com terminal e editor no navegador. Não custa
nada ao seu computador; o GitHub dá às contas pessoais uma cota mensal e cobra o que passar dela, em
termos que ele define e pode mudar. Esse caminho não foi rodado neste curso, e ele muda a aula 15: um
servidor no seu próprio computador não é alcançável a partir de um codespace, então o seu servidor
teria de estar online também.

## Conferindo, e dizendo ao git quem você é

As transcrições deste curso foram capturadas num notebook com Ubuntu 24.04, por Ana Lima, a autora do
loanbook. O prompt dela, `ana@laptop:~$`, diz quem digitou o comando, em que máquina, em que diretório;
o seu mostra o seu nome. Peça primeiro a versão de cada ferramenta, que também é o jeito mais rápido de
descobrir que ela não está instalada:

```
ana@laptop:~$ git --version
git version 2.43.0
ana@laptop:~$ ssh -V
OpenSSH_9.6p1 Ubuntu-3ubuntu13, OpenSSL 3.0.13 30 Jan 2024
ana@laptop:~$ python3 --version
Python 3.12.3
```

As suas versões vão ser outras, e nada neste curso precisa exatamente destas. Depois o git precisa saber
quem você é, porque **todo commit leva um nome e um endereço de e-mail**:

```
ana@laptop:~$ git config --global user.name "Ana Lima"
ana@laptop:~$ git config --global user.email ana@example.org
ana@laptop:~$ git config --global init.defaultBranch main
ana@laptop:~$ git config --global --list
user.name=Ana Lima
user.email=ana@example.org
init.defaultbranch=main
```

`--global` grava a configuração uma vez, para todo repositório deste computador. A terceira linha dá o
nome `main` ao primeiro branch de todo repositório novo, que é o que as transcrições do curso e os sites
de hospedagem usam. O endereço é publicado em cada commit que você envia, e a aula 18 o lê de volta e
mostra um endereço no-reply que deixa a sua caixa de correio de fora. Se você vai enviar para um site
público, configurar esse endereço agora poupa reescrever a história depois.

Por último, a prova de que tudo funciona: um repositório, um arquivo, um commit.

```
ana@laptop:~$ mkdir project && cd project && git init && echo "# project" > README.md
Initialized empty Git repository in /home/ana/project/.git/
ana@laptop:~/project$ git add README.md && git commit -q -m "Say what the project is for" && git log --oneline
d530b40 Say what the project is for
```

Uma linha de história, com um hash só dela; o seu vai ser diferente, porque o hash cobre o nome, a hora e
o conteúdo. Se você chegou até aqui, o seu computador está pronto para o resto do curso. Se algo no
caminho mostrou um erro, a próxima seção é para você.
