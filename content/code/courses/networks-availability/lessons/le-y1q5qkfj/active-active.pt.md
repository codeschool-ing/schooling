---
title: Ativo-ativo, e a regra que o mantém honesto
version: 1
---

O ativo-ativo não precisa de nada novo, só de uma segunda instância VRRP. O keepalived dos dois
balanceadores é reconfigurado com duas: `www_a` para `192.0.2.80`, em que `lb1` tem prioridade 150 e
`lb2` 100, e `www_b` para `192.0.2.81`, VRID 81, com as prioridades invertidas. As duas rastreiam o mesmo
script `haproxy_alive`. O arquivo do HAProxy não muda, porque já escutava nos dois endereços.

Pare o keepalived nos dois balanceadores antes, na máquina virtual:
`sudo bash netlab.sh kill lb1 keepalived` e `sudo bash netlab.sh kill lb2 keepalived`; cada um abre mão do
seu endereço ao sair. Depois acrescente isto no fim do `keepalived.conf` de cada balanceador, o de `lb1`
como está aqui, e em `lb2` com as duas prioridades trocadas:

```schooling-example
{"language": "conf", "file": "keepalived.conf", "parts": [{"code": "vrrp_instance www_b {\n    state BACKUP\n    interface eth0\n    virtual_router_id 81\n    priority 100\n    advert_int 1", "note": "Uma segunda instância, com VRID próprio, 81. Em `lb1` ela fica com a prioridade menor, 100; em `lb2` as duas se invertem, `www_a` com 100 e `www_b` com 150."}, {"code": "    virtual_ipaddress {\n        192.0.2.81/24\n    }", "note": "O segundo endereço público, em que o HAProxy já escuta."}, {"code": "    track_script {\n        haproxy_alive\n    }\n}", "note": "O mesmo check de `www_a`: se o HAProxy morre, este balanceador abre mão dos seus dois endereços."}]}
```

Inicie o keepalived nos dois com o comando da primeira seção, e alguns segundos depois:

```
ana@lb1:~$ ip -br addr show eth0
eth0@if1314      UP             192.0.2.11/24 192.0.2.80/24 
ana@lb2:~$ ip -br addr show eth0
eth0@if1316      UP             192.0.2.12/24 192.0.2.81/24 
ana@laptop:~$ curl -s http://192.0.2.80/; curl -s http://192.0.2.81/
served by web1
served by web3
ana@lb1:~$ tail -n 1 /run/haproxy.log
203.0.113.2:57106 [28/Sep/2026:18:12:09.815] www web/web1 0/0/0/0/0 200 206 - - ---- 1/1/0/0/0 0/0 "GET / HTTP/1.1"
ana@lb2:~$ tail -n 1 /run/haproxy.log
203.0.113.2:49940 [28/Sep/2026:18:12:09.822] www web/web3 0/0/0/0/0 200 206 - - ---- 1/1/0/0/0 0/0 "GET / HTTP/1.1"
```

**Cada balanceador tem um endereço público e o atende.** Uma requisição para o `.80` passou por `lb1` e
uma para o `.81` por `lb2`, e cada log tem a sua. Cada balanceador também mantém o próprio rodízio, e é por
isso que as duas respostas vieram de `web1` e `web3`: cada balanceador estava num ponto do próprio rodízio.
Os clientes normalmente seriam espalhados entre os dois endereços pelo DNS: o nome devolvendo os dois, numa
ordem diferente para cada um que pergunta. O DNS da rede só devolve `192.0.2.80` para
`www.example.com`, como o `dig` mostrou na seção do ativo-passivo, então aqui os dois endereços foram
pedidos à mão.

Depois o HAProxy de `lb2` foi morto, `sudo bash netlab.sh kill lb2 haproxy KILL`, e cinco segundos mais
tarde:

```
ana@lb1:~$ ip -br addr show eth0
eth0@if1314      UP             192.0.2.11/24 192.0.2.80/24 192.0.2.81/24 
```

`lb1` tem os dois endereços e leva todo o tráfego, que é o momento para o qual o ativo-ativo foi montado, e
o momento em que ele pode falhar.

## Cada um precisa levar tudo

Num dia normal cada balanceador leva metade. No dia em que um falha, o sobrevivente leva tudo, e **o
sobrevivente precisa ter sido dimensionado para esse dia, não para o normal**. Quando não foi, ele fica
lento, o próprio health check dele começa a estourar o tempo, e ele abre mão dos endereços também: uma
queda total, causada pela redundância, num par cujos painéis pareciam saudáveis todos os dias antes dela.

A regra se chama **N+1**: com N máquinas necessárias para a carga, tenha N+1, para que a perda de qualquer
uma deixe o suficiente. Num grupo ativo-ativo ela define um teto para o quanto cada membro pode trabalhar
num dia normal:

| membros | a carga que cada um pode levar normalmente | o que uma perda deixa para os outros |
|---|---|---|
| 2 | 50% | 100% em um |
| 3 | 67% | 100% em cada um de dois |
| 4 | 75% | 100% em cada um de três |

Quanto mais membros, menos capacidade fica parada de reserva, e é por isso que sites grandes espalham a
carga por muitos balanceadores em vez de dois grandes. **Um grupo de dois roda cada membro na metade, que é
exatamente a capacidade que o ativo-passivo tem.**

## Sessões e estado

Mover um endereço muda para onde vão as conexões novas. Tudo o que vivia na memória da máquina antiga se
foi: as conexões TCP abertas por ela, e o que ela guardava sobre cada usuário. Para um balanceador isso é
quase só conexões, e os clientes reconectam. Para os servidores web atrás dele, pode ser a sessão inteira
de um usuário, um carrinho de compras ou um login, guardada na memória de um servidor. Quando esse servidor
morre, ou a persistência do balanceador manda o usuário para outro lugar (aula 19), a sessão simplesmente
não está lá.

As soluções são todas a mesma ideia: **guardar o estado num lugar que sobreviva à máquina**. As sessões vão
para um repositório compartilhado, um banco de dados ou um cache que também é replicado, para que qualquer
servidor atenda qualquer usuário. Ou o estado viaja com o usuário, num cookie ou token assinado que o
servidor consegue conferir sem lembrar de nada. Os balanceadores podem ir além e copiar as próprias tabelas um para o outro. O HAProxy sincroniza as tabelas de persistência entre peers, e o conntrackd do Linux
consegue copiar a tabela de conexões de um firewall para que as conexões sobrevivam a um failover; nenhum
dos dois foi usado aqui. **Uma máquina sem estado é fácil de substituir. Deixar as máquinas sem estado é quase todo o trabalho de projetar um cluster.** O que não pode ficar sem estado, o próprio banco de dados, é
onde entram o split brain da aula 14 e a replicação da aula 17.
