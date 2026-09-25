---
title: Recuperação do macOS: o instalador já está dentro
version: 1
---

No Windows e no Linux o primeiro passo era um pendrive. No Mac normalmente não é, porque **todo Mac
carrega um pequeno segundo sistema para reparos**, chamado *Recuperação do macOS*, numa parte própria
do disco. Por ela você reinstala o macOS, apaga ou repara o disco e restaura de um backup.

## Como chegar lá

**Apple silicon.** Desligue o Mac. Aperte o botão de ligar e **continue segurando** até aparecer
*Carregando opções de inicialização*. Escolha *Opções* e depois *Continuar*. A mesma tela lista
todo disco pelo qual o Mac consegue iniciar, e é também por ela que você escolhe um instalador em
pendrive.

**Intel.** Ligue o Mac e segure na hora uma destas combinações até aparecer o logo da Apple:

| teclas | o que a Recuperação instala |
|---|---|
| **Command-R** | o macOS instalado por último neste Mac |
| **Option-Command-R** | o macOS mais recente que este Mac suporta, baixado |
| **Shift-Option-Command-R** | o que veio com o Mac, ou o mais próximo ainda disponível |

As duas últimas são a **Recuperação pela Internet**: o Mac baixa o sistema de recuperação da Apple
antes de iniciar. Precisa de rede, e funciona quando o próprio disco está vazio ou é novo.

## O que há na tela da Recuperação

Uma lista curta de utilitários: *Reinstalar o macOS*, *Utilitário de Disco*, *Restaurar do Time
Machine* e o *Safari* para ler instruções. O Terminal fica no menu *Utilitários*. Você vai precisar
da Recuperação de novo na aula 17, quando um Mac não inicia, e é a mesma tela.

## Quando você quer um pendrive mesmo

Alguns trabalhos pedem um instalador de boot assim mesmo: muitos Macs para instalar e uma conexão lenta,
ou um Mac com a Recuperação danificada. Ele é feito a partir de outro Mac, no Terminal:

```sh
softwareupdate --list-full-installers     # the versions Apple offers this Mac
softwareupdate --fetch-full-installer     # downloads "Install macOS …" into /Applications
sudo "/Applications/Install macOS Tahoe.app/Contents/Resources/createinstallmedia" \
     --volume /Volumes/Untitled           # erases the stick and makes it an installer
```

**Nenhum destes foi rodado para esta aula.** O `createinstallmedia` **apaga o pendrive inteiro**, como o
`dd` da aula 3. Ele pergunta uma vez, dizendo o nome do volume, e essa pergunta é a hora de ler o nome
depois do `--volume`.

Um Mac com Apple silicon que não inicia nem na Recuperação pode ser **reanimado** a partir de um segundo
Mac, com o *Apple Configurator* da Apple e um cabo USB-C. É raro, e é o único reparo que precisa de
outro Mac na sala.
