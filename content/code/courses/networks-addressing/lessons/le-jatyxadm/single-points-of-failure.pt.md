---
title: Pontos únicos de falha, e quais manter
version: 1
---

Um **ponto único de falha** é uma peça cuja falha sozinha derruba alguma coisa: sem gêmeo, sem segundo
caminho. O campus tem o núcleo duplicado e as subidas duplicadas, e é fácil concluir pelo desenho que ele
não tem ponto único de falha. Escolha qualquer PC e suba a partir dele, porém, e a resposta muda.

O laboratório é montado de novo do zero, com todos os cabos funcionando, e então o d1 falha: todas as
interfaces dele são desligadas, que é como um roteador sem energia parece para os vizinhos. O pc1 tenta o
próprio gateway, e depois o pc2:

```
root@d1:~# for i in eth0 eth1 eth2; do ip link set $i down; done
ana@pc1:~$ ping -c 3 -W 1 10.20.11.1
PING 10.20.11.1 (10.20.11.1) 56(84) bytes of data.

--- 10.20.11.1 ping statistics ---
3 packets transmitted, 0 received, 100% packet loss, time 2042ms

ana@pc1:~$ ping -c 3 -W 1 10.20.12.22
PING 10.20.12.22 (10.20.12.22) 56(84) bytes of data.

--- 10.20.12.22 ping statistics ---
3 packets transmitted, 0 received, 100% packet loss, time 2052ms

```

**100% de perda para os dois.** O pc1 não alcança `10.20.11.1`, o endereço para o qual ele manda tudo,
então não alcança nada além da própria LAN. Enquanto isso, c1, c2 e d2 estão saudáveis, e o segundo
caminho do núcleo — a redundância da seção anterior — está lá, sem uso, porque **a redundância começou
uma camada acima demais**. Para o pc1, o d1 é um ponto único de falha, e tudo abaixo dele também.

Suba a partir do pc1 e liste:

| peça | o que a falha dela derruba | duplicada no laboratório? |
|---|---|---|
| o cabo do pc1 até o a1 | o pc1 | não |
| o switch de acesso a1 | todo mundo no a1 | não |
| o cabo do d1 até o a1 | todo mundo no a1 | não |
| o d1, o gateway | todo mundo no a1, e a saída da LAN | não |
| os cabos do d1 até os núcleos | nada: são dois | sim |
| os roteadores de núcleo | nada: são dois | sim |

## Tirando o gateway da lista

A correção usual para o gateway é a **redundância do primeiro salto** (*first-hop redundancy*): dois
roteadores de distribuição na LAN do pc1 dividem um endereço de gateway. Um deles, o ativo, responde por
ele; o outro escuta, e se o ativo fica em silêncio ele assume o endereço. O pc1 continua mandando para o
mesmo `10.20.11.1` e nunca fica sabendo que outra caixa está respondendo. O protocolo padrão para isso é
o **VRRP** (*Virtual Router Redundancy Protocol*); o equivalente da Cisco é o HSRP.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 276\" role=\"img\" aria-label=\"Redundância do primeiro salto, como um projeto que não foi montado no laboratório. O pc1 manda para o gateway, 10.20.11.1, através do switch de acesso a1. Esse endereço não pertence a uma caixa só: o d1, ativo, responde por ele, e um segundo roteador na mesma LAN fica de reserva para assumi-lo se o d1 parar de responder. Os dois roteadores têm cabos subindo até o núcleo.\"><rect x=\"230\" y=\"14\" width=\"260\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">c1   c2</text><rect x=\"130\" y=\"100\" width=\"170\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"215\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">d1</text><text x=\"215\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">ativo: responde por ele</text><rect x=\"420\" y=\"100\" width=\"170\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"505\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">um segundo roteador</text><text x=\"505\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">reserva: assume o endereço</text><path d=\"M215 100 L300 50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M505 100 L420 50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"250\" y=\"176\" width=\"220\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></rect><text x=\"360\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">gateway 10.20.11.1</text><text x=\"360\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um endereço, dois roteadores</text><path d=\"M215 154 L290 176\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M505 154 L430 176\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><rect x=\"310\" y=\"236\" width=\"100\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"249\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">a1</text><path d=\"M360 216 L360 236\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"160\" y=\"236\" width=\"100\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"210\" y=\"249\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc1</text><path d=\"M260 249 L310 249\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path></svg>", "caption": "O que o laboratório não tem: um segundo roteador dividindo o endereço de gateway do pc1. Com VRRP, o roteador reserva assume o endereço quando o ativo fica em silêncio, e o pc1 não muda nada.", "same": ["gateway 10.20.11.1"]}
```

**Nada disso foi montado no laboratório.** O cenário campus tem um gateway por LAN justamente para que a
falha acima pudesse ser mostrada; um segundo roteador e o VRRP são o que um projeto de produção
acrescentaria. A aula 22 volta aos gateways, do lado de um switch que roteia.

## Os que você mantém

Eliminar todo ponto único de falha não é o objetivo, e não cabe no orçamento. **Projetar é decidir quais
pontos únicos aceitar**, e anotar a decisão:

- **O cabo de um PC de mesa** fica único. Um segundo cabo até cada mesa dobra o cabeamento por uma falha
  que atinge uma pessoa, e um técnico com um cabo novo resolve em minutos.
- **Um switch de acesso** costuma ficar único também, com um reserva na prateleira. A falha dele atinge
  um andar, pelo tempo que leva para trocá-lo.
- **A conexão de um servidor** muitas vezes é duplicada: duas placas de rede até dois switches,
  combinadas num link só (a aula 21 monta isso com LACP), porque a falha de um servidor atinge todo mundo
  que o usa.
- **O gateway e o núcleo** são duplicados em quase toda rede maior que um escritório, porque são as peças
  cuja falha atinge todo mundo.

A pergunta da aula 3 vale em toda camada: **se isto falhar, quantas pessoas percebem?** A resposta diz se
a peça precisa de um gêmeo.
