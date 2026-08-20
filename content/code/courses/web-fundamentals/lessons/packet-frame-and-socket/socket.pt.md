---
title: Socket: o endereço de um programa
---

O IP encontra a máquina, mas uma máquina roda dezenas de programas em rede ao mesmo tempo. Quem separa é a **porta**, um número que identifica qual programa deve receber aquele dado.

A dupla `IP:porta` é o **socket** — `192.168.0.10:443`, por exemplo. Uma conexão é identificada por quatro coisas: IP e porta de origem, IP e porta de destino. Como a porta de origem muda a cada conexão nova, você pode abrir dez abas do mesmo site sem que as respostas se misturem.

Portas comuns valem decorar: `80` para HTTP, `443` para HTTPS, `22` para SSH, `5432` para PostgreSQL. Quando um serviço "não responde" e a máquina está no ar, quase sempre a pergunta certa é se alguém está escutando naquela porta.
