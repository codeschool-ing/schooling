---
title: Quando a montagem falha
version: 1
---

A maioria das pessoas que desiste de um curso como este desiste aqui, diante de um erro sobre uma
máquina que ainda não terminou de montar. Estas são as falhas que acontecem, na ordem em que você as
encontraria.

**A conferência diz `FAILED`.** O download veio danificado. Baixe de novo; nunca instale de um arquivo
que falhou, porque nada do que ele fizer depois merece confiança. A aula 3 mostra a falha de propósito.

**A máquina virtual não liga, e a mensagem fala em VT-x, AMD-V, SVM ou virtualização.** O suporte do
processador a máquinas virtuais está desligado no firmware do computador. É uma opção no menu da BIOS ou
da UEFI, em geral em *Advanced* ou *CPU configuration*, e a aula 2 mostra como chegar a esse menu.
Nenhum programa consegue ligá-la por você. No Windows, o Hyper-V e o WSL também podem segurá-la, e aí o
VirtualBox roda muito devagar ou nem roda; use o próprio Hyper-V, ou desligue os dois.

**Num Mac com Apple silicon, o instalador nunca aparece, ou se arrasta.** Foi usado o instalador
`amd64`. Esse Mac roda sistemas `arm64` nativamente e só emula o outro tipo, devagar. Baixe o
instalador `arm64` e crie a máquina de novo.

**A senha é recusada no primeiro login, embora você a tenha digitado duas vezes.** O instalador recebeu
o teclado errado, e algum caractere da senha fica em outro lugar no teclado que você tem. Entre
digitando a senha como aquele teclado a enxerga, ou instale de novo com o layout certo.

**Depois de reiniciar, o instalador começa de novo.** O ISO continua no drive virtual da máquina, e ela
iniciou por ele em vez do disco. Tire-o (no VirtualBox, *Devices*, *Optical Drives*) e reinicie.

**O `apt` diz que não conseguiu obter uma trava.** Nos primeiros minutos o Ubuntu instala as próprias
atualizações de segurança, e só um programa pode instalar por vez. Espere alguns minutos e rode o
comando de novo. Apagar o arquivo de trava é o conselho que você vai achar na internet, e é assim que um
banco de dados de pacotes se estraga.

**O `apt` não encontra o PowerShell.** É isto que ele diz quando o catálogo da Microsoft não foi
acrescentado, ou foi e o `apt update` não rodou depois:

```
ana@server:~$ sudo apt install -y powershell
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
E: Unable to locate package powershell
```

Rode as linhas do passo 5 de novo, na ordem.

**Todo `sudo` reclama do nome da própria máquina.** Acontece depois de renomear o servidor, e a
transcrição abaixo reproduz isso tirando o nome do `/etc/hosts`:

```
ana@server:~$ sudo true
sudo: unable to resolve host server: Name or service not known
ana@server:~$ cat /etc/hostname
server
ana@server:~$ grep server /etc/hosts
ana@server:~$ echo '127.0.1.1 server' | sudo tee -a /etc/hosts
sudo: unable to resolve host server: Name or service not known
127.0.1.1 server
ana@server:~$ sudo true
```

O `sudo` rodou cada comando mesmo assim; a linha é um aviso. O nome da máquina está em `/etc/hostname` e
falta em `/etc/hosts`, o arquivo que transforma nomes em endereços, então a máquina não consegue achar a
si mesma. O instalador escreve os dois. Acrescentar a linha resolve, e o último `sudo` não diz nada. A
aula 15 é sobre o `/etc/hosts`.

**E quando nada mais funciona**, restaure o snapshot `fresh`, ou apague a máquina virtual e monte de novo
a partir do passo 2. Parece desistir. É o que profissionais fazem com uma máquina cujo estado ninguém
consegue mais explicar, e custa meia hora porque cada passo está escrito na seção anterior a esta.
