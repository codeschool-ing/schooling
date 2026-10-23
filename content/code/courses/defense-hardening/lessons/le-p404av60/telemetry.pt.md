---
title: Telemetria, e de onde ela vem
version: 1
---

**Telemetria é o registro do que aconteceu numa máquina, guardado para que alguém possa perguntar
sobre isso depois.** Três tipos carregam a maior parte do peso num servidor, e o `web` já produz
dois deles sem ninguém instalar nada.

**Processos, com os pais.** Todo programa em execução tem um pai, o processo que o iniciou, e a
árvore que eles formam é a coisa mais útil que um analista consegue ler. No `web`, o portal e a
porta de entrada dele ficam assim:

```
ana@web:~$ ps -eo user,pid,ppid,args --forest | grep -E "nginx|portal|sshd" | grep -v grep
portal        55       1 /usr/bin/python3 /opt/portal/portal.py
root          73       1 nginx: master process /usr/sbin/nginx -g daemon on; master_process on;
www-data      74      73  \_ nginx: worker process
www-data      75      73  \_ nginx: worker process
www-data      76      73  \_ nginx: worker process
www-data      77      73  \_ nginx: worker process
```

Leia a árvore. O mestre do nginx roda como root e os quatro workers como `www-data`; o portal é um
processo Python com a conta `portal`, iniciado pelo systemd, o processo 1. Esse é o formato normal,
e vale conhecê-lo antes de algo dar errado, porque um alerta é uma diferença em relação a ele. Um
`bash` pendurado debaixo do processo do portal, ou do nginx, seria a história inteira em uma linha.

**Logins.** O journal já registra cada sessão SSH, com a conta, o endereço de onde veio e a
impressão digital da chave usada. Entre no `web` uma vez a partir do `admin`, para haver uma para
ler:

```
ana@admin:~$ ssh web true
ana@web:~$ sudo journalctl -u ssh --no-pager -o short-iso | grep Accepted
2026-10-23T02:02:02-03:00 web sshd[106]: Accepted publickey for ana from 192.168.60.30 port 57922 ssh2: ED25519 SHA256:uNd8LFH2OUEz1CO+izl+KXX0/r30W6iqUjUjMA8jRkk
```

Um login é evidência de quem, onde nada mais é: a impressão digital diz qual chave, e a chave, num
lugar bem administrado, diz qual pessoa.

**O terceiro tipo é a trilha de auditoria do próprio kernel, e aqui ela falta.** O Linux tem um
sistema de auditoria que consegue registrar cada programa iniciado, cada arquivo aberto e cada
permissão alterada, no momento em que acontece, de dentro do kernel. O `auditctl` é o programa de
controle dele, e no `web` ele nem consegue listar as regras:

```
ana@web:~$ sudo auditctl -l; echo "exit $?"
Error sending rule list data request (Operation not permitted)
There was an error while processing parameters
exit 255
```

O `Operation not permitted` não é um pacote faltando; o `auditd` está instalado. **O kernel guarda
uma trilha de auditoria para o computador inteiro, e não entrega um pedaço dela a cada contêiner.**
Um processo dentro do `web` pedindo as regras de auditoria está pedindo as do host, e um contêiner
não pode isso. A sua máquina virtual Ubuntu, fora dos contêineres, tem uma trilha de auditoria do
kernel que funciona; as máquinas deste laboratório não têm, e é por isso que o `build` desligou o
`auditd`.

Essa é também a primeira coisa honesta a dizer sobre EDR em contêineres em geral. Um produto que
vigia contêineres roda **no host**, abaixo deles, onde estão os eventos do kernel, e vê todos os
contêineres de lá. Um agente instalado dentro de cada contêiner vê tanto quanto o sensor desta aula.

## O que um sensor registra sobre um processo

Quando um processo começa, um registro útil responde a seis perguntas, e o sensor da próxima seção
grava uma linha JSON com um campo para cada uma:

| campo | a pergunta |
|---|---|
| `pid`, `ppid` | qual processo, e qual o iniciou |
| `user` | com que conta ele roda |
| `exe` | que arquivo de programa ele é, resolvido, para que uma cópia renomeada ainda diga de onde veio |
| `cmd` | os argumentos que recebeu |
| `parents` | a cadeia acima dele, até o serviço ou o login de que descende |
| `time`, `host` | quando, e em que máquina, para que linhas de muitas máquinas possam ser postas lado a lado |

A diferença entre `exe` e `cmd` importa mais do que parece. `cmd` é o que o processo diz que é o
nome dele, e um processo pode dizer qualquer coisa. `exe` é o link do kernel para o arquivo que está
de fato rodando, e só o kernel o escreve.
