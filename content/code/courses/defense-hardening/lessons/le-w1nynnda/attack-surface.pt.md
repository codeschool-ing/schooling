---
title: O que é endurecimento, e por onde começa
version: 1
---

**Endurecer é tirar de uma máquina o que ela não precisa e apertar o que ela mantém.** Um servidor é
instalado para fazer um trabalho. Todo o resto que ele faz, cada serviço escutando numa porta, cada
conta que consegue entrar, cada programa que veio junto com um pacote, é algo que pode dar errado
sem ter feito bem nenhum. A soma dessas coisas é a **superfície de ataque** da máquina, e o primeiro
trabalho de quem defende é deixá-la tão pequena quanto o trabalho permite.

A imagem comum é a contrária: endurecer como acrescentar coisas, um produto de segurança aqui, uma
configuração mais forte ali. A maior parte deste curso acrescenta controles, sim, e as aulas 7 a 14
tratam deles. Mas um controle protege o que está lá, e o serviço mais barato de proteger é o que não
está rodando. Uma porta em que ninguém escuta não precisa de patch, de regra de firewall nem de
monitoramento.

**Não dá para tirar o que você não listou.** Esse é o princípio em que as outras dezoito aulas se apoiam, e a aula 18 o trata por inteiro.
O inventário, das máquinas e do que roda nelas, é a base de
qualquer defesa, porque um controle aplicado a "todos os nossos servidores" protege exatamente os
servidores de que alguém se lembrou. Esta aula começa pelo menor inventário que existe, uma máquina,
e faz dele o hábito de todas as aulas seguintes: **medir primeiro, mudar e medir de novo.**

## O portal como foi entregue

`web` é o portal de clientes da Jatobá, uma página servida pelo nginx na frente de um pequeno
programa em Python. O administrador anterior foi instalando coisas ao longo dos anos e não removeu
nenhuma. Você sabe do que o portal precisa, um servidor web e um jeito de um administrador entrar, e
de mais nada. Então comece por onde um atacante começaria, de outra máquina na mesma rede, e pergunte
a que o `web` responde. O `nmap` tenta uma conexão nas mil portas TCP mais comuns e informa quais
aceitaram:

```
ana@desk:~$ nmap web
Starting Nmap 7.94SVN ( https://nmap.org ) at 2026-10-23 09:46 -03
Nmap scan report for web (192.168.60.10)
Host is up (0.000084s latency).
rDNS record for 192.168.60.10: web.jatoba.example
Not shown: 995 closed tcp ports (conn-refused)
PORT    STATE SERVICE
21/tcp  open  ftp
22/tcp  open  ssh
23/tcp  open  telnet
80/tcp  open  http
111/tcp open  rpcbind

Nmap done: 1 IP address (1 host up) scanned in 0.05 seconds
ana@desk:~$ sudo nmap -sU -p 111,161,5353 web
Starting Nmap 7.94SVN ( https://nmap.org ) at 2026-10-23 09:46 -03
Nmap scan report for web (192.168.60.10)
Host is up (0.00018s latency).
rDNS record for 192.168.60.10: web.jatoba.example

PORT     STATE         SERVICE
111/udp  open          rpcbind
161/udp  open          snmp
5353/udp open|filtered zeroconf
MAC Address: 52:54:00:A8:3C:0A (QEMU virtual NIC)

Nmap done: 1 IP address (1 host up) scanned in 1.43 seconds
```

Cinco portas TCP aceitam conexão, onde o trabalho precisa de duas: **22** para o SSH e **80** para o
portal. A varredura UDP precisa de `sudo` porque monta os próprios pacotes, e encontra mais três
serviços. `open|filtered` na 5353 quer dizer que nenhuma resposta voltou, o que em UDP pode ser um
serviço que fica calado ou um firewall que descarta; a próxima seção pergunta à própria máquina.

