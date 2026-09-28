---
title: Largura de canal, e a taxa que ela compra
version: 1
---

Toda taxa da tabela da primeira seção vem de quatro números que o padrão fixa, multiplicados entre si.
Um canal Wi-Fi é cortado em centenas de **subportadoras** estreitas, cada uma levando alguns bits por
vez, e todas são enviadas juntas como um **símbolo**. A taxa de um fluxo é quantos bits de dados um
símbolo leva, dividido pela duração de um símbolo. **Alargue o canal e há mais subportadoras, logo mais
bits por símbolo**, que é a única coisa que a largura compra.

O programa abaixo faz a multiplicação para as emendas desta aula. Ele foi executado com `python3`, e o
que imprimiu está embaixo.

```schooling-example
{"language": "python", "file": "rates.py", "parts": [{"code": "# The rate of one spatial stream, from four numbers the standard fixes.\ndef per_stream(subcarriers, bits, coding, symbol_us):\n    return subcarriers * bits * coding / symbol_us  # bits per microsecond = Mbit/s", "note": "Um símbolo OFDM leva um ou vários bits em cada uma das subportadoras de dados. Multiplique pela fração desses bits que é dado, e não correção de erro, divida pela duração de um símbolo em microssegundos, e o resultado sai em Mbit/s."}, {"code": "# name, data subcarriers, bits per subcarrier, coding rate, symbol time in us, streams\nLINKS = [", "note": "Uma linha por enlace. A taxa de codificação é a fração de dado de verdade: 3/4 quer dizer que um bit em cada quatro é redundância que o receptor usa para corrigir erros."}, {"code": "    (\"802.11a/g   20 MHz\",   48,  6, 3/4,  4.0,  1),\n    (\"802.11n     40 MHz\",  108,  6, 5/6,  3.6,  4),\n    (\"802.11ac   160 MHz\",  468,  8, 5/6,  3.6,  8),", "note": "802.11a e g: 48 subportadoras de dados em 20 MHz, 64-QAM levando 6 bits em cada, e um símbolo a cada 4 microssegundos, o que dá os 54 Mbit/s de 1999. O 802.11n alarga para 40 MHz, encurta o intervalo de guarda para o símbolo durar 3,6, e permite quatro fluxos. O 802.11ac chega a 160 MHz, 256-QAM com 8 bits, e oito fluxos."}, {"code": "    (\"802.11ax    20 MHz\",  234, 10, 5/6, 13.6,  1),\n    (\"802.11ax    40 MHz\",  468, 10, 5/6, 13.6,  1),\n    (\"802.11ax    80 MHz\",  980, 10, 5/6, 13.6,  1),\n    (\"802.11ax   160 MHz\", 1960, 10, 5/6, 13.6,  1),\n    (\"802.11ax   160 MHz\", 1960, 10, 5/6, 13.6,  8),", "note": "O 802.11ax corta o mesmo canal em quatro vezes mais subportadoras, cada uma quatro vezes mais longa, então um símbolo dura 13,6 microssegundos com a guarda, e acrescenta 1024-QAM, 10 bits. As quatro primeiras linhas aqui são só a questão da largura, um fluxo cada; a quinta é o topo do padrão."}, {"code": "    (\"802.11be   320 MHz\", 3920, 12, 5/6, 13.6, 16),\n]", "note": "O 802.11be dobra o canal mais largo para 320 MHz, só em 6 GHz, leva 12 bits com 4096-QAM e prevê dezesseis fluxos. É um teto no papel: pontos de acesso saem com poucos fluxos por rádio, e celulares com dois."}, {"code": "for name, subcarriers, bits, coding, symbol_us, streams in LINKS:\n    one = per_stream(subcarriers, bits, coding, symbol_us)\n    print(f\"{name}  {one:7.1f} x {streams:2} = {one * streams:8.1f} Mbit/s\")", "note": "Imprime a taxa de cada linha com um fluxo, e com todos os fluxos juntos."}], "output": "802.11a/g   20 MHz     54.0 x  1 =     54.0 Mbit/s\n802.11n     40 MHz    150.0 x  4 =    600.0 Mbit/s\n802.11ac   160 MHz    866.7 x  8 =   6933.3 Mbit/s\n802.11ax    20 MHz    143.4 x  1 =    143.4 Mbit/s\n802.11ax    40 MHz    286.8 x  1 =    286.8 Mbit/s\n802.11ax    80 MHz    600.5 x  1 =    600.5 Mbit/s\n802.11ax   160 MHz   1201.0 x  1 =   1201.0 Mbit/s\n802.11ax   160 MHz   1201.0 x  8 =   9607.8 Mbit/s\n802.11be   320 MHz   2882.4 x 16 =  46117.6 Mbit/s"}
```

Leia as quatro linhas do 802.11ax com um fluxo: 143,4, 286,8, 600,5 e 1201,0 Mbit/s. **Cada vez que a
largura dobra, a taxa um pouco mais que dobra**, porque um canal mais largo desperdiça proporcionalmente
menos subportadoras nas bordas. Isso parece um motivo para escolher sempre o canal mais largo. Não é,
porque a largura tem três custos, e nenhum deles aparece no programa.

**Menos canais para dividir.** Uma faixa tem uma quantidade fixa de espectro, então cada vez que a
largura dobra o número de canais nela cai pela metade. Pontos de acesso próximos precisam de canais
diferentes, ou se revezam (a aula 7 explica como), e em 2,4 GHz um único canal de 40 MHz ocupa quase
metade da faixa. A faixa de 6 GHz, a mais larga que existe, mostra a troca em números, onde os 1200 MHz
estão liberados:

| largura do canal | 20 MHz | 40 MHz | 80 MHz | 160 MHz | 320 MHz |
|---|---|---|---|---|---|
| canais que não se sobrepõem | 59 | 29 | 14 | 7 | 3 |
| um fluxo 802.11ax, Mbit/s (o programa acima) | 143,4 | 286,8 | 600,5 | 1201,0 | não existe no 802.11ax |

**Menos sinal contra o ruído.** Um transmissor tem potência fixa, e um canal mais largo a espalha mais
fino, enquanto o ruído que o receptor ouve cresce com a largura que ele escuta. Dobre a largura e o total
do sinal fica igual enquanto o ruído dobra: **cada vez que a largura dobra, perdem-se 3 dB de relação
sinal-ruído**. Na borda de uma célula, um cliente em 160 MHz cai para uma modulação mais lenta antes de
um em 40 MHz, e pode acabar com uma taxa menor do que teria no canal mais estreito.

**Mais exposição a um vizinho.** Um canal de 160 MHz se sobrepõe a qualquer coisa que transmita em
qualquer uma das suas oito partes de 20 MHz. Desde o 802.11ac um ponto de acesso consegue recuar para
parte do canal quando o resto está ocupado, e desde o 802.11ax (e mais ainda no Wi-Fi 7) consegue deixar
de fora uma fatia ocupada, mas ainda assim transmite menos vezes do que transmitiria num canal só dele.

Então a escolha é feita por faixa e por prédio, e a prática se acomodou num padrão que é costume e não
está escrito em lugar nenhum: **20 MHz em 2,4 GHz, sempre**, 20 ou 40 MHz em 5 GHz onde os pontos de
acesso são densos, e 80 ou 160 em 6 GHz, onde há canais para todo mundo. Uma casa com um ponto de acesso
e nenhum vizinho pode usar o canal mais largo que tiver, porque não há com quem dividi-lo.
