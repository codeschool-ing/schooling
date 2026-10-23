---
title: Serviços que ninguém pediu
version: 1
---

**Uma varredura de fora diz o que responde. A própria máquina diz quem está respondendo.** O `ss`
lista cada socket esperando uma conexão, e `-p` acrescenta o processo que o segura, coisa que só o
root pode ver para processos de outros usuários. O `awk` no fim guarda três colunas, o protocolo, o
endereço e porta, e o nome do programa, porque a linha completa é mais larga que qualquer tela:

```
ana@web:~$ sudo ss -Htulpn | awk '{split($7, p, "\""); print $1, $5, p[2]}'
udp 0.0.0.0:54453 avahi-daemon
udp 0.0.0.0:5353 avahi-daemon
udp 0.0.0.0:111 rpcbind
udp 0.0.0.0:161 snmpd
tcp 0.0.0.0:22 sshd
tcp 0.0.0.0:23 inetd
tcp 0.0.0.0:21 vsftpd
tcp 0.0.0.0:111 rpcbind
tcp 0.0.0.0:80 nginx
tcp 127.0.0.1:8080 python3
```

Tudo o que a varredura achou está aqui, com um nome do lado, e mais duas coisas que ela não
conseguia ver. O daemon do avahi também segura uma porta UDP alta e aleatória para as próprias
consultas. E o `python3` escuta em `127.0.0.1:8080`, o endereço de loopback, que só programas no
próprio `web` alcançam: é o portal, e o nginx na porta 80 é a porta de entrada dele. **Um endereço
`0.0.0.0` quer dizer todas as interfaces que a máquina tem**, então esses serviços respondem a
qualquer um que consiga chegar ao `web`.

Um listener pertence a um processo, e no Ubuntu um processo pertence a uma **unidade** do systemd,
que é o que você liga e desliga. Estes são os serviços rodando:

```
ana@web:~$ systemctl list-units --type=service --state=running --no-legend --plain | cut -d" " -f1
avahi-daemon.service
console-getty.service
cron.service
dbus.service
fail2ban.service
inetd.service
nginx.service
portal.service
rpcbind.service
rsyslog.service
snmpd.service
ssh.service
systemd-journald.service
systemd-logind.service
unattended-upgrades.service
vsftpd.service
wpa_supplicant.service
```

Leia contra o trabalho. `nginx`, `portal` e `ssh` são o trabalho. `cron`, `dbus`, `rsyslog`,
`systemd-journald` e `systemd-logind` são o próprio sistema. `fail2ban` e `unattended-upgrades` são
proteções que o Ubuntu instala, e as aulas 11 e 17 as colocam para trabalhar. `console-getty` é o
prompt de login no console do contêiner. Sobram `avahi-daemon`, `inetd`, `rpcbind`, `snmpd` e
`vsftpd`, os cinco por trás das oito portas, e `wpa_supplicant`, que não escuta em porta nenhuma e é
assunto da última seção.

Dois deles se apresentam a quem conectar, antes de qualquer login:

```
ana@desk:~$ printf "quit\r\n" | nc -w2 web 21
220 (vsFTPd 3.0.5)
221 Goodbye.
ana@desk:~$ snmpget -v2c -c public web 1.3.6.1.2.1.1.5.0
iso.3.6.1.2.1.1.5.0 = STRING: "web"
ana@desk:~$ snmpwalk -v2c -c public web 1.3.6.1.2.1.25.4.2.1.2 | wc -l; snmpwalk -v2c -c public web 1.3.6.1.2.1.25.6.3.1.2 | wc -l
23
322
```

O servidor FTP diz o nome e a versão exata na primeira linha. O agente SNMP recebeu o pedido do nome
da máquina com a community string `public`, o padrão que toda ferramenta de varredura tenta primeiro,
e respondeu. A mesma pergunta com outros números devolve os 23 processos em execução e 308 linhas de software
instalado, como mostram as duas contagens do fim: um mapa da máquina, entregue a quem pedir.

## Parar um nem sempre é pará-lo

`systemctl disable --now` para um serviço e impede que ele suba no boot. Experimente no `rpcbind`:

```
ana@web:~$ sudo systemctl disable --now rpcbind
Synchronizing state of rpcbind.service with SysV service script with /usr/lib/systemd/systemd-sysv-install.
Executing: /usr/lib/systemd/systemd-sysv-install disable rpcbind
Removed "/etc/systemd/system/sockets.target.wants/rpcbind.socket".
Removed "/etc/systemd/system/multi-user.target.wants/rpcbind.service".
Disabling 'rpcbind.service', but its triggering units are still active:
rpcbind.socket
Stopping 'rpcbind.service', but its triggering units are still active:
rpcbind.socket
ana@web:~$ sudo ss -Htulpn | grep ':111 '
udp UNCONN 0      0        0.0.0.0:111   0.0.0.0:* users:(("systemd",pid=1,fd=116))                                                                                     
tcp LISTEN 0      4096     0.0.0.0:111   0.0.0.0:* users:(("systemd",pid=1,fd=115))                                                                                     
```

