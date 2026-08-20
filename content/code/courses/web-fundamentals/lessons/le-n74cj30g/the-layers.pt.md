---
title: As quatro que importam na prática
---

O modelo OSI tem sete camadas e é bom para estudar. No dia a dia, quatro explicam quase tudo:

- **Enlace** — o quadro no cabo ou no ar. Endereço MAC, Ethernet, Wi-Fi.
- **Rede** — o pacote atravessando redes diferentes. Endereço IP, roteamento.
- **Transporte** — a conversa entre dois programas. Portas, TCP e UDP.
- **Aplicação** — o que os programas falam entre si. HTTP, DNS, SMTP.

Cada camada envelopa a de cima: o quadro contém o pacote, que contém o segmento, que contém o pedido HTTP. É literalmente uma boneca russa, e é assim que o Wireshark mostra qualquer captura.