Cada um desses oito é um programa com que alguém consegue conversar sem fazer login, e cada um vem
com os bugs que os autores ainda não acharam. FTP e telnet mandam senhas em texto claro pela rede. O
`rpcbind` existe para ajudar clientes a encontrar serviços NFS que esta máquina não oferece. O SNMP
versão 2 responde a quem souber a community string, e a próxima seção mostra que a desta é
`public`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l01-surface\" aria-label=\"O servidor do portal, web, desenhado duas vezes. À esquerda, como foi entregue: oito listeners na borda, TCP 21 ftp, 22 ssh, 23 telnet, 80 http e 111 rpcbind, e UDP 111 rpcbind, 161 snmp e 5353 mdns. Seis deles marcados como desnecessários para o trabalho. À direita, depois da aula: só TCP 22 ssh e TCP 80 http, e o próprio portal em 127.0.0.1:8080 dentro da caixa, alcançável só a partir da máquina.\"><text x=\"180.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">como foi entregue</text><text x=\"540.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">depois da aula 1</text><rect x=\"40.0\" y=\"50.0\" width=\"150.0\" height=\"220.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"52.0\" y=\"68.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">web</text><text x=\"52.0\" y=\"252.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">127.0.0.1:8080</text><rect x=\"190.0\" y=\"60.0\" width=\"130.0\" height=\"21.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"198.0\" y=\"70.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">tcp 21</text><text x=\"312.0\" y=\"70.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ftp</text><rect x=\"190.0\" y=\"85.0\" width=\"130.0\" height=\"21.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"198.0\" y=\"95.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">tcp 22</text><text x=\"312.0\" y=\"95.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ssh</text><rect x=\"190.0\" y=\"110.0\" width=\"130.0\" height=\"21.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"198.0\" y=\"120.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">tcp 23</text><text x=\"312.0\" y=\"120.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">telnet</text><rect x=\"190.0\" y=\"135.0\" width=\"130.0\" height=\"21.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"198.0\" y=\"145.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">tcp 80</text><text x=\"312.0\" y=\"145.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">http</text><rect x=\"190.0\" y=\"160.0\" width=\"130.0\" height=\"21.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"198.0\" y=\"170.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">tcp 111</text><text x=\"312.0\" y=\"170.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">rpcbind</text><rect x=\"190.0\" y=\"185.0\" width=\"130.0\" height=\"21.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"198.0\" y=\"195.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">udp 111</text><text x=\"312.0\" y=\"195.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">rpcbind</text><rect x=\"190.0\" y=\"210.0\" width=\"130.0\" height=\"21.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"198.0\" y=\"220.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">udp 161</text><text x=\"312.0\" y=\"220.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">snmp</text><rect x=\"190.0\" y=\"235.0\" width=\"130.0\" height=\"21.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"198.0\" y=\"245.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">udp 5353</text><text x=\"312.0\" y=\"245.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">mdns</text><rect x=\"400.0\" y=\"50.0\" width=\"150.0\" height=\"220.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"412.0\" y=\"68.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">web</text><text x=\"412.0\" y=\"252.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">127.0.0.1:8080</text><rect x=\"550.0\" y=\"85.0\" width=\"130.0\" height=\"21.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"558.0\" y=\"95.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">tcp 22</text><text x=\"672.0\" y=\"95.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ssh</text><rect x=\"550.0\" y=\"135.0\" width=\"130.0\" height=\"21.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"558.0\" y=\"145.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">tcp 80</text><text x=\"672.0\" y=\"145.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">http</text><text x=\"615.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">o trabalho, e mais nada</text><rect x=\"250.0\" y=\"280.0\" width=\"22.0\" height=\"12.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"280.0\" y=\"286.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">um listener de que o trabalho não precisa</text></svg>", "caption": "Oito listeners onde o trabalho precisa de dois. Cada aba marcada é um programa com que um estranho conversa."}
```

**Faça varredura só em máquinas pelas quais você responde.** O seu laboratório é seu, para sondar
como quiser. Fora dele, varrer as portas da rede de outra pessoa é, no melhor caso, uma violação dos
termos dela e, no pior, um crime, e uma varredura autorizada no trabalho é uma que alguém deixou por
escrito antes.
