---
title: Quando a montagem falha
version: 1
---

A maioria das pessoas que desiste de um curso como este desiste aqui, num erro sobre uma máquina que
ainda não terminou de montar. Estas são as falhas que acontecem de verdade, na ordem em que você as
encontraria.

**A máquina virtual não inicia, e a mensagem fala de virtualização, VT-x, AMD-V ou SVM.** O suporte do
processador a máquinas virtuais está desligado no firmware do computador, o menu da BIOS ou UEFI,
em geral em *Advanced* ou *CPU configuration*. Nenhum programa consegue ligá-lo por você. No Windows,
o Hyper-V e o WSL também podem ocupá-lo, e aí o VirtualBox roda devagar ou não roda.

**O `apt-get` diz que não conseguiu uma trava (lock).** O Ubuntu instala as próprias atualizações nos
primeiros minutos depois que uma máquina liga, e só um programa por vez pode instalar pacotes. Espere
alguns minutos e rode o comando de novo. Apagar o arquivo de trava é o conselho que você vai achar na
internet, e é assim que um banco de dados de pacotes se corrompe.

**O IPv6 continua lá.** Se `ls /proc/sys/net/ipv6` listar arquivos depois da reinicialização, o
carregador de boot não pegou a configuração. `cat /proc/cmdline` imprime a linha com que o kernel foi
iniciado, e `ipv6.disable=1` deveria estar nela. Se não estiver, confira se
`/etc/default/grub.d/99-netlab.cfg` tem a linha da seção 03, rode `sudo update-grub` de novo e
reinicie. O laboratório funciona com o IPv6 ligado, mas algumas das suas transcrições não vão bater
com as das aulas.

**Você esqueceu o `sudo`.** O laboratório cria dispositivos de rede para a máquina inteira, e só o
root pode:

```
ubuntu@netlab:~$ bash ~/netlab/netlab up
netlab builds and removes network devices for the whole machine: run it with sudo
```

**Falta um pacote.** O script confere cada pacote antes de montar qualquer coisa, e dá o nome dos que
não achou. Instale-os com `sudo apt-get install -y` e os nomes, e rode `up` de novo:

```
ubuntu@netlab:~$ sudo bash ~/netlab/netlab up
install first: swaks
```

**Um arquivo ficou cortado.** Uma colagem que parou antes do fim deixa um arquivo que parece certo em
cima e quebra embaixo. O bash lê uma função por vez e aponta o lugar onde o arquivo acabou, não onde a
colagem falhou:

```
ubuntu@netlab:~$ wc -l ~/netlab/dns.sh
100 /home/ubuntu/netlab/dns.sh
ubuntu@netlab:~$ sudo bash ~/netlab/netlab up
/home/ubuntu/netlab/dns.sh: line 100: warning: here-document at line 93 delimited by end-of-file (wanted `Z')
/home/ubuntu/netlab/dns.sh: line 101: syntax error: unexpected end of file
```

O `dns.sh` deve ter 172 linhas, como mostra a contagem da seção 08. Abra-o, apague tudo e cole de novo
o bloco inteiro da seção 05.

**As máquinas não estão lá.** Esta é a mensagem depois de uma reinicialização, ou antes do primeiro
`up`:

```
ubuntu@netlab:~$ sudo bash ~/netlab/netlab shell laptop
Cannot open network namespace "laptop": No such file or directory
```

`laptop` é um namespace de rede, e um namespace só existe enquanto o laboratório está montado. Rode
`up`.

**Você está num container, e não numa máquina virtual.** O Docker e muitos dos shells oferecidos num
navegador são containers, e um container em geral não tem permissão para criar namespaces de rede,
nem como o seu próprio root. A montagem para no primeiro `ip netns add` com
`mount --make-shared /run/netns failed: Operation not permitted`. Nenhuma configuração dentro do
container resolve isso; use uma máquina virtual.

**Algo no laboratório se comporta diferente de uma transcrição**, depois de uma aula que quebrou algo
ou de um experimento seu. Rode `sudo bash ~/netlab/netlab reset`. Custa dez segundos e põe cada
máquina de volta como os quatro arquivos descrevem.

**E quando nada mais funciona**, apague a máquina virtual e monte de novo: com o Multipass,
`multipass delete --purge netlab`, depois os comandos da seção 03 e os quatro arquivos outra vez.
Parece desistir. É o que quem cuida de redes faz com uma máquina cujo estado ninguém sabe mais
explicar, e é o motivo de tudo aqui ser montado a partir de arquivos que você pode ler.
