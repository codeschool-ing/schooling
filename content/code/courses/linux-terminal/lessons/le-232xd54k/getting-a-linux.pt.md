---
title: Conseguindo um Linux para praticar
version: 2
---

Esta seção não ensina Linux nenhum, e é a seção sem a qual o resto do curso não funciona. **Tudo
depois daqui assume que você tem um prompt na sua frente** — não um vídeo de um, não um diagrama:
um de verdade, no qual você possa digitar e que você possa quebrar.

Ler sobre comandos não produz a habilidade. A habilidade está nas suas mãos, e ela chega por
repetição numa máquina que é sua para estragar. Então: três jeitos de ter uma, o que cada um custa,
qual escolher, e o que fazer quando a montagem dá errado.

## O que "uma máquina para praticar" precisa ser

Três propriedades, e elas eliminam algumas opções que parecem convenientes:

1. **Você pode quebrá-la.** Você vai rodar algo destrutivo sem querer. Isso tem de ser um
   contratempo de dez minutos, e não um desastre.
2. **Você pode jogá-la fora e pegar outra nova.** Começar limpo é uma ferramenta de aprendizado,
   não uma admissão de fracasso.
3. **É um Linux de verdade, que dá boot.** Não um simulador, não um site que finge. O assunto
   inteiro é como o sistema realmente se comporta, e a aula 5 é sobre o que acontece quando ele
   liga.

## Três jeitos

| | o que é | o que te custa | as transcrições |
|---|---|---|---|
| **uma máquina virtual** (recomendado) | um computador inteiro simulado dentro do seu, rodando o Ubuntu Server 24.04 LTS | software livre, 25 GB de disco, 2 a 3 GB de memória enquanto ela roda | batem, fora nomes, números e datas |
| **instalado** | o Linux no próprio computador, como sistema único ou ao lado do que ele já tem | nada, se ele já roda Linux; uma partição livre e um reboot se não roda | batem no Ubuntu 24.04, ficam perto nos outros |
| **online** | a máquina de outra pessoa, alugada por hora ou emprestada de uma cota mensal | nada no seu computador; dinheiro, ou a cota que uma empresa decide | ficam perto, e a aula 5 pode não funcionar |

## O recomendado: uma máquina virtual

**Crie uma máquina virtual e instale nela o Ubuntu Server 24.04 LTS.** É o único caminho que tem as
três propriedades: um erro fica dentro dela, um snapshot tirado logo depois da instalação a traz de
volta em um minuto, e ela dá boot, então os serviços da aula 5 e os timers da aula 13 estão lá por
inteiro. É também o que é a maioria das máquinas de que você vai cuidar no trabalho: um servidor sem
desktop, acessado por um terminal.

O custo dá para medir. A documentação do próprio Ubuntu para o 24.04 pede **pelo menos 1,5 GB de
memória e 5 GB de disco** para instalar pela ISO, e sugere 3 GB e 25 GB para uma máquina que faça
algum trabalho de verdade. Dê a ela **2 GB de memória se o seu computador tem 8 GB, e 4 GB se tem
16**, dois processadores e um disco de 25 GB. O disco cresce conforme é escrito, então uma
instalação nova ocupa alguns gigabytes dos 25, não todos. A memória só é tomada enquanto a máquina
está ligada.

O programa que a roda depende do que o seu computador já é:

| seu computador | o hipervisor | |
|---|---|---|
| **Windows 10 ou 11** | **WSL 2**, que é uma máquina virtual que o Windows administra por você | `wsl --install -d Ubuntu-24.04` no PowerShell, depois reiniciar |
| | ou o VirtualBox, grátis | a instalação completa abaixo, igual à de qualquer outro computador |
| **macOS, Apple silicon** (M1 em diante) | o UTM, grátis | a ISO de servidor **ARM**: o Ubuntu publica uma para o 24.04 |
| **macOS, Intel** | o VirtualBox, grátis | a ISO de servidor comum |
| **Linux** | o virt-manager, que comanda o KVM; ou o VirtualBox | a ISO de servidor comum |

**O WSL é o atalho no Windows, e ele conta como este caminho.** Ele dá boot num kernel Linux de
verdade, as versões atuais iniciam o systemd, e ele pula o instalador. O que ele não te dá é o
próprio instalador, o console e um botão de snapshot. Se você quiser essas coisas, use o VirtualBox.
Dentro do WSL, trabalhe do lado Linux: a sua casa é `/home/<você>`, e o disco do Windows aparece em
`/mnt/c`, onde os arquivos são mais lentos e carregam finais de linha do Windows, que é o assunto
da seção 12.

**Em todo o resto, a instalação são as mesmas cinco decisões**, seja qual for o hipervisor que as
pergunta:

1. Baixe a ISO do Ubuntu Server 24.04 LTS em `ubuntu.com/download/server`.
2. Crie uma máquina com a memória, os processadores e o disco acima, e aponte o drive óptico dela
   para a ISO.
