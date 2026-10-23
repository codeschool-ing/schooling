---
title: Achando as máquinas
version: 1
---

**Comece pelo que o escritório acredita ter.** Na Jatobá, essa crença é um arquivo curto mantido por
quem cuida da TI: uma linha por máquina, com endereço, papel, a pessoa responsável por ela e quanto o
escritório sofreria se a perdesse. Escreva-o no `admin` como `hosts.csv`:

```
name,address,role,owner,criticality
web,192.168.60.10,portal,Marta,high
desk,192.168.60.20,workstation,Rafael,low
admin,192.168.60.30,administration,Marta,high
jump,192.168.60.40,bastion,Marta,high
dns,192.168.60.53,resolver,Marta,medium
```

Cinco máquinas. Agora pergunte à rede. O `nmap -sn` não manda sondas de porta, só o bastante para
saber que endereços respondem, que é a pergunta mais leve que existe e aquela com que se começa
qualquer descoberta. Como em toda varredura deste curso, **faça-a só numa rede pela qual você
responde**:

```
ana@admin:~$ nmap -sn 192.168.60.0/24 | grep -E "report|done"
Nmap scan report for sw.jatoba.example (192.168.60.2)
Nmap scan report for web.jatoba.example (192.168.60.10)
Nmap scan report for desk.jatoba.example (192.168.60.20)
Nmap scan report for admin.jatoba.example (192.168.60.30)
Nmap scan report for jump.jatoba.example (192.168.60.40)
Nmap scan report for dns.jatoba.example (192.168.60.53)
Nmap scan report for trap.jatoba.example (192.168.60.66)
Nmap done: 256 IP addresses (7 hosts up) scanned in 2.31 seconds
```

Sete máquinas respondem onde o arquivo lista cinco. A diferença é o primeiro achado da aula, e o shell
consegue calculá-la: os endereços que o `nmap` achou e que não estão no arquivo.

```
ana@admin:~$ nmap -sn -oG - 192.168.60.0/24 | awk "/Up\$/{print \$2}" | sort > found.txt; cut -d, -f2 hosts.csv | tail -n +2 | sort > listed.txt; comm -23 found.txt listed.txt
192.168.60.2
192.168.60.66
```

Duas máquinas que ninguém listou. `192.168.60.2` é o `sw`, o switch: infraestrutura é o que mais fica
de fora de um inventário, e também é algo que pode ser mal configurado, rodar software desatualizado e
ser invadido. `192.168.60.66` é o `trap`, que a aula 13 transformou em honeypot de propósito; numa rede
de verdade, um endereço que responde e não aparece em registro nenhum é uma máquina que alguém ligou e
de que ninguém é dono. **A resposta é a mesma nos dois casos: ache o dono, depois decida**. Ou ela
entra na lista com um nome ao lado, ou sai da rede.

## O que uma varredura não vê

Uma varredura vê o que responde, no momento em que roda. Ela perde o notebook que está em casa esta
semana, a máquina cujo firewall descarta até essa sonda e tudo o que está em outro segmento. É por isso
que inventários de verdade combinam fontes: a varredura, as concessões do servidor DHCP, a tabela de
endereços de hardware que o switch viu em cada porta, assunto da aula 4, e os agentes que informam de
cada máquina onde quer que ela esteja. Cada uma pega algo que as outras perdem, e o inventário é a
união delas, conferida contra a lista.
