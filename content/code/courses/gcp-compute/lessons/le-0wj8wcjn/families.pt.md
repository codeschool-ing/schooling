---
title: Famílias, e a proporção que decide entre elas
version: 1
---

O jeito errado de escolher uma máquina é escolher um tamanho e depois uma família. **A família vem
primeiro, porque decide duas coisas que o tamanho não muda: a proporção de memória por processador
e o preço de cada um.** O Google agrupa as séries em quatro famílias, e quase tudo que uma equipe
pequena roda cabe na primeira.

## As quatro famílias

**Uso geral** é o padrão, e tem três níveis que diferem no que prometem:

- **E2** é a mais barata por vCPU. O Google escolhe o processador, Intel ou AMD, entre o que a zona
  tiver. Não há desconto por uso contínuo na E2, o desconto automático de até 30% que algumas
  outras séries ganham por rodar mais de um quarto do mês; o preço já começa baixo.
- **N4, N2 e N2D** fixam o processador, então um benchmark feito hoje continua valendo no mês que
  vem. A N4 é a mais nova; ela usa só Hyperdisk, a família de discos que a lição 3 compara com os
  discos persistentes.
- **C4, C4A e C4D** são o nível de desempenho, com os processadores mais novos e a maior banda de
  rede. **A C4A é Arm**, o Axion do próprio Google, o que quer dizer que as suas imagens e toda
  dependência compilada precisam ser feitas para `arm64`.

**Otimizada para computação** (C2, C2D, H3, H4D) é para trabalho que é quase só cálculo:
simulações, codificadores, computação de alto desempenho. **Otimizada para memória** (M1 a M4, X4)
começa onde o uso geral termina, perto de um terabyte de memória, para bancos que guardam tudo na
memória. **Otimizada para aceleradores** (A2, A3, G2, G4) traz GPUs e é o assunto da lição 2.

## O que a proporção custa

Eis toda máquina de 2 vCPUs da tabela, pelo programa da seção 03:

```
ana@laptop:~/gcp$ python3 prices.py vm | grep -E "standard-2|highcpu-2|highmem-2"
  e2-standard-2   2 vCPU   8 GiB    0.06701142       48.92    0.040212
  e2-highcpu-2    2 vCPU   2 GiB    0.04947024       36.11           -
  e2-highmem-2    2 vCPU  16 GiB    0.09039966       65.99           -
  n4-standard-2   2 vCPU   8 GiB        0.0907       66.21    0.053652
  n4-highcpu-2    2 vCPU   4 GiB       0.07654       55.87           -
  n4-highmem-2    2 vCPU  16 GiB       0.11902       86.88           -
  n2-standard-2   2 vCPU   8 GiB      0.097118       70.90    0.058256
  n2d-standard-2  2 vCPU   8 GiB      0.084492       61.68           -
  c4-standard-2   2 vCPU   7 GiB      0.096866       70.71    0.057979
  c4a-standard-2  2 vCPU   8 GiB        0.0898       65.55    0.044388
```

Leia duas vezes: na horizontal, pela proporção, e na vertical, pelo nível. **Na horizontal**, a
memória é quase tudo que muda o preço dentro de uma série: `e2-highcpu-2` com 2 GiB custa 36,11 por
mês, `e2-standard-2` com 8 GiB custa 48,92, `e2-highmem-2` com 16 GiB custa 65,99. **Na
vertical**, os mesmos 8 GiB e 2 vCPUs custam 48,92 na E2, 61,68 na N2D, 66,21 na N4 e 70,90 na N2.
O que os 22 dólares a mais por mês compram na N4 é um processador que não muda e faz mais por vCPU,
o que importa quando a máquina está ocupada e não importa nada quando ela está ociosa.

Então a proporção é a primeira medida a fazer, e ela vem do programa, não do catálogo. Um serviço
que se acomoda em 11 GiB de memória sob carga real, com duas vCPUs ocupadas, tem três escolhas
honestas na E2:

| máquina | vCPU | GiB | por mês | o que sobra |
|---|---|---|---|---|
| `e2-standard-4` | 4 | 16 | 97,84 | duas vCPUs que ninguém usa |
| `e2-highmem-2` | 2 | 16 | 65,99 | 5 GiB de folga |
| um tipo custom | 2 | 12 | seção 06 | nada, com um adicional |

Escolher primeiro o tamanho, "precisa de mais memória, então o tamanho seguinte", cai na primeira
linha e paga 31,85 por mês a mais que a segunda por processadores parados. **Em um ano são 382
dólares numa única máquina**, e um grupo delas multiplica isso.

## Onde cada uma cabe

A regra prática que sobrevive à maioria dos casos é curta. **Comece na E2**, porque é a mais barata
e o trabalho de uma equipe pequena (uma aplicação web, um worker, um agente de build) raramente
percebe qual processador recebeu. **Passe para N4 ou C4** quando uma medição disser que o
processador é o gargalo, ou quando o software não puder ver o processador mudar debaixo dele.
**Considere a C4A** quando o software já roda em Arm, porque com as mesmas vCPUs e mais memória ela
custa menos que a C4. E recorra às outras famílias só para o trabalho que dá nome a elas.
