---
title: Vazão é o que você realmente conseguiu
---

**Vazão** (*throughput*) é a taxa observada de verdade, e ela costuma ficar abaixo da largura de banda. A diferença é onde mora o problema real: congestionamento no caminho, perda de pacotes forçando reenvio, um servidor lento do outro lado, ou o próprio protocolo esperando confirmação.

Uma analogia que se paga: a **banda** é quantas faixas tem a estrada, a **latência** é o tempo de percorrê-la, e a **vazão** é quantos carros efetivamente chegaram. Estrada larga com engarrafamento entrega pouco.

Diagnóstico prático: se a vazão está baixa **e** a latência normal, suspeite do outro lado ou de perda. Se a latência está alta, nenhuma contratação de banda vai resolver — o problema é distância ou fila.