O serviço parou, e a porta 111 continua aberta, agora segura pelo próprio `systemd`, o processo 1.
Isto é **ativação por socket**: a unidade `rpcbind.socket` faz o systemd escutar na porta em nome do
serviço e iniciá-lo quando chega a primeira conexão. O systemd disse isso nos dois avisos acima, e são
as linhas que as pessoas pulam. Desabilitar o serviço deixou o socket no comando, então o próximo
cliente a bater teria iniciado o `rpcbind` de novo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l01-socket\" aria-label=\"Ativação por socket em três passos. Um: o systemd, processo 1, escuta na porta 111 em nome do rpcbind.socket, enquanto o rpcbind.service não está rodando. Dois: um cliente conecta na porta 111. Três: o systemd inicia o rpcbind.service e entrega o socket a ele. Desabilitar só o serviço deixa o passo um no lugar, então o próximo cliente o inicia de novo.\"><defs><marker id=\"l01-socket-dh-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l01-socket-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"250.0\" y=\"40.0\" width=\"220.0\" height=\"60.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">systemd (pid 1)</text><text x=\"360.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">escuta na :111 pelo rpcbind.socket</text><rect x=\"250.0\" y=\"170.0\" width=\"220.0\" height=\"50.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 3\"></rect><text x=\"360.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">rpcbind.service</text><text x=\"360.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">desabilitado, parado</text><rect x=\"30.0\" y=\"50.0\" width=\"130.0\" height=\"40.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"95.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um cliente</text><path d=\"M160.0 70.0 L250.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l01-socket-dh-ah-paper-dim)\"></path><text x=\"205.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2 conecta</text><path d=\"M360.0 100.0 L360.0 170.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l01-socket-dh-ah-amber)\"></path><text x=\"372.0\" y=\"128.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">3 inicia de novo,</text><text x=\"372.0\" y=\"143.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">e entrega o socket</text><text x=\"500.0\" y=\"62.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 ainda habilitado:</text><text x=\"500.0\" y=\"78.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">rpcbind.socket</text></svg>", "caption": "Desabilitar o serviço deixou o systemd segurando a porta. O socket tem de sair também."}
```

A correção é desabilitar o socket também, e o mesmo vale para o avahi:

```
ana@web:~$ sudo systemctl disable --now rpcbind.socket avahi-daemon.socket avahi-daemon 2>&1 | grep -v ^Removed
Disabling 'avahi-daemon.service', but its triggering units are still active:
avahi-daemon.socket
ana@web:~$ sudo ss -Htulpn | grep -cE ':(111|5353) '
0
```

`disable --now` num socket e no seu serviço juntos para os dois, e o `grep -c` não conta nenhum
listener sobrando na 111 ou na 5353. O aviso que fica é impresso enquanto o `systemctl` desabilita o
serviço, quando o socket ao lado dele no mesmo comando ainda não foi parado.

## Desabilitado, mascarado ou removido

Há três intensidades de "desligado", e cada uma serve para um caso.

| | o que faz | desfeito por | quando |
|---|---|---|---|
| `disable` | a unidade não sobe mais no boot | `enable` | você pode querer de volta, ou um pacote precisa dela instalada |
| `mask` | a unidade é ligada a `/dev/null`, então nada consegue iniciá-la, nem outra unidade que dependa dela | `unmask` | ela tem de continuar instalada e nunca pode rodar |
| `apt-get purge` | o pacote e a configuração dele saem da máquina | instalar de novo | ninguém precisa dele aqui |

**Num servidor, remover é o mais forte e o mais simples.** Um serviço desabilitado continua sendo um
binário em disco que uma atualização segue corrigindo, um arquivo de configuração que pode estar
errado e um `enable` de distância de rodar. Um removido não é nada disso. Remova os cinco:

```
ana@web:~$ sudo apt-get purge -y -q vsftpd openbsd-inetd inetutils-telnetd rpcbind avahi-daemon snmpd 2>&1 | grep -E "^(Removing|Purging)" | cut -d" " -f1,2
Removing avahi-daemon
Removing inetutils-telnetd
Removing openbsd-inetd
Removing rpcbind
Removing snmpd
Removing vsftpd
Purging configuration
Purging configuration
Purging configuration
Purging configuration
Purging configuration
Purging configuration
ana@web:~$ sudo ss -Htulpn | awk '{split($7, p, "\""); print $1, $5, p[2]}'
tcp 127.0.0.1:8080 python3
tcp 0.0.0.0:80 nginx
tcp 0.0.0.0:22 sshd
```

Seis pacotes saíram, com a configuração: o `inetd` e o servidor telnet que ele rodava eram dois. A
máquina agora escuta exatamente no que o trabalho precisa, SSH na 22, nginx na 80 e o portal no
endereço de loopback, atrás do nginx.

**Remover numa máquina que você não montou exige uma pergunta antes: quem usa isto?** Um serviço que
parece parado pode ser aquele a que um job mensal se conecta. Aqui a resposta é conhecida, porque o
trabalho é conhecido. Numa rede de verdade a resposta vem do inventário da aula 18, dos logs ou de
perguntar ao dono, e vale anotá-la junto da mudança, porque a próxima pessoa que der falta do FTP vai
perguntar por quê.
