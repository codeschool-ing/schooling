---
title: "Tipos de instância: uma família, uma geração e um tamanho"
version: 1
---

A lista de tipos de instância parece um catálogo de códigos arbitrários, e quem usa pela primeira vez
escolhe um rolando a página. **Os códigos são uma gramática**, e depois que você lê um consegue situar
qualquer tipo do menu sem consultar nada.

Um tipo é uma combinação fixa de threads de processador e memória, mais uma cota de rede e às vezes
discos locais. O que separa as famílias é a **proporção** entre memória e processador, porque é isso
que muda entre cargas de trabalho: uma aplicação web quer um pouco de cada, um codificador de vídeo
quer processador e pouca memória, e um cache em memória quer o contrário.

| família | para que serve | memória por vCPU na AWS |
|---|---|---|
| uso geral, `m` | a maioria dos servidores, quando não há motivo para escolher outra | 4 GiB |
| otimizada para computação, `c` | trabalho que é sobretudo cálculo: codificação, compilação, lotes | 2 GiB |
| otimizada para memória, `r` | bancos de dados, caches, tudo o que guarda muito em memória | 8 GiB |
| burstable, `t` | máquinas que passam a maior parte do tempo ociosas | varia |

A tabela de preços mostra duas dessas proporções lado a lado. `m7i.large` tem 2 vCPU com 8 GiB e
`c7i.large` tem 2 vCPU com 4 GiB: o mesmo processador, metade da memória, e 0,13755 USD por hora
contra 0,16065 em `sa-east-1`.

## Lendo um nome

`m7i.large` são quatro informações, e os nomes dos outros provedores se decompõem do mesmo jeito,
com outras letras.

| pedaço | em `m7i.large` | o que diz |
|---|---|---|
| família | `m` | uso geral |
| geração | `7` | a sétima desta família; número maior é hardware mais novo |
| atributos | `i` | o processador: `i` Intel, `a` AMD, `g` o Graviton da própria AWS, que é Arm |
| tamanho | `large` | quanto da proporção da família você leva; `xlarge` é o dobro |

Mais letras podem vir depois do processador. `d` quer dizer que o host tem discos locais para a
instância (o instance store, que não sobrevive a um stop; a seção sobre discos desta aula explica), e
`n` quer dizer mais banda de rede. Então `m7gd.large` é a `m7g.large` com um disco local.

**O `g` não é detalhe.** Um processador Arm roda programas compilados para Arm, e um binário feito
para x86-64 não inicia nele. As grandes distribuições Linux, os runtimes das linguagens e a maioria
das imagens de contêiner publicam builds para Arm, então um serviço em Python ou Java costuma migrar
sem mudança; o binário fechado de um fornecedor, ou uma biblioteca nativa que ninguém compilou para
`arm64`, é onde a migração para.

## Uma vCPU é uma thread, não um núcleo

**Uma vCPU é uma thread de hardware.** Nos tipos Intel e AMD, cada núcleo físico roda duas threads ao
mesmo tempo (simultaneous multithreading), então as 2 vCPU da `m7i.large` são um núcleo. Os
processadores Graviton não têm a segunda thread, então as 2 vCPU da `m7g.large` são dois núcleos
inteiros. O mesmo número na tabela, portanto, não quer dizer a mesma quantidade de processador nas
duas, e é mais um motivo para a próxima seção mandar medir em vez de comparar rótulos.

## Tipos burstable, em linhas gerais

A família `t` (`t3` na Intel, `t4g` no Graviton) vende um **baseline** em vez da thread inteira: uma
porcentagem de cada vCPU que a instância pode usar o tempo todo. Abaixo do baseline ela acumula
créditos de CPU; acima dele, gasta. Quando os créditos acabam, o que acontece depende de uma
configuração. No modo standard a instância fica presa ao baseline, e no modo unlimited ela continua em
velocidade máxima e o excedente é cobrado. A AWS lança `t3` e `t4g` em modo unlimited, a menos que
você diga outra coisa.

A tabela põe um número nessa troca. `t3.medium` tem 2 vCPU e 4 GiB por 0,06720 USD por hora em
`sa-east-1`; `c7i.large` também tem 2 vCPU e 4 GiB, por 0,13755. **A máquina burstable custa metade
porque não promete o processador o dia inteiro.** Para um servidor de homologação que fica ocioso
entre um deploy e outro, é uma pechincha. Para um serviço que fica em 70% de CPU das nove às seis, é
uma máquina que ou está sendo segurada ou está cobrando excedente em silêncio, e um tipo fixo teria
saído mais barato e mais rápido.
