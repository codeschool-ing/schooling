---
title: "Métricas: duas rotas para o mesmo lugar"
version: 2
---

O prefixo mais longo não consegue escolher entre duas rotas para o mesmo prefixo: elas têm o mesmo
tamanho. Aí a **métrica** decide, e **vence a métrica mais baixa**. Ela é um custo, e o roteador pega o
caminho mais barato. O motivo mais comum para ter duas rotas assim é um reserva: duas saídas, uma
preferida, a outra esperando.

O r1 ganha exatamente isso. A padrão antiga sai, e duas entram no lugar dela, via ra com métrica 100 e
via rb com métrica 200:

```
root@r1:~# ip route del default via 10.20.1.2
root@r1:~# ip route add default via 10.20.1.2 metric 100
root@r1:~# ip route add default via 10.20.2.2 metric 200
root@r1:~# ip route show default
default via 10.20.1.2 dev eth1 metric 100 
default via 10.20.2.2 dev eth2 metric 200 
root@r1:~# ip route get 198.51.100.7
198.51.100.7 via 10.20.1.2 dev eth1 src 10.20.1.1 uid 0 
    cache 
```

As duas estão na tabela e só uma é usada: 198.51.100.7, um endereço que nada mais específico cobre,
sai via ra. A rota de métrica 200 não está errada nem parada à toa. Ela é uma **rota reserva**,
mantida na tabela e ignorada enquanto a melhor puder ser usada.

Depois o cabo do r1 até o ra é puxado. (No laboratório, a ponta do ra é desligada, `ip link set eth0 down`
num prompt de root no ra, o que o r1 vê exatamente como um cabo puxado: o sinal na porta dele some.) O r1 percebe na hora:

```
root@r1:~# ip -br link show eth1
eth1@if219       DOWN           02:a6:80:20:13:54 <NO-CARRIER,BROADCAST,MULTICAST,UP> 
root@r1:~# ip route show default
default via 10.20.1.2 dev eth1 metric 100 dead linkdown 
default via 10.20.2.2 dev eth2 metric 200 
root@r1:~# ip route get 198.51.100.7
198.51.100.7 via 10.20.2.2 dev eth2 src 10.20.2.1 uid 0 
    cache 
```

A eth1 está `DOWN` com `NO-CARRIER`: a interface continua ligada (`UP` nas flags) e não há nada do
outro lado. O kernel marca a rota que passa por ela como **`dead linkdown`** e para de escolhê-la, e a
mesma pergunta agora recebe a outra resposta: via rb, eth2. Ninguém digitou nada, e nenhum protocolo
de roteamento participou. **Uma rota cuja interface perde o sinal sai da escolha, e a reserva atrás
dela assume.** Quando o cabo voltou, a rota de métrica 100 voltou a ser escolhida, o que a captura da
próxima seção, feita depois, mostra como selecionada.

Esse failover tem um ponto cego, e é o que importa na prática. Ele só dispara quando a porta do
próprio r1 perde o sinal. Suponha que o ra travasse mas a porta continuasse acesa, ou que o ra e o r1 estivessem ligados por um
switch, ou que o ra perdesse a sua própria saída mais adiante. O enlace do r1 continuaria no ar, a rota de métrica 100 continuaria viva, e o r1 continuaria mandando tudo para um
roteador que descarta. **Uma reserva estática protege contra um cabo, não contra um roteador.** Saber
se o próximo roteador ainda consegue entregar exige algo que pergunte a ele: as mensagens de hello de
um protocolo de roteamento, que a aula 16 cobre, ou um teste do próprio caminho, que alguns roteadores
conseguem amarrar a uma rota estática.

De onde vem a métrica depende de quem fez a rota. Aqui ela é um número digitado à mão, e o Linux a
trata como uma simples preferência. Um protocolo de roteamento a calcula a partir da rede: o RIP conta
os roteadores no caminho, o OSPF soma um custo por enlace derivado da velocidade dele, e o EIGRP
combina várias medidas num número só; a aula 16 desmonta cada um. **Uma métrica só significa algo ao
lado de outra métrica da mesma origem.** Cinco saltos e um custo de cinco não são o mesmo cinco, e a
próxima seção trata do que um roteador faz quando duas origens discordam.
