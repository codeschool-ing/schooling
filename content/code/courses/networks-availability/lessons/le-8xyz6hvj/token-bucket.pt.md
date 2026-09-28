---
title: O token bucket que os dois usam
version: 1
---

Um shaper e um policer decidem "sobra taxa para este pacote?" do mesmo jeito, com um **token bucket**, um
balde de fichas. As fichas pingam no balde na taxa configurada, uma por byte aqui. Um pacote pode sair
quando o balde tem tantas fichas quantos bytes o pacote tem, e sair as consome. O balde tem um tamanho, e
as fichas que chegam com ele cheio se perdem, então **a taxa diz a que velocidade o crédito é ganho e o
tamanho diz quanto dá para juntar**.

Os números do laboratório deixam isso concreto. 5 Mbit/s são 5.000.000 de bits por segundo, e um byte
tem 8 bits, então o balde enche a **625.000 bytes por segundo**, e é por isso que o policer, mais adiante
nesta aula, está escrito como `625 kbytes/second`. Os dois limites do laboratório têm um balde de 16 KB,
16.384 bytes, e um quadro Ethernet de tamanho máximo tem 1514 bytes:

| | |
|---|---|
| quadros que um balde cheio deixa passar de uma vez | 16.384 ÷ 1514 = **10**, e um pouco |
| tempo para encher um balde vazio | 16.384 ÷ 625.000 = **26 ms** |
| tempo que a taxa precisa para um quadro | 1514 ÷ 625.000 = **2,4 ms** |

Então um enlace quieto consegue mandar uns dez quadros em velocidade total, uma rajada, e depois se
acomoda num quadro a cada 2,4 ms. Um balde maior perdoa rajadas maiores; um balde menor que um quadro
nunca deixaria um quadro passar.

A única diferença entre os dois é a linha que roda quando faltam fichas. Um shaper espera por elas. Um
policer não espera; o pacote é descartado. O programa abaixo modela os dois com a taxa e o balde do
laboratório, e manda a cada um a mesma rajada: 40 quadros de tamanho máximo, um a cada meio milissegundo,
o que dá 24 Mbit/s durante 20 ms.

```schooling-example
{"language": "python", "file": "bucket.py", "parts": [{"code": "RATE = 625_000   # tokens a second, one per byte: 5 Mbit/s\nBURST = 16_384   # the bucket's size: 16 KB, like burst 16kb\nFRAME = 1514     # one full-size Ethernet frame\nGAP = 0.0005     # a frame arrives every half millisecond: 24 Mbit/s", "note": "Os números do laboratório. O balde começa cheio, 16.384 fichas, e ganha 625.000 por segundo. A rajada é um quadro a cada meio milissegundo, umas cinco vezes a taxa."}, {"code": "def shape(n):\n    tokens, clock, waits = BURST, 0.0, []\n    for i in range(n):\n        arrives = i * GAP\n        start = max(arrives, clock)\n        tokens = min(BURST, tokens + (start - clock) * RATE)\n        wait = max(0.0, (FRAME - tokens) / RATE)\n        clock = start + wait\n        tokens += wait * RATE - FRAME\n        waits.append(clock - arrives)\n    return n, 0, max(waits)", "note": "O shaper. Um quadro começa quando chega ou quando o anterior saiu, o que for mais tarde, e espera até o balde ter 1514 fichas. Nada é descartado; o custo é a espera, e a função devolve a mais longa."}, {"code": "def police(n):\n    tokens, clock, sent = BURST, 0.0, 0\n    for i in range(n):\n        arrives = i * GAP\n        tokens = min(BURST, tokens + (arrives - clock) * RATE)\n        clock = arrives\n        if tokens >= FRAME:\n            tokens -= FRAME\n            sent += 1\n    return sent, n - sent, 0.0", "note": "O policer. O mesmo balde, reabastecido até o momento em que o quadro chega. Se as fichas estão lá, o quadro passa e paga; se não, conta como descartado, e nada espera."}, {"code": "for name, run in ((\"shaper\", shape), (\"policer\", police)):\n    sent, dropped, wait = run(40)\n    print(f\"{name:8} sent {sent:2}  dropped {dropped:2}  longest wait {wait * 1000:.1f} ms\")", "note": "Os mesmos 40 quadros por cada um, e uma linha para cada."}], "output": "shaper   sent 40  dropped  0  longest wait 51.2 ms\npolicer  sent 18  dropped 22  longest wait 0.0 ms"}
```

**O shaper enviou os 40 e fez o último esperar 51,2 ms; o policer enviou 18 e descartou 22 sem atrasar
nada.** O shaper do modelo guarda tudo o que recebe. O shaper do `tc` é
informado de quanto pode guardar, na próxima seção com `latency 50ms`, e descarta o que não cabe. Uma
rajada de 40 quadros fica perto desse limite. Um upload TCP, que continua enviando até algo se perder,
passa dele, e os contadores da próxima seção mostram os descartes.