3. Ligue-a e aceite os padrões do instalador, com duas exceções. **O seu nome e o nome do
   servidor:** toda transcrição deste curso mostra `ana@vm` — `ana` a usuária, `vm` a máquina — e a
   sua vai mostrar o que você escolher. **"Install OpenSSH server": marque.** A aula 5 se conecta à
   máquina por SSH.
4. Quando ele pedir, remova a ISO e reinicie, e então entre no console com o nome e a senha que
   você escolheu.
5. **Desligue-a e tire um snapshot.** Chame de `clean`. Esse snapshot é o "jogar fora e pegar outra
   nova" da lista acima.

## Os outros dois, nomeados

**Instalado.** Se o seu computador já roda Linux, você tem uma máquina e ela não custa nada. O
Ubuntu 24.04 bate com todas as transcrições daqui; outra distribuição bate com a maioria, e a aula 2
diz o que muda. O custo é a primeira propriedade da lista: as aulas 4, 5 e 7 mexem em usuários,
serviços e pacotes, e um erro ali acontece no computador em que você trabalha. Instalar o Linux ao
lado do Windows (um *dual boot*) é o mesmo caminho com uma partição para criar antes, e dá mais
trabalho do que uma máquina virtual para um curso.

**Online.** Um provedor de nuvem aluga um servidor Linux por hora, e alguns serviços de
desenvolvimento emprestam um terminal no navegador a partir de uma cota mensal grátis. Não custa
nada ao seu computador, o que faz dele o caminho para um computador que não consegue rodar uma
máquina virtual. Custa dinheiro ou uma cota, em termos que a empresa define e pode mudar, então
nada neste curso depende de um. Duas coisas para conferir antes de começar: `cat /etc/os-release`,
abaixo, diz qual Linux te emprestaram; e um terminal no navegador muitas vezes é **um contêiner**,
e não uma máquina, que é o assunto da próxima parte.

**Num Mac, o Terminal não é um quarto caminho.** Ele abre na hora e a maioria dos comandos funciona,
então você vai ser tentado. Ele é um userland BSD: flags mudam, o `sed -i` se comporta diferente,
não existe `/proc`, não existe `apt` e não existe systemd. Serve para as aulas 3 e 4 e é ativamente
enganoso para 2, 5, 7 e 11. Use-o pela conveniência, e tenha um Linux de verdade para o curso.

## Um contêiner é rápido, e não basta

Você vai encontrar contêineres cedo, e um deles é um Linux descartável completo em um segundo:

```
docker run -it --rm ubuntu:24.04 bash
```

`-it` te dá um terminal, `--rm` apaga a máquina quando você sair, `bash` é o que rodar lá dentro.
Quando você digita `exit`, tudo o que você fez some, que é justamente a graça.

Ele falha na terceira propriedade, e o curso encontra essa falha na aula 5. **Um contêiner não dá
boot.** Ele roda um programa, não o equivalente a uma máquina inteira deles, então o gerenciador de
serviços que o Linux de todo mundo inicia primeiro não está lá. Use um para dar uma olhada rápida em
outra distribuição, que a aula 2 faz; não use um como a máquina deste curso.

## Confira se o que você tem é o que você pensa

O primeiro reflexo deste curso, e você vai usá-lo por anos: quando chegar numa máquina, pergunte a
ela o que ela é.

```
ana@vm:~$ cat /etc/os-release
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

`ID` e `ID_LIKE` são as duas linhas que importam, e a aula 2 explica por quê: elas dizem em qual
família você está, o que diz o gerenciador de pacotes, os nomes dos serviços e metade dos caminhos.

E pergunte quem você é:

```
ana@vm:~$ id
uid=1001(ana) gid=1002(ana) groups=1002(ana),27(sudo)
```

Um usuário comum, com um número, num grupo chamado `sudo` — que é o que deixa esta conta agir como o
administrador, um comando de cada vez, e é o assunto da aula 4. Numa máquina que você acabou de
instalar o número muito provavelmente é `1000`, porque a primeira conta criada numa máquina fica com
ele. Esta já tinha uma conta antes da `ana`, então a dela é `1001`, e um instalador pode te pôr em
mais alguns grupos do que estes. Se o `id` disser `uid=0(root)`, você é o próprio administrador, o
que é muito comum dentro de contêineres e é discutido na seção 14.

## Quando a montagem falha

É aqui que a maioria das pessoas para, então aqui estão as falhas que acontecem, cada uma com a cara
que tem e o que fazer.

**O hipervisor não liga a máquina, ou liga insuportavelmente devagar.** Uma máquina virtual precisa
das extensões de virtualização do processador — a Intel as chama de VT-x, a AMD de AMD-V — e muitos
computadores saem de fábrica com elas desligadas no firmware. Num computador com Linux, um programa
pergunta, e `sudo apt install cpu-checker` o instala:

```
ana@vm:~$ sudo kvm-ok
[sudo] password for ana:
INFO: Your CPU does not support KVM extensions
KVM acceleration can NOT be used
```

Essa é a resposta de uma máquina cujo processador não oferece nenhuma — esta é ela própria uma
máquina virtual, e nada foi repassado a ela. No seu computador, a correção fica nas configurações do
firmware, a tela que uma tecla como F2, F10 ou Del abre enquanto ele liga: ative *Intel
Virtualization Technology*, *SVM* ou *AMD-V*, seja qual for o nome que ele usa, salve e reinicie. No
Windows, o WSL precisa da mesma configuração, e do recurso *Plataforma de Máquina Virtual* do
próprio Windows, que o `wsl --install` liga e que só vale depois do reinício que ele pede.

**O instalador para, ou a máquina trava durante ele.** Pouca memória, quase sempre. Dê a ela os 2 GB
acima, e não 1 GB que um hipervisor às vezes oferece por padrão, e comece de novo: nada no seu
computador foi tocado.

**A máquina está ligada e o `apt` não sai do lugar.** Um Ubuntu novo instala sozinho as suas
atualizações de segurança nos primeiros minutos depois do boot, e enquanto isso nada mais pode
instalar coisa alguma:

```
ana@vm:~$ sudo apt install tree
[sudo] password for ana:

