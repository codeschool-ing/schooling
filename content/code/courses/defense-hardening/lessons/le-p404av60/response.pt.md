---
title: Guardar a evidência, parar, isolar
version: 1
---

**Um alerta é o começo do trabalho, não o fim.** O que vem depois é a resposta, e a ordem dela
importa mais que a velocidade: **guardar a evidência, parar a atividade, conter a máquina**, e só
então começar a consertar. Matar um processo primeiro é o instinto, e destrói a única coisa que
poderia dizer o que o processo era.

## Guarde a evidência

Enquanto o `/tmp/update` continua rodando, o kernel ainda guarda tudo sobre ele:

```
ana@web:~$ pgrep -a -u portal
55 /usr/bin/python3 /opt/portal/portal.py
193 /tmp/update 600
ana@web:~$ pid=$(pgrep -f "^/tmp/update"); sudo sha256sum /proc/$pid/exe /usr/bin/sleep
4a193eb6f25eecf27bad523cb8a53ec4d40775eb498f44760b19bfc421cc90aa  /proc/193/exe
4a193eb6f25eecf27bad523cb8a53ec4d40775eb498f44760b19bfc421cc90aa  /usr/bin/sleep
ana@web:~$ pid=$(pgrep -f "^/tmp/update"); sudo cat /proc/$pid/environ | tr "\0" "\n" | grep -E "^(USER|SUDO_USER|PWD)="
SUDO_USER=ana
PWD=/home/ana
USER=portal
```

O `pgrep` confirma o que o alerta disse, e `/proc/<pid>/exe` é o próprio programa em execução,
legível mesmo que alguém apague o arquivo em `/tmp` depois. O SHA-256 dele é a evidência que você
guarda, e aqui ele resolve uma pergunta na hora: é idêntico ao de `/usr/bin/sleep`, então o
"programa desconhecido" é uma cópia de uma ferramenta do sistema. Num incidente de verdade, esse hash
é o que você consultaria, e a aula 19 faz isso com os serviços feitos para isso. O ambiente do
processo diz como ele chegou a rodar, e aqui `SUDO_USER=ana` aponta para você, o que num caso real
seria a linha mais valiosa da tela.

Para guardar o próprio programa, copie `/proc/<pid>/exe` para um lugar que só o root lê antes de
parar qualquer coisa. Quem responde anota também cada comando e o horário, porque o registro do que
foi feito com a máquina é parte da evidência sobre ela.

## Pare

```
ana@web:~$ sudo pkill -u portal -f "^/tmp/update"; sleep 1; pgrep -a -u portal
55 /usr/bin/python3 /opt/portal/portal.py
```

A cópia sumiu, e o processo do próprio portal, 55, é a única coisa que sobra rodando como `portal`.
Parar um processo encerra esta atividade e nada mais: o que fez o portal rodar um comando continua
lá, e é por isso que o próximo passo não espera a causa ser encontrada.

## Isole a máquina

**Isolar corta uma máquina da rede, menos para as pessoas que estão respondendo.** Impede que o que
estiver na máquina alcance qualquer outra coisa, e mantém a máquina ligada, com a memória, os
processos e os logs intactos, que um corte de energia destruiria. Todo produto de EDR tem um botão
para isso. Por baixo, o botão é um firewall, e este é um arquivo. Salve-o como `isolate.nft` no seu
home no `web`:

```schooling-example
{"language": "conf", "file": "isolate.nft", "parts": [{"code": "table inet isolate {\n\tchain input {\n\t\ttype filter hook input priority -10; policy drop;\n\t\tiif \"lo\" accept\n\t\tip saddr 192.168.60.30 tcp dport 22 accept\n\t}\n\tchain output {\n\t\ttype filter hook output priority -10; policy drop;\n\t\toif \"lo\" accept\n\t\tip daddr 192.168.60.30 tcp sport 22 accept\n\t}\n}", "note": "Isolar é um firewall com uma porta deixada aberta. Todo pacote que entra ou sai é descartado, menos o loopback e o SSH com o `admin`, 192.168.60.30, que é de onde quem responde trabalha. No nftables, um pacote descartado por qualquer chain continua descartado, então um `accept` em outra tabela da máquina não deixa tráfego passar por estas duas; a prioridade `-10` só as faz olhar primeiro."}]}
```

Carregue-o e depois teste a máquina pelos dois lados:

```
ana@web:~$ sudo nft -f isolate.nft && sudo nft list tables
table inet isolate
ana@desk:~$ ping -c1 -W1 web | tail -2; curl -s -m3 http://web/; echo "exit $?"
1 packets transmitted, 0 received, 100% packet loss, time 0ms

exit 28
ana@admin:~$ ssh web "hostname; uptime -p"
web
up 16 minutes
```

Do `desk`, o ping se perde e a página do portal estoura o tempo: para a rede, o `web` sumiu. Do
`admin`, o SSH continua funcionando, porque essa única porta ficou aberta de propósito. O shell em
que você está digitando no `web` também nunca foi afetado, porque o `hostlab.sh` alcança uma máquina
entrando nela, não pela rede, mais ou menos como o agente de um produto mantém um canal próprio com
o console.

Quando a máquina tiver sido examinada e consertada, o isolamento termina apagando a tabela:

```
ana@web:~$ sudo nft delete table inet isolate; sudo nft list tables
ana@desk:~$ curl -s -m3 http://web/
Jatobá Contabilidade: client portal
```

A página volta a responder ao `desk`. **Na vida real esse é o último passo, não o próximo**: uma
máquina que estava rodando o comando de outra pessoa é reinstalada ou restaurada de um estado sabido
bom, e a aula 3 trata de devolver uma máquina à configuração que ela deveria ter.
