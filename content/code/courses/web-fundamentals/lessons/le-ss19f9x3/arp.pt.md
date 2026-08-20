---
title: ARP: a ponte entre os dois
---

Para entregar um quadro na rede local a máquina precisa do MAC de quem tem aquele IP — e é isso que o **ARP** descobre. Ele grita na rede "quem tem `192.168.0.1`?", e a dona responde com o próprio MAC.

A resposta fica num cache por alguns minutos, senão cada pacote custaria uma pergunta. Dá para ver o seu com `arp -a`.

Vale saber que o ARP não confere nada: quem responder primeiro é acreditado. É a base do ataque de *ARP spoofing*, em que uma máquina responde no lugar do roteador e passa a receber o tráfego da rede — o motivo pelo qual usar HTTPS em rede pública deixa de ser recomendação e vira necessidade.
