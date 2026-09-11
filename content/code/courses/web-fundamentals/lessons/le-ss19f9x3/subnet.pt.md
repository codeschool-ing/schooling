---
title: Decidir o que é local
version: 1
---

Ao lado do endereço, em toda configuração de rede que você já abriu, há um segundo número. É a
**máscara**, e ela responde a uma pergunta: *quais endereços estão no meu próprio fio, e quais eu
tenho que entregar ao gateway?*

Essa pergunta é feita para cada pacote que uma máquina envia, e é a primeira decisão do roteamento
que você viu na aula dois.

## O endereço são duas partes, e a máscara diz onde elas se dividem

Um endereço é uma parte de rede e uma parte de host, grudadas. A parte de rede é igual para tudo
que está no seu fio; a parte de host é o que distingue duas máquinas dele.

A máscara diz quantos bits a partir da esquerda pertencem à rede.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Um endereço dividido por uma máscara. Vinte e quatro bits à esquerda sombreados como a parte de rede, oito à direita como a parte de host.\"><text x=\"360\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">192.168.1.24 / 24</text><rect x=\"24\" y=\"44\" width=\"480\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".22\" stroke=\"var(--phosphor)\"></rect><text x=\"264\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">a rede — 24 bits</text><text x=\"264\" y=\"110\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">192.168.1</text><rect x=\"516\" y=\"44\" width=\"180\" height=\"40\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".22\" stroke=\"var(--amber)\"></rect><text x=\"606\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">o host — 8 bits</text><text x=\"606\" y=\"110\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">.24</text><text x=\"264\" y=\"142\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">igual para tudo neste fio</text><text x=\"606\" y=\"142\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o que os distingue</text><text x=\"360\" y=\"182\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">dois endereços são locais entre si quando as partes de rede são idênticas</text></svg>", "caption": "A máscara não faz parte do endereço. Ela é como a máquina que tem o endereço o lê."}
```

Duas notações significam exatamente a mesma coisa. `255.255.255.0` escreve a máscara como um
endereço, com um 1 para cada bit de rede; `/24` apenas diz quantos são. A segunda se chama
**CIDR**, é o que você vai ver em quase todo lugar hoje, e é mais fácil de ler depois que você
aceita que é uma contagem.

## A conta que você de fato vai fazer

Com `/24`, os três primeiros números são a rede e o último é o host. Então:

- `192.168.1.24` e `192.168.1.99` são **locais** entre si — mande o quadro direto;
- `192.168.1.24` e `192.168.2.99` não são — entregue ao gateway.

É essa a decisão inteira, tomada por pacote, milhares de vezes por segundo.

Agora os tamanhos, que é a parte que as pessoas decoram e não deveriam precisar:

| máscara | bits de rede | endereços | utilizáveis | o que costuma ser |
|---|---|---|---|---|
| `/24` | 24 | 256 | 254 | uma rede doméstica ou de escritório comum |
| `/25` | 25 | 128 | 126 | metade de uma |
| `/26` | 26 | 64 | 62 | um segmento pequeno, um rack |
| `/30` | 30 | 4 | 2 | um enlace entre dois roteadores e mais nada |
| `/16` | 16 | 65.536 | 65.534 | uma empresa grande, uma rede de nuvem |

**Cada bit dado à rede corta a faixa pela metade.** É a única regra; a tabela é essa regra aplicada
cinco vezes. E a coluna de *utilizáveis* é sempre dois a menos, porque o primeiro endereço nomeia a
rede e o último é broadcast — os dois que você viu na seção anterior.

## A mesma conta, pelo outro lado

Há um segundo jeito de ler uma máscara, e é o que torna os tamanhos óbvios sem decorar nada.

Uma `/24` deixa 8 bits para o host, e 8 bits contam 256 valores. Uma `/25` deixa 7, que contam 128.
Uma `/26` deixa 6, que contam 64. **Os bits de host são o expoente**, e a tabela da seção anterior é
dois elevado a ele.

O que significa que você consegue responder às duas perguntas que aparecem na prática sem consultar
nada:

- *quantas máquinas cabem?* — conte os bits de host, eleve dois a isso, subtraia dois;
- *que máscara eu preciso para 50 máquinas?* — 6 bits de host dão 62 utilizáveis, 5 dão 30, então
  `/26`.

A subtração de dois pega as pessoas por um tempo e depois nunca mais. Uma faixa de quatro endereços
— uma `/30`, usada no enlace entre dois roteadores — tem exatamente dois utilizáveis, que é por que
esse tamanho existe.

## Por que alguém cortaria uma rede

Dividir uma faixa grande em várias menores se chama sub-rede, e é feito por três razões que nada
têm a ver com acabar endereços.

**Broadcast.** Parte do tráfego vai para tudo que está no fio — inclusive o ARP que você vai
encontrar daqui a duas seções. Numa rede de 65.000 máquinas isso é um barulho enorme chegando em
todas elas. Redes menores significam menos disso.

**Separação.** Tráfego entre duas sub-redes tem que passar por um roteador, e um roteador é um
lugar onde regras podem ser aplicadas. Colocar as impressoras, os servidores e o Wi-Fi de visitas
em sub-redes separadas é como uma rede ganha qualquer estrutura.

**Raio de dano.** Uma máquina com defeito inunda o próprio segmento, e não o prédio inteiro.

## O erro que parece uma rede quebrada

Um sintoma vale levar, porque é comum e parece outra coisa.

Uma máquina com o **endereço certo e a máscara errada** alcança algumas coisas e outras não, sem
padrão que faça sentido. Máscara estreita demais e ela trata máquinas locais como distantes,
mandando o tráfego delas para um gateway que pode não saber devolver. Larga demais e ela trata
máquinas distantes como locais, gritando no próprio fio por uma máquina que não está lá.

Tudo parece configurado. O endereço está certo. É o segundo número que está errado, e quase
ninguém o confere primeiro.

## Onde isto te deixa

A máscara divide um endereço numa parte de rede e numa parte de host, e duas máquinas são locais
quando as partes de rede coincidem. `/24` quer dizer 24 bits de rede e 256 endereços, 254 deles
utilizáveis, e cada bit a mais corta a faixa pela metade.

Essa decisão — local ou não — é tomada sobre o endereço. Mas um quadro não viaja por endereço, como
a aula dois fez questão de dizer. Ele viaja pelo número gravado numa placa de rede, e as próximas
duas seções são o que é esse número e como uma máquina descobre o do vizinho.
