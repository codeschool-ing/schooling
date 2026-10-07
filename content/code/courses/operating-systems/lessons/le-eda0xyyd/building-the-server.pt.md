---
title: Montando o servidor
version: 1
---

Meia hora, quase toda de espera. A aula 3 explica cada tela do instalador; esta seção dá as respostas,
para que a máquina exista antes do primeiro comando.

## 1. Baixe o instalador e confira

Em `ubuntu.com/download/server`, baixe o **Ubuntu Server 24.04 LTS**, um arquivo de uns 4 GB, e, da
mesma página da versão, o arquivo pequeno `SHA256SUMS`. Num Mac com Apple silicon, pegue o instalador
`arm64`. Depois confira se o arquivo que você tem é o que a Canonical publicou. Num computador com Linux
é um comando:

```
ana@laptop:~/Downloads$ ls
SHA256SUMS  ubuntu-24.04.5-live-server-amd64.iso
ana@laptop:~/Downloads$ grep live-server-amd64 SHA256SUMS
c3514bf0056180d09376462a7a1b4f213c1d6e8ea67fae5c25099c6fd3d8274b *ubuntu-24.04.3-live-server-amd64.iso
e907d92eeec9df64163a7e454cbc8d7755e8ddc7ed42f99dbc80c40f1a138433 *ubuntu-24.04.4-live-server-amd64.iso
97f3d7ffb032c3eb3b23d2c8be9cc76e60c2c1f2c0146ba5ba9fe01cafae0fd8 *ubuntu-24.04.5-live-server-amd64.iso
ana@laptop:~/Downloads$ sha256sum -c --ignore-missing SHA256SUMS
ubuntu-24.04.5-live-server-amd64.iso: OK
```

O `SHA256SUMS` lista todos os arquivos da versão, e `--ignore-missing` confere só os que você tem. O
`24.04.5` é a quinta atualização do 24.04, e o seu pode ser uma mais nova; qualquer `24.04` é o mesmo
sistema. `OK` é a única resposta aceitável. No Windows e no macOS o número vem de outro comando, e você o
compara a olho com a linha do seu arquivo:

```sh
Get-FileHash .\ubuntu-24.04.5-live-server-amd64.iso      # Windows, in PowerShell
shasum -a 256 ubuntu-24.04.5-live-server-amd64.iso       # macOS, in Terminal
```

**Esses dois não foram rodados para este curso.** A aula 3 volta ao porquê de a conferência importar.

## 2. Crie a máquina virtual

No VirtualBox, *New*, e estas respostas. O UTM e os outros fazem as mesmas perguntas com outras palavras.

- *Name*: `server`. *Type*: Linux, *Ubuntu (64-bit)*. *ISO image*: o arquivo que você baixou.
- *Skip Unattended Installation*: **marque.** Senão o VirtualBox responde o instalador por você, e o
  instalador é o assunto da aula 3.
- *Memory*: 2048 MB. *Processors*: 2. *Hard disk*: 25 GB, sem pré-alocar.

Ligue a máquina. Ela inicia pelo ISO, como um computador de verdade inicia por um pendrive.

## 3. Instale

Responda o instalador assim, e a aula 3 diz o que cada escolha significa:

- Idioma e teclado: o idioma em que você lê e **o teclado que você tem de fato**, porque é nele que a sua
  senha vai ser digitada.
- *Ubuntu Server*, não o *minimized*. A rede como vier. *Use an entire disk*: o virtual, que está vazio.
- *Your name*, qualquer um. *Your server's name*: `server`. *Pick a username*: o seu. As transcrições
  dizem `ana`, e as suas vão dizer o seu nome onde elas dizem o dela. Uma senha que você não vá esquecer.
- *Ubuntu Pro*: pule. *Install OpenSSH server*: **marque.** Featured snaps: nenhum.

Quando ele disser que a instalação terminou, escolha *Reboot Now* e tecle Enter se ele pedir para tirar
a mídia de instalação. Entre com o seu usuário e a sua senha.

## 4. Olhe para ele e atualize

```
ana@server:~$ hostname
server
ana@server:~$ grep PRETTY_NAME /etc/os-release
PRETTY_NAME="Ubuntu 24.04.5 LTS"
ana@server:~$ id
uid=1000(ana) gid=1000(ana) groups=1000(ana),27(sudo)
```

O nome certo, o sistema certo e a sua conta no grupo `sudo`, que a deixa rodar comandos de administrador.
Depois as atualizações, que a aula 3 desmonta linha por linha:

```sh
sudo apt update
sudo apt upgrade -y
```

## 5. PowerShell 7

O PowerShell não está no catálogo do próprio Ubuntu, então o `apt` não o encontra até você acrescentar o
da Microsoft. O número da versão em `/etc/os-release` escolhe o catálogo certo:

```
ana@server:~$ source /etc/os-release
ana@server:~$ wget -q https://packages.microsoft.com/config/ubuntu/$VERSION_ID/packages-microsoft-prod.deb
ana@server:~$ sudo dpkg -i packages-microsoft-prod.deb
Selecting previously unselected package packages-microsoft-prod.
(Reading database ... 37575 files and directories currently installed.)
Preparing to unpack packages-microsoft-prod.deb ...
Unpacking packages-microsoft-prod (1.2-ubuntu24.04) ...
Setting up packages-microsoft-prod (1.2-ubuntu24.04) ...
ana@server:~$ sudo apt update > apt.log 2>&1; grep microsoft apt.log
Get:5 https://packages.microsoft.com/ubuntu/24.04/prod noble InRelease [3600 B]
Get:6 https://packages.microsoft.com/ubuntu/24.04/prod noble/main amd64 Packages [519 kB]
Get:7 https://packages.microsoft.com/ubuntu/24.04/prod noble/main arm64 Packages [463 kB]
Get:8 https://packages.microsoft.com/ubuntu/24.04/prod noble/main all Packages [643 B]
Get:9 https://packages.microsoft.com/ubuntu/24.04/prod noble/main armhf Packages [12.6 kB]
ana@server:~$ sudo apt install -y powershell > pwsh.log 2>&1; grep "^Setting up" pwsh.log
Setting up powershell (7.6.6-1.deb) ...
ana@server:~$ pwsh --version
PowerShell 7.6.6
```

O pacote `packages-microsoft-prod` não traz programa nenhum, só o endereço do catálogo da Microsoft e a
chave que prova que um pacote veio de lá. Depois dele, o `apt update` lê esse catálogo também, e o
`powershell` é encontrado como qualquer outro pacote; a aula 11 é sobre como isso funciona. Digite `pwsh`
e o prompt vira `PS /home/ana>`, que é como começa cada linha de PowerShell deste curso; `exit` volta
para o bash.

## 6. Guarde a máquina como está agora

No VirtualBox, *Snapshots*, *Take*, com o nome `fresh`. Um snapshot é a máquina inteira naquele momento.
Quando uma aula mais adiante deixar o servidor num estado que você não consegue explicar, *Restore* o põe
de volta em segundos. O Hyper-V chama a mesma coisa de *checkpoint*; no UTM, faça *Clone* da máquina
desligada e guarde a cópia.

**Digitar do seu próprio terminal** é opcional e agradável: a janela do servidor não deixa colar, e o
seu terminal deixa. No VirtualBox, *Settings*, *Network*, *Advanced*, *Port Forwarding*, acrescente uma
regra da porta `2222` do computador para a porta `22` da máquina e então, no seu computador:

```sh
ssh -p 2222 ana@127.0.0.1      # your username, not ana
```

**Não foi rodado para este curso**, como nenhum passo desta seção que acontece fora do servidor.
