---
title: Medindo com o Lynis
version: 1
---

**O Lynis é um auditor que roda na própria máquina que audita.** Ele lê arquivos de configuração,
pergunta aos serviços o que fazem e imprime um achado para cada verificação que não passou. Não muda
nada. É um script de shell, não precisa de agente nem de servidor, e está no repositório do Ubuntu,
então o laboratório o instalou em todas as máquinas.

Suba o laboratório com `sudo bash hostlab.sh up web admin`. O `web` é o portal do jeito que foi
entregue: tudo o que a aula 1 removeu está de volta, porque toda aula começa de um `up` novo. Audite:

```
ana@web:~$ sudo lynis audit system --quick --no-colors > lynis.txt 2>&1; grep -E "Hardening index|Tests performed" lynis.txt
  Hardening index : 69 [#############       ]
  Tests performed : 259
```

`--quick` pula as pausas entre as seções, e o relatório completo vai para `lynis.txt` porque tem
várias centenas de linhas. As duas linhas guardadas são o resumo. O **índice de endurecimento** é a
nota do próprio Lynis, de 0 a 100, ponderada pelas verificações que passaram, e só serve comparado
consigo mesmo: a mesma máquina antes e depois de uma mudança. Duas máquinas com o mesmo índice podem
estar erradas de jeitos completamente diferentes.

## Primeiro os avisos

O Lynis grava uma cópia legível por máquina de cada resultado em `/var/log/lynis-report.dat`, um por
linha, que é mais fácil de ler que a tela:

```
ana@web:~$ sudo grep '^warning' /var/log/lynis-report.dat | cut -d'|' -f1,2
warning[]=AUTH-9204|Multiple users with UID 0 found in passwd file
warning[]=AUTH-9208|Multiple accounts found with same UID
warning[]=PKGS-7392|Found one or more vulnerable packages.
warning[]=NETW-2704|Nameserver 8.8.8.8 does not respond
warning[]=NETW-2704|Nameserver 8.8.4.4 does not respond
warning[]=NETW-2705|Couldn't find 2 responsive nameservers
warning[]=FIRE-4512|iptables module(s) loaded, but no rules active
warning[]=FINT-4315|No AIDE configuration file was found, needed for AIDE functionality
```

Um **aviso** é um achado que o Lynis acha que pede ação. Dois deles são o segundo root da aula 1,
encontrado por duas verificações diferentes. Um diz que há pacotes vulneráveis instalados, assunto da
aula 16, e um que o monitoramento de integridade de arquivos não tem configuração, assunto da aula 11.
Três são sobre servidores de nomes que não respondem e um diz que o firewall não tem regras:
verdade, e sobre o laboratório e não sobre o portal, porque nada no laboratório alcança a internet e
a aula 5 escreve o firewall. **Ler um aviso é decidir de que tipo ele é.**

## Depois as sugestões

```
ana@web:~$ sudo grep -c '^suggestion' /var/log/lynis-report.dat
43
ana@web:~$ sudo grep -E '^suggestion.*(AUTH|BANN|KRNL-5820|FILE-6310)' /var/log/lynis-report.dat | cut -d'|' -f1,2
suggestion[]=KRNL-5820|If not required, consider explicit disabling of core dump in /etc/security/limits.conf file
suggestion[]=AUTH-9230|Configure password hashing rounds in /etc/login.defs
suggestion[]=AUTH-9262|Install a PAM module for password strength testing like pam_cracklib or pam_passwdqc
suggestion[]=AUTH-9282|When possible set expire dates for all password protected accounts
suggestion[]=AUTH-9284|Look at the locked accounts and consider removing them
suggestion[]=AUTH-9286|Configure minimum password age in /etc/login.defs
suggestion[]=AUTH-9286|Configure maximum password age in /etc/login.defs
suggestion[]=AUTH-9328|Default umask in /etc/login.defs could be more strict like 027
suggestion[]=FILE-6310|To decrease the impact of a full /home file system, place /home on a separate partition
suggestion[]=FILE-6310|To decrease the impact of a full /var file system, place /var on a separate partition
suggestion[]=BANN-7126|Add a legal banner to /etc/issue, to warn unauthorized users
suggestion[]=BANN-7130|Add legal banner to /etc/issue.net, to warn unauthorized users
```

Uma **sugestão** é uma verificação que não passou e que o Lynis não considera urgente. Cada uma cita
o id do teste, e o id é o que a torna acionável: `lynis show details` imprime o que o teste olhou.

```
ana@web:~$ sudo lynis show details AUTH-9204 | head -8
2026-10-23 02:04:03 Performing test ID AUTH-9204 (Check users with an UID of zero)
2026-10-23 02:04:03 Test: Searching accounts with UID 0
2026-10-23 02:04:03 Result: Found more than one administrator accounts
2026-10-23 02:04:03 Warning: Multiple users with UID 0 found in passwd file [test:AUTH-9204] [details:-] [solution:-]
2026-10-23 02:04:03 Administrator account: suporte:0
2026-10-23 02:04:03 ====
```

Leia como uma lista de perguntas, não de ordens. Um aviso legal em `/etc/issue` é um argumento que
alguns departamentos jurídicos fazem e outros não. Uma partição separada para `/home` é impossível de
fazer num servidor em produção e sem sentido num contêiner. Desligar core dumps é barato e vale a
pena. Cada uma pede uma decisão, e a decisão é sobre esta máquina.

**O que o Lynis não tem como saber também importa.** Nenhum dos seus 259 testes sabe que esta máquina
é um portal cujo trabalho são duas portas, então nenhum dos seus oito avisos fala do servidor FTP, do
telnet ou da community SNMP `public` que a aula 1 achou em minutos. Um auditor conhece as
verificações; só você conhece o trabalho, e é por isso que a linha de base que você escreve mais
adiante nesta aula é sua.
