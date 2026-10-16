---
title: Sentinel ou Cluster
version: 1
---

Os dois costumam ser apresentados como uma versão básica e uma avançada da mesma coisa. Não são. **O
Sentinel torna um conjunto de dados altamente disponível; o Cluster divide um conjunto entre máquinas e
torna cada parte altamente disponível.** A pergunta que escolhe um deles é se os dados e a taxa de
escrita cabem numa máquina, e não quão sério é o projeto.

## Lado a lado

| | Sentinel | Cluster |
| --- | --- | --- |
| o que resolve | a máquina do primário morrer | os dados ou as escritas passarem do tamanho de uma máquina, e um primário morrer |
| para onde vão as escritas | um primário, para tudo | um primário por faixa de slots |
| processos na aula | 3 Redis + 3 Sentinel | 6 Redis, sem Sentinel |
| comandos com várias chaves, transações, Lua | em quaisquer chaves | só em chaves de um slot; hash tags para arrumar isso |
| bancos `SELECT 1` a `15` | disponíveis | só o banco 0 |
| o que o cliente precisa | perguntar a um Sentinel pelo primário | seguir `MOVED` e conhecer o mapa de slots |
| failover | os Sentinels votam, por quórum | os primários votam, por maioria |
| perder escritas confirmadas | possível, como a seção anterior mostrou | possível, pelo mesmo motivo |
| acrescentar capacidade | uma máquina maior | mais primários, movendo slots para eles |

## O que cada um custa

**O Sentinel custa processos e um cliente que sabe perguntar.** Três Sentinels são pequenos, mas são
mais três coisas para rodar, para pôr em máquinas separadas e para vigiar; dois Sentinels na mesma
máquina que o primário votam como um só quando essa máquina morre. E todo cliente precisa ser
configurado com os endereços dos Sentinels, e não com o do primário, ou o primeiro failover o deixa
gravando no vazio.

**O Cluster custa o modelo de dados.** Todo lugar em que a aplicação mexe em duas chaves de uma vez,
uma transação, um script Lua, um `MGET` sobre clientes, ou mantém as chaves num slot ou para de
funcionar. É uma decisão de modelagem do tipo que as aulas 3 e 4 tomaram, tomada antes da primeira
implantação, porque mover chaves existentes para uma hash tag nova é uma migração. O resharding, mover
slots para um primário novo, é feito online com `redis-cli --cluster reshard`; ele move chaves enquanto
os clientes são atendidos, e leva um tempo proporcional aos dados movidos.

## Para a loja

O Redis da loja guarda contadores de estoque, carrinhos, sessões e os streams da aula 12: alguns
gigabytes no máximo, uma taxa de escrita que um servidor atende com folga. **Esse é o caso do
Sentinel.** O Cluster espalharia carrinhos e contadores por nós, proibiria as transações que mexem nos
dois e compraria uma capacidade de que a loja não precisa. O dia em que uma máquina deixar de bastar é
o dia de modelar para slots, e o que a aula 10 diz sobre uma shard key escolhida cedo demais vale também
para uma hash tag.

E qualquer que seja a escolha, a seção anterior continua valendo: **uma escrita confirmada pode se
perder num failover.** Dados que não podem se perder vão para um armazenamento cuja replicação espera
a maioria, como o replica set do MongoDB da aula 9 com write concern majority, ou o banco relacional que
a loja já tem.
