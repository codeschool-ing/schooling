---
title: A linha do tempo, a partir da evidência
version: 1
---

**Um postmortem começa por uma linha do tempo montada a partir de evidência, não de memória.** A memória põe os
eventos na ordem que dá a melhor história; logs e métricas os põem na ordem em que aconteceram. O incidente de
pagamento da lição 10 está no `checkout.log`, os trinta minutos que o `genlogs.py` escreve, então a linha do tempo
dele pode ser refeita no seu computador. Gere o arquivo de novo se o apagou (`python3 genlogs.py > checkout.log`,
em `~/gcp`).

Quando as tentativas passaram de cinco por minuto pela primeira vez, e quando isso parou?

```
ana@laptop:~/gcp$ jq -r 'select(.message == "payment retried") | .timestamp[11:16]' checkout.log | sort | uniq -c | awk '$1 > 5 {print $2}' | sed -n '1p;$p'
14:12
14:17
```

A primeira e a última tentativa dentro desse trecho, ao segundo:

```
ana@laptop:~/gcp$ jq -r 'select(.message == "payment retried") | .timestamp' checkout.log | sort | sed -n '/T14:1[2-7]/p' | sed -n '1p;$p'
2026-10-30T14:12:08+00:00
2026-10-30T14:17:53+00:00
```

E o que os clientes viveram naqueles seis minutos:

```
ana@laptop:~/gcp$ jq -r 'select(.timestamp[11:16] >= "14:12" and .timestamp[11:16] <= "14:17") | .message' checkout.log | sort | uniq -c
    155 order placed
     85 payment retried
```

Em seis minutos, 85 checkouts precisaram de nova tentativa contra 155 que passaram de primeira: **mais de um em
três**. Todo pedido com nova tentativa neste log foi concluído, então o dano foi atraso, não pedidos perdidos. É um
fato que o postmortem afirma com um número em vez de "alguns clientes foram afetados".

## O que a linha do tempo diz sobre o alerta

O incidente foi de 14:12:08 a 14:17:53, menos de seis minutos. A política da lição 14 só dispara depois de as
tentativas ficarem acima de cinco por minuto **por dez minutos**. Então a política não teria disparado: o incidente
acabou antes de a condição dela poder ser verdadeira. Isso não é um erro na linha do tempo; é o primeiro achado do
postmortem, e o tipo de achado que só uma linha do tempo montada a partir de evidência produz. Se dez minutos ainda
é o certo é uma decisão sobre quanto um problema de pagamento de seis minutos vale para a loja, e o postmortem é
onde ela é tomada.

O resto da linha do tempo vem do canal do incidente: quando alguém percebeu, quando o incidente foi declarado, o
que foi tentado, quando acabou. Ponha as duas fontes lado a lado e as lacunas aparecem: aqui, uma lacuna entre
14:12, quando as tentativas começaram, e o momento em que alguém soube.
