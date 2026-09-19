---
title: USB, onde os nomes são piores que a tecnologia
version: 1
---

USB é a porta em que tudo acaba entrando, e os nomes dela são a coisa mais confusa deste curso
inteiro. A culpa não é sua e não é acidente da história: a norma foi renomeada duas vezes, de um
jeito que fez nomes antigos valerem para coisas novas.

## Os formatos primeiro, porque esses pelo menos são honestos

| formato | onde você o encontra |
|---|---|
| **USB-A** | o retângulo achatado. O que todo mundo imagina, em todo desktop e todo hub |
| **USB-B** | o quadradão alto. Impressoras e interfaces de áudio |
| **Micro-B** | o trapézio pequeno. Celulares antes de uns 2018, e ainda em aparelhos baratos |
| **USB-C** | o oval pequeno, e o único que entra dos dois lados |

Cinco formatos, e um deles está sendo substituído por outro. **O USB-C está ganhando e é um
formato, não uma velocidade** — que é justamente a confusão que o resto desta seção existe para
desfazer.

## Os nomes, que descrevem os mesmos fios três vezes

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Três fileiras. A primeira diz 5 gigabits por segundo e lista os nomes USB 3.0, USB 3.1 Gen 1, USB 3.2 Gen 1 e SuperSpeed USB 5Gbps. A segunda diz 10 gigabits e lista USB 3.1 Gen 2, USB 3.2 Gen 2 e SuperSpeed USB 10Gbps. A terceira diz 20 gigabits e lista USB 3.2 Gen 2x2 e SuperSpeed USB 20Gbps. Uma nota diz que a velocidade é a única coluna que significa alguma coisa e que todo nome ao lado dela é o mesmo fio.\"><text x=\"24\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">As mesmas três velocidades, renomeadas duas vezes</text><text x=\"24\" y=\"48\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o que ele faz</text><text x=\"180\" y=\"48\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">e como já foi vendido</text><rect x=\"24\" y=\"62\" width=\"672\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"40\" y=\"84\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">5 Gb/s</text><text x=\"180\" y=\"84\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">USB 3.0 · USB 3.1 Gen 1 · USB 3.2 Gen 1 · SuperSpeed USB 5Gbps</text><rect x=\"24\" y=\"118\" width=\"672\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"40\" y=\"140\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">10 Gb/s</text><text x=\"180\" y=\"140\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">USB 3.1 Gen 2 · USB 3.2 Gen 2 · SuperSpeed USB 10Gbps</text><rect x=\"24\" y=\"174\" width=\"672\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"40\" y=\"196\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">20 Gb/s</text><text x=\"180\" y=\"196\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">USB 3.2 Gen 2x2 · SuperSpeed USB 20Gbps</text><text x=\"24\" y=\"240\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">A coluna da esquerda é a única que significa algo. Todo nome ao lado dela é o mesmo fio.</text></svg>", "caption": "Leia a velocidade e ignore o nome. Uma caixa anunciando USB 3.2 está anunciando um número entre 5 e 20 gigabits e não disse qual."}
```

**`USB 3.2` numa caixa não é informação.** Cobre de 5 a 20 gigabits. A única figura útil é a que
vem em gigabits, e é por isso que os nomes de propaganda acabaram mudando para pôr o número na
frente — `SuperSpeed USB 10Gbps` diz o que faz.

## A energia, que viaja pelo mesmo cabo e é uma negociação à parte

Uma porta USB-A comum fornece `2,5 W`, o bastante para um mouse e não para muito mais. O **USB
Power Delivery** deixa as duas pontas negociarem para cima, em degraus, até `240 W`.

A consequência com que as pessoas esbarram é esta: **um carregador USB-C não é um carregador
USB-C.** Um carregador de celular entregando `20 W` espetado num notebook que quer `65 W` vai
carregá-lo — devagar, ou só enquanto ele dorme, ou nada enquanto ele trabalha pesado. Nada está
quebrado e nada avisa. A potência vem impressa no carregador, em letra miúda, e é o número que
importa.

## O vídeo, que é uma terceira coisa separada

O **DisplayPort Alternate Mode** deixa uma porta USB-C carregar sinal de vídeo entregando parte
dos fios dela ao DisplayPort. Um soquete USB-C pode fazer isso ou não, e de novo o formato não
diz.

É por isso que um cabo USB-C para HDMI funciona num notebook e não faz nada em outro ao lado. O
cabo está bom. A porta da segunda máquina nunca teve os fios de vídeo ligados.

## Thunderbolt, que é o que promete tudo

O **Thunderbolt 3 e 4** usam o formato USB-C e garantem o que o USB deixa opcional: `40 Gb/s`,
vídeo, energia, e banda suficiente para rodar uma caixa de placa de vídeo externa ou um disco em
velocidade plena. O símbolo do raio ao lado da porta é a promessa.

O `USB4` é a norma construída a partir do Thunderbolt 3, então os dois hoje se sobrepõem quase
inteiramente. Se a porta tem o raio, tudo acima está garantido.

## O cabo é um componente, não um fio

Um cabo USB-C pode ser qualquer um destes: só carga, dados a `480 Mb/s`, `10 Gb/s`, `40 Gb/s`,
`60 W`, `240 W`. **Eles são idênticos por fora.** O cabo que vem na caixa de um celular é quase
sempre do tipo mais lento, e usá-lo para copiar um disco transforma um serviço de dez minutos em
duas horas sem aviso em lugar nenhum.

Guarde os cabos bons e marque-os. Isso não é frescura; é o único jeito de saber.