WARNING: apt does not have a stable CLI interface. Use with caution in scripts.

Waiting for cache lock: Could not get lock /var/lib/dpkg/lock-frontend. It is held by process 8129 (unattended-upgr)...
```

`unattended-upgr` é o programa que faz as atualizações, com o nome cortado em quinze caracteres, e o
`apt` repete essa última linha a cada segundo enquanto espera. Deixe-o e ele segue sozinho quando as
atualizações terminarem; ou aperte Ctrl+C e rode o comando de novo daqui a alguns minutos. **Nunca
apague o arquivo de trava**: ele existe porque dois programas escrevendo no banco de pacotes ao mesmo
tempo é como uma máquina acaba com meio pacote instalado. (O aviso acima dele é assunto da aula 7.)

**Falta um comando.** O Ubuntu Server vem sem algumas coisas que você vai ver no curso, e a resposta
diz qual pacote o tem:

```
ana@vm:~$ tree
Command 'tree' not found, but can be installed with:
sudo apt install tree
```

`sudo apt install tree` o instala, e a aula 7 é sobre tudo o que essa linha faz.

**O `systemctl` diz que o sistema não deu boot.** Você está num contêiner, não numa máquina:

```
ana@vm:~$ systemctl status
System has not been booted with systemd as init system (PID 1). Can't operate.
Failed to connect to bus: Host is down
```

Nada está quebrado. Não há gerenciador de serviços rodando, porque nada deu boot. A maior parte do
curso ainda funciona ali; a aula 5 e os timers da aula 13 precisam da máquina virtual. As
transcrições deste curso foram capturadas numa máquina assim, e a aula 5 diz onde isso aparece.

**E se tudo der errado depois de ter funcionado,** volte ao snapshot. É para isso que ele existe.

## Antes de seguir

Você deveria conseguir fazer isto, agora, antes de continuar lendo:

1. abrir um terminal e ver um prompt;
2. digitar `whoami`, apertar enter, e ver um nome;
3. digitar `uname -s` e ver `Linux`;
4. digitar algo que não existe — `ola` serve — e ler o que volta.

O quarto não é piada. É a primeira mensagem de erro do curso, e a seção 17 passa o tempo dela
exatamente nessa linha. Levar uma recusa de uma máquina que você acabou de montar é um começo
melhor do que não levar nada.

## Os arquivos que esta aula usa

As seções à frente listam e leem alguns arquivos pequenos. Crie-os agora, para que o que você vê
bata com o que a página mostra. Copie isto para o terminal como está; roda em alguns milissegundos e
não imprime nada:

```sh
mkdir -p ~/notes ~/demo/folder ~/plain/folder ~/case ~/crlf
cd ~/demo
printf 'first line\nsecond line\nthird line\nfourth line\n' > readme.txt
printf 'x\n' > ./-strange
printf 'abc\n' > 'with space.txt'
touch .hidden
cp readme.txt .hidden ~/plain/
cd ~/case
touch NOTES.TXT Notes.txt notes.txt
printf 'not a PDF at all\n' > report.pdf
cd ~/crlf
printf '#!/bin/bash\necho "hello"\n' > unix.sh
printf '#!/bin/bash\r\necho "hello"\r\n' > windows.sh
printf '#!/bin/bash\r\nif [ -n "$HOME" ]; then\r\n  echo "home is set"\r\nfi\r\n' > vars.sh
chmod +x unix.sh windows.sh vars.sh
cd
```

O `printf` escreve exatamente o que recebe, com `\n` como o fim de uma linha e `\r\n` como o fim de
uma linha do jeito que o Windows escreve, que é o assunto da seção 12. Você não precisa entender
nada disso ainda: na aula 3 cada linha dele já é corriqueira.
