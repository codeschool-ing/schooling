---
title: "Distância administrativa: em qual origem acreditar"
version: 1
---

Um roteador pode ouvir falar do mesmo prefixo por vários lugares ao mesmo tempo: uma interface
conectada, uma rota estática que alguém digitou, o OSPF, o BGP. As métricas delas estão em unidades
diferentes, então não dá para compará-las. **A distância administrativa classifica as próprias
origens, e vence a distância mais baixa**, antes de qualquer métrica ser olhada. É uma medida de
confiança: uma rota que o roteador vê no próprio cabo vale mais que uma que alguém digitou, e essa
vale mais que uma que um protocolo aprendeu com um vizinho.

O r1 roda o FRR, uma suíte de roteamento que mantém a sua própria tabela e entrega as vencedoras ao
kernel. A visão dele das rotas digitadas até aqui, com o cabo até o ra de volta:

```
root@r1:~# vtysh -c "show ip route"
Codes: K - kernel route, C - connected, S - static, R - RIP,
       O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, F - PBR,
       f - OpenFabric,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup
       t - trapped, o - offload failure

K * 0.0.0.0/0 [0/200] via 10.20.2.2, eth2, 00:00:09
K>* 0.0.0.0/0 [0/100] via 10.20.1.2, eth1, 00:00:10
C>* 10.20.1.0/30 is directly connected, eth1, 00:00:03
C>* 10.20.2.0/30 is directly connected, eth2, 00:00:23
C>* 10.20.10.0/24 is directly connected, eth0, 00:00:23
K>* 10.30.0.0/16 [0/0] via 10.20.1.2, eth1, 00:00:17
K>* 10.30.5.0/24 [0/0] via 10.20.2.2, eth2, 00:00:17
```

Cada linha é uma rota, com uma letra para a origem: `K` para uma rota encontrada no kernel, que é tudo
o que foi digitado com `ip route`, e `C` para conectada. O par entre colchetes é
**`[distância/métrica]`**. As duas padrões são `[0/100]` e `[0/200]`, mesma distância, então a métrica
decide, e `>` marca a selecionada, via 10.20.1.2. As duas têm `*`, que quer dizer que as duas estão na
tabela de encaminhamento do kernel, como o `ip route` mostrou na seção anterior. A rota conectada de
10.20.1.0/30 tem 3 segundos onde as outras duas conectadas têm 23: é o cabo até o ra voltando.

Agora duas rotas para o mesmo prefixo, da mesma origem, com distâncias diferentes. As duas são
digitadas na linguagem de configuração do próprio FRR: 10.40.0.0/16 via ra sem distância, o que numa
rota estática quer dizer 1, e via rb com distância 200, o número no fim da linha:

```
root@r1:~# vtysh -c "configure terminal" -c "ip route 10.40.0.0/16 10.20.1.2" -c "ip route 10.40.0.0/16 10.20.2.2 200"
root@r1:~# vtysh -c "show ip route 10.40.0.0/16"
Routing entry for 10.40.0.0/16
  Known via "static", distance 200, metric 0
  Last update 00:00:02 ago
    10.20.2.2, via eth2, weight 1

Routing entry for 10.40.0.0/16
  Known via "static", distance 1, metric 0, best
  Last update 00:00:02 ago
  * 10.20.1.2, via eth1, weight 1

root@r1:~# ip route show 10.40.0.0/16
10.40.0.0/16 nhid 26 via 10.20.1.2 dev eth1 proto static metric 20 
```

O FRR conhece as duas, `Known via "static"`, e marca a de distância 1 como `best`. **A suíte de
roteamento guarda toda candidata; o kernel recebe só a vencedora**: uma linha, via 10.20.1.2,
`proto static`. O `metric 20` nela é o número que o FRR dá às rotas que instala no kernel, e não é nem
a distância nem a métrica 0 da rota estática. A rota com distância 200 é uma **rota estática
flutuante**: ela flutua atrás da melhor e só é instalada se aquela sumir, por exemplo quando o próximo
salto dela fica inalcançável. É o jeito de costume de manter uma reserva estática atrás de uma rota
que um protocolo aprendeu: dar à estática uma distância acima da do protocolo.

As distâncias padrão são uma convenção, definida pela Cisco e seguida pelo FRR:

| origem | distância |
|---|---|
| conectada | 0 |
| estática | 1 |
| eBGP (de outro sistema autônomo) | 20 |
| EIGRP, interna (Cisco) | 90 |
| OSPF | 110 |
| RIP | 120 |
| iBGP (de dentro do mesmo sistema autônomo) | 200 |

Então, quando o OSPF e o RIP oferecem uma rota para o mesmo prefixo, a do OSPF é usada e a do RIP
espera, digam o que disserem as métricas. As aulas 16 e 17 tratam desses protocolos; a tabela é o
motivo de um roteador que roda dois deles não precisar comparar uma contagem de saltos com um custo.

Ponha as três regras na ordem, porque é na ordem que os erros nascem. **Primeiro o prefixo mais
longo, depois a menor distância, depois a menor métrica.** A distância só compara rotas para o mesmo
prefixo. Se o RIP oferece 10.50.1.0/24 e uma rota estática cobre 10.50.0.0/16, um pacote para
10.50.1.7 vai pelo /24 do RIP, com distância 120, e não pelo /16 estático com distância 1, porque o
prefixo mais longo foi decidido antes de a confiança sequer entrar na conversa.
