---
title: Escala vertical, uma máquina maior
version: 1
---

**A escala vertical dá ao mesmo programa uma máquina maior**: mais processadores, mais memória,
armazenamento mais rápido. Nada no programa muda, e essa é a grande virtude dela. Costuma ser a
primeira coisa a tentar, e muitas vezes a certa.

Num servidor de verdade isso quer dizer uma máquina nova, ou parar uma virtual e subi-la de novo
com um tamanho maior. No laboratório, o Docker consegue mudar na hora a fatia de processadores de
um contêiner em execução. A bilheteria começa com `cpus: 1`; aqui ela ganha dois, depois quatro,
com o mesmo teste de antes, 16 trabalhadores comprando ingressos para cem shows:

```
ana@lab:~/tickets$ docker update --cpus 2 tickets-app-1
tickets-app-1
ana@lab:~/tickets$ python3 load.py -m POST -c 16 -d 10 --events 100 'http://localhost:8080/events/{event}/tickets'
requests  3159 in 10.1 s = 314.1 per second
latency   p50 50.2 ms  p95 91.4 ms  p99 104.9 ms  max 159.6 ms
status    201: 3159
ana@lab:~/tickets$ docker update --cpus 4 tickets-app-1
tickets-app-1
ana@lab:~/tickets$ python3 load.py -m POST -c 16 -d 10 --events 100 'http://localhost:8080/events/{event}/tickets'
requests  4345 in 10.0 s = 433.2 per second
latency   p50 35.8 ms  p95 66.0 ms  p99 85.5 ms  max 155.1 ms
status    201: 4345
ana@lab:~/tickets$ nproc
4
```

De um processador para dois, as vendas vão de 143 por segundo (a rodada de 16 trabalhadores da
última seção) para 314. **Um pouco mais que o dobro**, e o excesso é um efeito do limite e não um
presente: um contêiner limitado a um processador fica pausado pelo resto de cada décimo de segundo
depois que as suas threads gastaram a sua parte, e dezesseis threads ocupadas gastam essa parte em
rajadas. Com dois, ele é pausado menos vezes.

De dois para quatro, as vendas vão a 433, não a 628. O `nproc` dá o motivo: **a máquina tem quatro
processadores**, e a bilheteria não era a única coisa usando-os. O gerador de carga, o nginx e o
PostgreSQL dividem os mesmos quatro. Dar todos a um contêiner tirou tempo de processador dos outros,
e o banco e o gerador de carga passaram a fazer parte do gargalo. Numa máquina virtual com dois
processadores, o passo de dois para quatro nem pode ser medido, porque não há quatro para dar.

## O que uma máquina maior compra

- **Nenhuma mudança no programa.** O mesmo código, a mesma conexão com o banco, tudo igual. A
  bilheteria não faz ideia de que foi mudada de lugar.
- **Nenhum tipo novo de falha.** Uma máquina falha do jeito que uma máquina falha. Nada precisa
  concordar com nada através de uma rede.
- **Toda parte do trabalho fica mais rápida**, inclusive as que não podem ser divididas, que é
  exatamente o que a seção 09 mostra que a escala horizontal não consegue fazer.

## Onde ela acaba

A escala vertical tem quatro limites, e cada um chega num tamanho diferente:

- **A maior máquina à venda.** Os provedores de nuvem alugam máquinas com centenas de processadores
  e terabytes de memória, e além disso não há o que comprar. Muito antes disso,
- **o preço deixa de ser proporcional.** Uma máquina com o dobro do tamanho costuma custar mais que
  o dobro perto do topo de uma linha, e os tamanhos do topo são os mais escassos.
- **Uma máquina é uma falha.** Uma máquina maior é uma coisa maior para perder. Quando ela para,
  tudo nela para, e uma maior demora mais para ser substituída.
- **Mudar de tamanho exige reiniciar**, na maioria das plataformas de verdade. O `docker update` fez
  isso ao vivo; uma máquina virtual numa nuvem normalmente precisa ser parada, redimensionada e
  ligada de novo, o que é uma interrupção que você agenda.

E há um limite no programa, não na máquina. **Um programa precisa conseguir usar os processadores
que recebe.** A bilheteria consegue, porque o `ThreadingHTTPServer` roda cada conexão numa thread e
o `sign()` deixa as outras threads rodarem enquanto calcula. Um programa que faz o seu trabalho
numa única thread teria ficado no tempo de um processador, tivesse a máquina o que tivesse, e o
passo de dois para quatro não teria mostrado nada. A seção 10 põe um número nisso.
