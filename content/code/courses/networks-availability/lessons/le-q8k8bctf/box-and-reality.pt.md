---
title: O número da caixa e o número que você recebe
version: 1
---

Um roteador vendido como **AX3000** não promete 3000 Mbit/s a ninguém. O número é a soma de dois rádios.
Em 2,4 GHz, dois fluxos num canal de 40 MHz dão 2 × 286,8 = 573,6 Mbit/s. Em 5 GHz, dois fluxos em 160
MHz dão 2 × 1201,0 = 2402 Mbit/s. As duas taxas saem do programa da seção sobre largura de canal.
Juntas dão 2975,6, e a caixa arredonda para 3000. **Nenhum cliente usa os dois rádios ao mesmo tempo**,
então o máximo que um aparelho poderia ver é 2402, e mesmo isso é taxa de enlace, não download.

A **taxa de enlace** é a taxa com que os próprios quadros são enviados, e é o que um celular mostra nos
detalhes do Wi-Fi. O que chega, a vazão, é sempre menos, por motivos que não têm nada a ver com defeito,
e **o primeiro deles é que só um aparelho fala de cada vez**:

- O ar é half duplex. Num canal, um aparelho transmite por vez: o ponto de acesso e todos os clientes se
  revezam, e um upload e um download dividem o mesmo ar em vez de correrem lado a lado como num cabo
  Ethernet comutado.
- Toda transmissão paga um custo fixo antes dos dados: um preâmbulo enviado a uma taxa lenta e fixa para
  que todo mundo o ouça, um intervalo, uma espera aleatória para não colidir com os outros, e uma
  confirmação depois.
- Um quadro perdido para o ruído ou numa colisão é enviado de novo, e um cliente que perde muitos passa
  para uma modulação mais lenta.

O valor citado para um único cliente perto do ponto de acesso, com TCP, fica **em torno de 50 a 70% da taxa de enlace**. É um valor típico da
prática, não um número que algum padrão define. O programa abaixo usa 60%.

## O recurso é o tempo de ar

O que um canal divide é tempo, e um cliente gasta tempo na razão inversa da sua taxa. Quatro clientes
num ponto de acesso, num canal de 80 MHz, baixam cada um um arquivo de 10 MB. As taxas de enlace são as
que um celular e um laptop Wi-Fi 6 negociariam a distâncias diferentes, mais a de uma impressora antiga
802.11g. O programa foi executado com `python3`:

```schooling-example
{"language": "python", "file": "airtime.py", "parts": [{"code": "# Four clients each download 10 MB from one access point, on one channel.\nFILE_BITS = 10 * 8_000_000  # 10 MB\nEFFICIENCY = 0.6            # share of the link rate left after overheads: a typical value", "note": "Dez megabytes são oitenta milhões de bits. Os 60% são a premissa desta seção, uma fração típica para um cliente perto do ponto de acesso, e mudá-la altera todos os tempos abaixo pelo mesmo fator sem mudar qual cliente é o problema."}, {"code": "clients = {                 # the link rate each one negotiated, in Mbit/s\n    \"phone, same room\": 1201,\n    \"laptop, next room\": 720,\n    \"phone, far corner\": 72,\n    \"old 802.11g printer\": 54,\n}", "note": "Dois fluxos em 80 MHz dão ao celular 1201 Mbit/s de perto. O laptop na sala ao lado caiu para 64-QAM, 720, e o celular no canto mais distante para a modulação mais lenta, 72. A impressora só fala 802.11g e o melhor dela é 54."}, {"code": "busy = 0.0\nfor name, link in clients.items():\n    seconds = FILE_BITS / (link * 1e6 * EFFICIENCY)\n    busy += seconds\n    print(f\"{name:20} {link:5} Mbit/s  {seconds:6.3f} s of airtime\")", "note": "O tempo de ar de cada cliente é o arquivo dividido pela taxa que ele realmente obtém. O canal atende um de cada vez, então os tempos se somam."}, {"code": "moved = FILE_BITS * len(clients)\nprint(f\"channel busy {busy:.3f} s for 40 MB: {moved / busy / 1e6:.1f} Mbit/s in all\")\nprint(f\"four phones in the same room instead: {1201 * EFFICIENCY:.1f} Mbit/s in all\")", "note": "A vazão do canal inteiro é tudo o que passou dividido pelo tempo em que ele ficou ocupado, comparada com os mesmos quatro downloads para quatro celulares que estivessem todos perto."}], "output": "phone, same room      1201 Mbit/s   0.111 s of airtime\nlaptop, next room      720 Mbit/s   0.185 s of airtime\nphone, far corner       72 Mbit/s   1.852 s of airtime\nold 802.11g printer     54 Mbit/s   2.469 s of airtime\nchannel busy 4.617 s for 40 MB: 69.3 Mbit/s in all\nfour phones in the same room instead: 720.6 Mbit/s in all"}
```

Os dois clientes rápidos terminaram em menos de um terço de segundo, somados. **Os dois lentos ocuparam
o canal por 4,3 dos 4,6 segundos**, e puxaram o canal inteiro para 69,3 Mbit/s, onde quatro celulares na
mesma sala teriam dividido 720,6. Ninguém naquela sala reclama da impressora. Reclamam que o Wi-Fi está
lento.

As aulas 7, 9 e 10 partem dessa conta: mais pontos de acesso, cada um perto dos seus clientes, e as
taxas mais antigas desligadas para que nada tão lento entre. Alguns pontos de acesso também dividem o ar
**por tempo, e não por bytes**, uma parcela igual de segundos por cliente. Os fabricantes chamam isso de
airtime fairness. Protege os clientes rápidos dos lentos e não deixa ninguém mais rápido.

## O que este laboratório não consegue mostrar

O laboratório **não tem rádio**. As máquinas dele são ligadas por Ethernet virtual, que é full duplex,
nunca perde um quadro por ruído e não tem tempo de ar a dividir. Então nada nesta aula é captura: as
taxas são a aritmética do padrão e os 60% são uma premissa declarada. Num laptop Linux de verdade, `iw
dev wlan0 link` informa a taxa de enlace e o `iperf3`, que a aula 22 roda nos fios do laboratório, mede o
que chega. Nenhum dos dois foi executado pelo ar para esta aula.
