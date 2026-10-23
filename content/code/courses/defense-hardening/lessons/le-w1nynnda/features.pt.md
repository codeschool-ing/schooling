---
title: Recursos que vieram junto, e a prova no fim
version: 1
---

**Um pacote traz mais que o programa que você queria.** Instalar uma coisa instala aquilo de que ela
depende, e o Ubuntu instala também o que ela recomenda. Com os anos, um servidor junta programas que
ninguém usa: clientes de protocolos que ninguém fala, ferramentas de que alguém precisou uma vez,
daemons para hardware que a máquina não tem. Nenhum deles escuta numa porta, então a varredura nunca
os mostra. Ainda assim precisam de atualização, e alguns rodam.

O `web` tem 316 pacotes instalados, e 156 deles foram pedidos pelo nome; os outros 160 vieram como
dependência:

```
ana@web:~$ dpkg -l | grep -c ^ii; apt-mark showmanual | wc -l
316
156
ana@web:~$ apt-cache rdepends --installed wpasupplicant hostapd
wpasupplicant
Reverse Depends:
hostapd
Reverse Depends:
ana@web:~$ systemctl is-active wpa_supplicant hostapd
active
inactive
```

`apt-cache rdepends --installed` lista que pacote instalado precisa de cada um, e para esses dois a
lista está vazia: nada na máquina depende de `wpasupplicant` nem de `hostapd`. São o cliente de Wi-Fi
e o ponto de acesso Wi-Fi, num servidor que não tem rádio. O laboratório instala um mesmo conjunto de
pacotes em todas as máquinas, e o `desk` e o `sw` precisam desses dois na aula 4; o portal nunca vai
precisar. O `wpa_supplicant` está rodando mesmo assim: o Ubuntu o habilita no boot em toda máquina que
o instala, com rádio ou sem rádio.

Remova os dois, mascarando antes o que está rodando, para que nada o inicie de novo enquanto o pacote
sai:

```
ana@web:~$ sudo systemctl mask --now wpa_supplicant 2>&1 | sed "s/ → .*//"
Created symlink /etc/systemd/system/wpa_supplicant.service
ana@web:~$ sudo apt-get purge -y -q hostapd wpasupplicant 2>&1 | grep -E "^(Removing|Purging)" | cut -d" " -f1,2
Removing hostapd
Removing wpasupplicant
Purging configuration
Purging configuration
```

**"Não precisa" tem de ser decidido por máquina, e anotado.** Os mesmos dois pacotes são a razão de
ser do `desk` na aula 4. Uma lista de pacotes a remover de "todos os servidores" é como alguém tira o
cliente de Wi-Fi do único notebook que precisava dele; o que decide é o trabalho da máquina.

## O que os serviços dizem de si mesmos

Alguns recursos não são pacotes, são comportamento, e o mais simples é um banner. O nginx diz o
próprio nome e a versão exata em cada resposta, e assim faz cada página do portal:

```
ana@web:~$ curl -s -D - -o /dev/null http://localhost/ | grep -i ^server
Server: nginx/1.24.0 (Ubuntu)
ana@web:~$ sudo sed -i "s/# server_tokens off;/server_tokens off;/" /etc/nginx/nginx.conf && sudo nginx -t 2>&1 | tail -1 && sudo systemctl restart nginx
nginx: configuration file /etc/nginx/nginx.conf test is successful
ana@web:~$ curl -s -D - -o /dev/null http://localhost/ | grep -i ^server
Server: nginx
```

Um número de versão num cabeçalho diz a quem o lê quais falhas publicadas tentar primeiro, e não diz
nada a quem defende. `server_tokens off` mantém o nome e tira a versão. É uma mudança pequena e não é
uma correção: um servidor desatualizado continua desatualizado, diga o que disser, e a aula 16 trata
de descobrir quais estão. O que ela tira é uma resposta de graça à primeira pergunta.

## Medir de novo

A aula começou com uma varredura a partir do `desk`, e termina com a mesma:

```
ana@desk:~$ nmap web
Starting Nmap 7.94SVN ( https://nmap.org ) at 2026-10-23 09:46 -03
Nmap scan report for web (192.168.60.10)
Host is up (0.000098s latency).
rDNS record for 192.168.60.10: web.jatoba.example
Not shown: 998 closed tcp ports (conn-refused)
PORT   STATE SERVICE
22/tcp open  ssh
80/tcp open  http

Nmap done: 1 IP address (1 host up) scanned in 0.04 seconds
ana@desk:~$ sudo nmap -sU -p 111,161,5353 web
Starting Nmap 7.94SVN ( https://nmap.org ) at 2026-10-23 09:46 -03
Nmap scan report for web (192.168.60.10)
Host is up (0.000073s latency).
rDNS record for 192.168.60.10: web.jatoba.example

PORT     STATE  SERVICE
111/udp  closed rpcbind
161/udp  closed snmp
5353/udp closed zeroconf
MAC Address: 52:54:00:A8:3C:0A (QEMU virtual NIC)

Nmap done: 1 IP address (1 host up) scanned in 0.24 seconds
```

**Duas portas TCP, as duas de que o trabalho precisa, e cada porta UDP que a primeira varredura
achou agora responde `closed`**, o que quer dizer que a máquina respondeu que não há nada ali. Entre as duas varreduras, uma máquina perdeu oito listeners, os seis pacotes por trás deles e mais dois sem motivo para estar ali.
Perdeu também um segundo root, duas senhas utilizáveis, dois shells e uma regra de `sudo`
que nunca deveria ter tido, e as duas opções do SSH que deixavam qualquer um tentar uma senha como
root.

Esse é o formato de todas as aulas deste curso: uma medição, uma mudança e a mesma medição de novo. A
aula 2 troca o olho por um guia que lista centenas dessas verificações e por uma ferramenta que as
executa.
