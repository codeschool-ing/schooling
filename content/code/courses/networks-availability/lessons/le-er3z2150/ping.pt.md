---
title: O que o ping mede
version: 1
---

O ping é a primeira ferramenta que todo mundo usa e a mais lida além do que ela diz. **Ele mede uma
coisa só: se um eco ICMP foi até um endereço e voltou, e quanto tempo levou a ida e volta**. Não diz nada
sobre uma porta, um programa ou banda, e uma máquina cujo firewall descarta ICMP não responde nada
enquanto serve páginas web perfeitamente. Do laptop para o web1:

```
ana@laptop:~$ ping -c 4 192.0.2.21
PING 192.0.2.21 (192.0.2.21) 56(84) bytes of data.
64 bytes from 192.0.2.21: icmp_seq=1 ttl=62 time=0.679 ms
64 bytes from 192.0.2.21: icmp_seq=2 ttl=62 time=0.080 ms
64 bytes from 192.0.2.21: icmp_seq=3 ttl=62 time=0.105 ms
64 bytes from 192.0.2.21: icmp_seq=4 ttl=62 time=0.086 ms

--- 192.0.2.21 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3077ms
rtt min/avg/max/mdev = 0.080/0.237/0.679/0.255 ms
```

Quatro ecos, quatro respostas. A primeira é a mais lenta, 0.679 ms contra 0.080 a 0.105 das outras
três. O primeiro pacote de uma conversa muitas vezes espera enquanto uma máquina no caminho procura um
endereço de hardware, então leia o resto e não o primeiro. **Nenhum desses tempos é de uma rede.** Os
enlaces do laboratório não têm atraso, e todo tempo impresso aqui é um computador falando consigo mesmo.
Numa linha de verdade a mesma saída traz a distância e as filas, e o `mdev`, a dispersão, é o número que
diz o quanto o atraso varia.

## De que distância veio a resposta

```
ana@laptop:~$ ping -c 1 192.168.10.1 | grep ttl; ping -c 1 192.0.2.21 | grep ttl
64 bytes from 192.168.10.1: icmp_seq=1 ttl=64 time=0.660 ms
64 bytes from 192.0.2.21: icmp_seq=1 ttl=62 time=0.381 ms
```

O TTL de uma resposta diz quantos roteadores ela atravessou. O Linux começa em 64, e cada roteador que
encaminha o pacote tira um. `hq` responde da porta ao lado com `ttl=64`; a resposta do web1 chega com
**`ttl=62`, dois roteadores**, o do provedor e `hq`. Outros sistemas começam em outro número, o Windows
em 128 e muitos roteadores em 255, então o TTL só é distância quando você sabe de onde ele partiu.

## De que tamanho

```
ana@laptop:~$ ping -c 3 -q -i 0.2 -s 1400 192.0.2.21
PING 192.0.2.21 (192.0.2.21) 1400(1428) bytes of data.

--- 192.0.2.21 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 407ms
rtt min/avg/max/mdev = 0.074/0.147/0.283/0.096 ms
```

`-s 1400` pede 1400 bytes de dados, e o ping informa **1428 no fio**: 8 bytes de cabeçalho ICMP e 20 de
IP. Tamanho é o teste que a aula 21 usou para achar o buraco negro dela. Este caminho não tem túnel, e
1428 bytes atravessam. `-q` imprime só o resumo e `-i 0.2` manda cinco por segundo em vez de um.

## Quanto se perde

A rodada seguinte foi encenada. Uma regra no roteador do provedor descarta **dois pacotes em cada dez, ao
acaso**, dos que ele encaminha para o web2, `192.0.2.22`. Em `isp`:

```sh
sudo nft add table ip faults
sudo nft add chain ip faults loss '{ type filter hook forward priority 0; }'
sudo nft add rule ip faults loss 'ip daddr 192.0.2.22 numgen random mod 10 < 2 drop'
```

Cinquenta pings, dez por segundo:

```
ana@laptop:~$ ping -c 50 -i 0.1 -q 192.0.2.22
PING 192.0.2.22 (192.0.2.22) 56(84) bytes of data.

--- 192.0.2.22 ping statistics ---
50 packets transmitted, 44 received, 12% packet loss, time 5095ms
rtt min/avg/max/mdev = 0.065/0.094/0.615/0.080 ms
```

Doze por cento, não vinte. Não há nada de errado com o ping; **uma perda medida numa rodada curta é uma
amostra, e cinquenta é pouco**. Umas linhas de Python mostram o quanto uma rodada de pings pode se afastar
da taxa verdadeira, usando a distribuição binomial: cada ping se perde ou não, com a mesma chance, de
forma independente.

```schooling-example
{"language": "python", "file": "spread.py", "parts": [{"code": "from math import comb"}, {"code": "def chance(n, p, k):\n    \"\"\"Probability that exactly k of n pings are lost, each with probability p.\"\"\"\n    return comb(n, k) * p**k * (1 - p) ** (n - k)", "note": "A chance de exatamente k perdas em n pings, quando cada um se perde com probabilidade p. `comb(n, k)` conta os jeitos de escolher quais k se perderam."}, {"code": "def spread(n, p):\n    \"\"\"The loss a run of n pings reports, from its 2.5th to its 97.5th percentile.\"\"\"\n    total, low, high = 0.0, None, None\n    for k in range(n + 1):\n        total += chance(n, p, k)\n        if low is None and total >= 0.025:\n            low = k\n        if high is None and total >= 0.975:\n            high = k\n    return low / n, high / n", "note": "Soma essas chances a partir de zero perdas, e anota onde o total acumulado passa de 2,5% e de 97,5%. Entre os dois ficam noventa e cinco rodadas em cada cem."}, {"code": "p = 0.2\nfor n in (20, 50, 1000):\n    low, high = spread(n, p)\n    print(f\"{n:5} pings, true loss {p:.0%}: reports {low:.0%} to {high:.0%}\")", "note": "A taxa que a regra do provedor descarta, 20%, e três tamanhos de rodada: as 20 sondas do primeiro relatório do mtr, os 50 pings do teste de perda e mil."}, {"code": "print(f\"6 or fewer lost of 50: {sum(chance(50, p, k) for k in range(7)):.1%} of runs\")", "note": "E a pergunta que a captura levanta: com que frequência 50 pings perdem 6 ou menos, que é o que 12% quer dizer, quando a taxa verdadeira é 20%?"}], "output": "   20 pings, true loss 20%: reports 5% to 40%\n   50 pings, true loss 20%: reports 10% to 32%\n 1000 pings, true loss 20%: reports 18% to 22%\n6 or fewer lost of 50: 10.3% of runs"}
```

Com vinte por cento de perda de verdade, cinquenta pings informam qualquer coisa de 10% a 32% em noventa
e cinco rodadas de cada cem, e um resultado de 12% ou menos aparece em mais ou menos uma rodada a cada
dez. **Os 12% medidos estão dentro dessa faixa, e também os 10% que o mtr informa para a mesma regra duas
seções adiante.** Mil pings prendem a mesma taxa entre 18% e 22%. Antes de dizer que um enlace perde
pacotes, ou que foi consertado, mande pacotes suficientes para o número querer dizer alguma coisa.
