---
title: Conseguindo um Linux para praticar
version: 1
---

Esta seção não ensina Linux nenhum, e é a seção sem a qual o resto do curso não funciona. **Tudo
depois daqui assume que você tem um prompt na sua frente** — não um vídeo de um, não um diagrama:
um de verdade, no qual você possa digitar e que você possa quebrar.

Ler sobre comandos não produz a habilidade. A habilidade está nas suas mãos, e ela chega por
repetição numa máquina que é sua para estragar. Então: cinco jeitos de ter uma, o que cada um
custa, e uma recomendação.

## O que "uma máquina para praticar" precisa ser

Três propriedades, e elas eliminam algumas opções que parecem convenientes:

1. **Você pode quebrá-la.** Você vai rodar algo destrutivo sem querer. Isso tem de ser um
   contratempo de dez minutos, e não um desastre.
2. **Você pode jogá-la fora e pegar outra nova.** Começar limpo é uma ferramenta de aprendizado,
   não uma admissão de fracasso.
3. **É um Linux de verdade.** Não um simulador, não um site que finge. O assunto inteiro é como o
   sistema realmente se comporta.

## Cinco jeitos

| | o que é | custa | bom para |
|---|---|---|---|
| **WSL 2** | um kernel Linux de verdade rodando ao lado do Windows, com um terminal para dentro dele | nada; só Windows 10/11 | **a resposta se você está no Windows** |
| **um contêiner** | um userland Linux sobre um host Linux ou Mac, iniciado em um segundo | nada; precisa de Docker ou Podman instalado | prática rápida, máquinas descartáveis, aulas 1–4 e 7–9 |
| **uma máquina virtual** | um computador inteiro simulado dentro do seu | software livre, alguns GB de disco, um pouco de RAM | a opção mais completa; a única que te dá o boot, o systemd e o desktop |
| **um live USB** | dar boot no seu próprio hardware a partir de um pendrive, sem tocar no disco | um pendrive e um reboot | experimentar uma distribuição em hardware real |
| **uma instância na nuvem** | a máquina de outra pessoa, alugada por hora | dinheiro, e um cartão de crédito | praticar acesso remoto; como vai ser de verdade no trabalho |

## Escolha uma, em uma linha

**No Windows → WSL 2.** É grátis, é um kernel genuíno em vez de uma emulação, e é um comando no
PowerShell:

```
wsl --install
```

Isso instala o Ubuntu por padrão, e depois de reiniciar o `wsl` de qualquer terminal te deixa num
prompt. Se você quiser uma distribuição específica, `wsl --list --online` mostra o que está
disponível.

**No macOS ou no Linux → um contêiner**, pela velocidade, e uma máquina virtual quando você chegar
na aula 5. Com o Docker instalado, isto é um Linux descartável completo:

```
docker run -it --rm ubuntu:24.04 bash
```

`-it` te dá um terminal, `--rm` apaga a máquina quando você sair, `bash` é o que rodar lá dentro.
Quando você digita `exit`, tudo o que você fez some — que é justamente a graça. Para manter uma
máquina entre sessões, tire o `--rm` e dê um nome a ela.

**Num Mac, não use só o Terminal.** Você vai ser tentado, porque ele abre na hora e a maioria dos
comandos funciona. Ele é um userland BSD: flags mudam, o `sed -i` se comporta diferente, não existe
`/proc`, não existe `apt` e não existe systemd. Serve para as aulas 3 e 4 e é ativamente enganoso
para 2, 5, 7 e 11. Use-o pela conveniência, e tenha um Linux de verdade para o curso.

## Confira se o que você tem é o que você pensa

O primeiro reflexo deste curso, e você vai usá-lo por anos: quando chegar numa máquina, pergunte a
ela o que ela é.

```
ana@vm:~$ cat /etc/os-release
PRETTY_NAME="Ubuntu 24.04.4 LTS"
NAME="Ubuntu"
VERSION_ID="24.04"
VERSION="24.04.4 LTS (Noble Numbat)"
VERSION_CODENAME=noble
ID=ubuntu
ID_LIKE=debian
```

`ID` e `ID_LIKE` são as duas linhas que importam, e a aula 2 explica por quê: elas dizem em qual
família você está, o que diz o gerenciador de pacotes, os nomes dos serviços e metade dos caminhos.

E pergunte quem você é:

```
ana@vm:~$ id
uid=1001(ana) gid=1002(ana) groups=1002(ana)
```

Um usuário comum, com um número. Se aparecer `uid=0(root)`, você é o administrador — o que é muito
comum dentro de contêineres e é discutido na seção 14.

## Três coisas que vão te confundir, avisadas com antecedência

**Um contêiner não tem systemd.** Essa é a surpresa mais comum da lista inteira e não é um defeito.
Um contêiner roda um programa, não o equivalente a uma máquina inteira deles, então o `systemctl`
dentro de um contêiner `ubuntu` comum responde:

```
System has not been booted with systemd as init system (PID 1). Can't operate.
Failed to connect to bus: Host is down
```

Nada está quebrado. Simplesmente não há sistema de inicialização rodando, porque nada deu boot. A
aula 5 é sobre systemd e precisa de uma máquina virtual ou do WSL, não de um contêiner. Planeje
isso agora, em vez de concluir que a sua máquina está errada.

**Um contêiner novo não tem ferramentas que você espera.** A `ubuntu:24.04` vem enxuta: sem `ps`,
sem `vim`, sem `curl`. A aula 7 ensina a instalá-las; até lá, `apt update && apt install -y procps
vim curl` te dá uma máquina utilizável.

**O sistema de arquivos do WSL tem dois lados.** Sua casa Linux é `/home/voce` e o disco do Windows
aparece em `/mnt/c`. Trabalhe do lado Linux — arquivos em `/mnt/c` são mais lentos, e carregam
finais de linha do Windows, que é o assunto inteiro da seção 12.

## Antes de seguir

Você deveria conseguir fazer isto, agora, antes de continuar lendo:

1. abrir um terminal e ver um prompt;
2. digitar `whoami`, apertar enter, e ver um nome;
3. digitar `uname -s` e ver `Linux`;
4. digitar algo que não existe — `ola` serve — e ler o que volta.

O quarto não é piada. É a primeira mensagem de erro do curso, e a seção 17 passa o tempo dela
exatamente nessa linha. Levar uma recusa de uma máquina que você acabou de montar é um começo
melhor do que não levar nada.
