---
title: dBm e miliwatts
version: 1
---

A potência de rádio cobre uma faixa que nenhuma unidade comum trata bem. Um ponto de acesso transmite um
décimo de watt; o que chega a um celular do outro lado do escritório muitas vezes é menos de um
milionésimo de miliwatt, e o enlace ainda funciona. Escrever isso em miliwatts é contar zeros, então todo
mundo em redes sem fio escreve em **dBm: decibéis em relação a um miliwatt**, dez vezes o logaritmo da
potência em mW.

O logaritmo é o que faz valer a pena aprender, porque transforma multiplicação em soma. **+3 dB dobram a
potência, +10 dB a multiplicam por dez**, e os sinais de menos cortam pela metade e dividem. Um ganho ou
uma perda em dB, o ganho de uma antena, a perda de um cabo, a atenuação de uma parede, simplesmente se
soma a um nível em dBm. O programa abaixo converte nos dois sentidos e faz um pequeno orçamento. Foi
executado com `python3`:

```schooling-example
{"language": "python", "file": "dbm.py", "parts": [{"code": "from math import log10\n\ndef to_dbm(mw):\n    return 10 * log10(mw)\n\ndef to_mw(dbm):\n    return 10 ** (dbm / 10)", "note": "As duas conversões, e nada mais é preciso. dBm é dez vezes o logaritmo na base 10 da potência em miliwatts; a volta é dez elevado a um décimo disso."}, {"code": "for mw in (1, 2, 10, 100, 200, 1000):\n    print(f\"{mw:5} mW = {to_dbm(mw):5.1f} dBm\")", "note": "Miliwatts para dBm. Dobrar, de 1 para 2 ou de 100 para 200, soma 3,0; multiplicar por dez soma exatamente 10."}, {"code": "for dbm in (-30, -67, -90):\n    print(f\"{dbm:4} dBm = {to_mw(dbm):.0e} mW\")", "note": "Níveis recebidos, que são negativos porque são frações de um miliwatt. Impressos com um algarismo significativo, então -67 dBm aparece como 2e-07 mW."}, {"code": "radio, antenna, cable = 17, 5, -2  # dBm, dBi, dB: gains and losses simply add\nprint(f\"EIRP: {radio} + {antenna} + ({cable}) = {radio + antenna + cable} dBm\")", "note": "Um orçamento de transmissão. Um rádio de 17 dBm, uma antena de 5 dBi e um cabo que perde 2 dB dão 20 dBm de EIRP, só somando."}, {"code": "ap, phone = 23, 14  # transmit power in dBm\nprint(f\"AP {ap} dBm is {to_mw(ap):.0f} mW; phone {phone} dBm is {to_mw(phone):.0f} mW\")\nprint(f\"{ap - phone} dB apart: the AP is {to_mw(ap) / to_mw(phone):.1f} times louder\")", "note": "As duas pontas de um enlace, com as potências de transmissão da próxima seção: nove decibéis são quase oito vezes a potência."}, {"code": "loss = 98  # dB between the two, the same in both directions\nprint(f\"the phone hears the AP at {ap - loss} dBm; the AP hears the phone at {phone - loss} dBm\")", "note": "A mesma perda vale nos dois sentidos, então cada ponta ouve a outra tão mais fraca quanto ela transmite."}], "output": "    1 mW =   0.0 dBm\n    2 mW =   3.0 dBm\n   10 mW =  10.0 dBm\n  100 mW =  20.0 dBm\n  200 mW =  23.0 dBm\n 1000 mW =  30.0 dBm\n -30 dBm = 1e-03 mW\n -67 dBm = 2e-07 mW\n -90 dBm = 1e-09 mW\nEIRP: 17 + 5 + (-2) = 20 dBm\nAP 23 dBm is 200 mW; phone 14 dBm is 25 mW\n9 dB apart: the AP is 7.9 times louder\nthe phone hears the AP at -75 dBm; the AP hears the phone at -84 dBm"}
```

Leia o primeiro bloco como uma tabela para saber de cor: **0 dBm é 1 mW, 20 dBm são 100 mW, 30 dBm são um
watt**, e 23 dBm são 200 mW porque 3 dB a mais é o dobro. O segundo bloco é a outra ponta da escala. Um
celular que informa −67 dBm está recebendo cerca de 2e-07 mW, dois décimos de milionésimo de miliwatt, e
os valores impressos estão arredondados para um algarismo. Isso é um sinal forte para o Wi-Fi; a aula 10
explica por que −67 dBm é o nível que os projetistas buscam, e −90 dBm fica perto de onde o ruído começa.

**Um nível recebido é negativo, e mais perto de zero é mais forte.** −50 dBm é cem vezes mais potência
que −70 dBm, e não um número menor que de algum jeito é melhor. Quem lê −70 como "mais alto" que −50
porque 70 é maior está lendo errado uma escala em que o sinal de menos faz todo o trabalho.

## EIRP, o que as regras limitam

A potência de um rádio é só parte do que sai da antena. A **EIRP**, a potência efetivamente irradiada
isotropicamente, é a saída do rádio mais o ganho da antena em dBi menos a perda no cabo entre os dois:
17 + 5 − 2 = 20 dBm no exemplo. Os reguladores limitam a EIRP, e não só o rádio, porque é a antena que
decide quanta energia chega a uma direção. Na Europa o limite em 2,4 GHz é 100 mW de EIRP, 20 dBm; nos
Estados Unidos um rádio pode entregar 1 W e usar uma antena de até 6 dBi. Pôr uma antena maior num ponto
de acesso, portanto, gasta a mesma cota, e um ponto de acesso que conhece o seu país e a sua antena
reduz a própria potência para ficar dentro dela.
