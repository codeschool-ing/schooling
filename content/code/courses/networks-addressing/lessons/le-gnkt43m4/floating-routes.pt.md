---
title: Uma rota reserva, e o que ela não enxerga
version: 1
---

O cabo reserva de r1 a r3 é um segundo caminho. Uma **rota flutuante** o põe para uso: uma segunda rota
estática para a mesma rede, pelo cabo reserva, com métrica pior, para que ela fique flutuando sem uso
acima da principal até a principal sumir. A aula 14 mostrou o kernel escolhendo a menor métrica entre
duas rotas para o mesmo prefixo; aqui essa regra é posta para trabalhar:

```
root@r1:~# ip route add 10.20.3.0/24 via 10.20.13.2 metric 200
root@r3:~# ip route add 10.20.1.0/24 via 10.20.13.1 metric 200
root@r1:~# ip route show 10.20.3.0/24
10.20.3.0/24 via 10.20.12.2 dev eth1 
10.20.3.0/24 via 10.20.13.2 dev eth3 metric 200 
```

r1 agora tem duas linhas para `10.20.3.0/24`. A que não mostra métrica tem métrica 0 e vence; a que sai
por `eth3` espera com `metric 200`. r3 recebeu a imagem espelhada para `10.20.1.0/24`.

Em equipamento Cisco a mesma ideia é escrita com uma distância administrativa em vez de uma métrica, um
número depois do próximo salto como `ip route 10.20.3.0 255.255.255.0 10.20.13.2 200`, e o nome *rota
estática flutuante* vem daí. O mecanismo é outro e o propósito é o mesmo.

## Puxando um cabo

Então o cabo de r1 a r2 foi puxado. r1 perdeu o sinal em `eth1`, e sua tabela mudou sozinha:

```
root@r1:~# ip route show 10.20.3.0/24
10.20.3.0/24 via 10.20.12.2 dev eth1 dead linkdown 
10.20.3.0/24 via 10.20.13.2 dev eth3 metric 200 
root@r1:~# ip route get 10.20.3.10
10.20.3.10 via 10.20.13.2 dev eth3 src 10.20.13.1 uid 0 
    cache 
```

**`dead linkdown`** é o kernel marcando a principal como inutilizável porque a interface por onde ela
sai não tem portadora. A rota continua listada, então volta a ser usada quando o cabo voltar, e o
`ip route get` confirma que um pacote para pc3 agora sai por `eth3`, pelo cabo reserva. Até aqui a rota
reserva cumpre seu papel.

Agora faça a r3 a mesma pergunta sobre o caminho de volta:

```
root@r3:~# ip route get 10.20.1.10
10.20.1.10 via 10.20.23.1 dev eth2 src 10.20.23.2 uid 0 
    cache 
```

**r3 continua mandando as respostas para r2.** Nada mudou em r3: seu cabo até r2 tem sinal, sua rota por
`10.20.23.1` continua sendo a melhor, e a reserva por `10.20.13.1` espera atrás dela. r3 não tem como
saber que o cabo do outro lado de r2 sumiu.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 265\" role=\"img\" aria-label=\"Os mesmos três roteadores depois que o cabo de r1 a r2 é puxado. O pedido de pc1 vai de r1 pelo cabo reserva até r3, porque a rota reserva de r1 assumiu. A resposta de pc3 vai de r3 para r2, porque o cabo de r3 até r2 continua ligado e a rota por r2 continua sendo a melhor que ele tem. r2 perdeu o enlace com r1, responde !N, rede inalcançável, e a resposta nunca chega a pc1.\"><defs><marker id=\"chf-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"50\" width=\"100\" height=\"74\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc1</text><text x=\"20\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.1.10</text><rect x=\"150\" y=\"50\" width=\"118\" height=\"74\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"160\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r1</text><text x=\"160\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth0 10.20.1.1</text><text x=\"160\" y=\"97\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth1 10.20.12.1</text><text x=\"160\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth3 10.20.13.1</text><rect x=\"300\" y=\"50\" width=\"118\" height=\"74\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"310\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r2</text><text x=\"310\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth1 10.20.12.2</text><text x=\"310\" y=\"97\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth2 10.20.23.1</text><rect x=\"450\" y=\"50\" width=\"118\" height=\"74\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"460\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r3</text><text x=\"460\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth2 10.20.23.2</text><text x=\"460\" y=\"97\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth3 10.20.13.2</text><text x=\"460\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth0 10.20.3.1</text><rect x=\"610\" y=\"50\" width=\"100\" height=\"74\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"620\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc3</text><text x=\"620\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.3.10</text><path d=\"M110 87 L150 87\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M268 87 L300 87\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M418 87 L450 87\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M568 87 L610 87\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"130\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.1.0/24</text><text x=\"284\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.12.0/30</text><text x=\"434\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.23.0/30</text><text x=\"589\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.3.0/24</text><path d=\"M209 124 L209 190 L509 190 L509 124\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\" fill=\"none\"></path><text x=\"359\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.13.0/30</text><text x=\"284\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">cabo puxado</text><path d=\"M284 24 L284 80\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 3\"></path><text x=\"359\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">pedido: r1 usa a rota de métrica 200</text><path d=\"M520 50 L520 34 L370 34 L370 50\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#chf-ah)\"></path><text x=\"560\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">resposta: r3 ainda vai por r2</text><text x=\"20\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">r2 não tem mais enlace com r1 e responde !N. pc1 só vê perda.</text></svg>", "caption": "O cabo de r1 a r2 puxado. r1 percebeu, porque o cabo era dele. r3 não, porque nada que ele enxerga mudou."}
```

O resultado:

```
ana@pc1:~$ ping -c 2 -W 1 10.20.3.10
PING 10.20.3.10 (10.20.3.10) 56(84) bytes of data.

--- 10.20.3.10 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1018ms

ana@pc3:~$ traceroute -n 10.20.1.10
traceroute to 10.20.1.10 (10.20.1.10), 30 hops max, 60 byte packets
 1  10.20.3.1  0.887 ms  0.427 ms  0.319 ms
 2  10.20.23.1  0.273 ms !N  0.307 ms !N *
```

O ping perde os dois pacotes sem nenhum erro. O `traceroute` a partir de pc3 mostra para onde vão as
respostas: para r3, depois para r2 em `10.20.23.1`, que responde **`!N`**, rede inalcançável. A rota do
próprio r2 para `10.20.1.0/24` saía pelo cabo morto, e r2 não tinha outra. A terceira sonda imprimiu
`*`, nenhuma resposta.

## O que isso mostra

**Uma rota estática reage aos cabos do próprio roteador e a mais nada.** r1 passou para a reserva porque
a falha estava na interface de r1. r3 não passou, porque de onde r3 está todos os cabos continuam
funcionando. Uma rota flutuante é uma boa reserva para exatamente uma falha, a perda do enlace do
próprio roteador, e transforma qualquer outra falha no estado silencioso de meio funcionamento que você
acabou de ver.

Três saídas, e só a primeira é assunto deste curso:

- *Um protocolo de roteamento.* Os roteadores contam uns aos outros o que alcançam, então r2 teria
  avisado r3 que perdeu a rede de pc1. A aula 16 é isso.
- *BFD* (*Bidirectional Forwarding Detection*), um protocolo pequeno que troca hellos rápidos entre dois
  roteadores e pode retirar uma rota estática quando o vizinho para de responder, mesmo com o sinal no
  cabo. Ele é citado aqui e não foi executado neste laboratório.
- *Menos caminhos.* Uma rede com uma saída só não tem como errar desse jeito, e esse é o assunto da
  próxima seção.
