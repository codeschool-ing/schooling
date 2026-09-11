---
title: Uma máquina inteira de controle
version: 1
---

O passo seguinte é receber uma máquina — não uma pasta dentro de uma — e com ela cada decisão e cada
consequência que o provedor da seção anterior estava absorvendo em seu nome.

## Virtual, e o que isso quer dizer

Quase ninguém recebe hardware físico. Um **servidor virtual privado** é uma fatia de uma máquina
real, isolada das outras fatias pela mesma tecnologia que roda a maior parte da internet.

A palavra privado é a importante. Você recebe uma alocação fixa de processador, memória e disco que
é *sua* — a carga de um vizinho não a toma — e um sistema operacional próprio com acesso
administrativo. Você escolhe a distribuição, instala o que quiser, configura o servidor web você
mesmo, e roda qualquer coisa que se rode num computador.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Uma máquina física dividida em fatias. Cada fatia tem uma alocação fixa de processador, memória e disco e um sistema operacional próprio, então a carga de um vizinho não toma a sua.\"> <rect x=\"20\" y=\"30\" width=\"680\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"360\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\">uma máquina física, dividida</text> <rect x=\"40\" y=\"70\" width=\"200\" height=\"94\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"140\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sua</text> <text x=\"140\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">2 processadores, 4 GB</text> <text x=\"140\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">um sistema operacional</text> <text x=\"140\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">só seu</text> <rect x=\"252\" y=\"70\" width=\"200\" height=\"94\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\"></rect> <text x=\"352\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">de outra pessoa</text> <text x=\"352\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">2 processadores, 4 GB</text> <text x=\"352\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o que quer que rodem</text> <rect x=\"464\" y=\"70\" width=\"216\" height=\"94\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\"></rect> <text x=\"572\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">e mais fatias</text> <text x=\"572\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">cada uma com parte fixa</text> <text x=\"572\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">que é só delas</text> <text x=\"360\" y=\"212\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a alocação é a diferença: um vizinho ocupado não toma a sua</text> <text x=\"360\" y=\"242\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">e também o fato de tudo naquela máquina virar responsabilidade sua</text> </svg>", "caption": "Uma parte fixa e um sistema operacional só seu. As duas metades disso são a troca."}
```

Um **servidor dedicado** é o mesmo arranjo sem o fatiamento: a máquina física inteira. Vale mais
quando você precisa de cada pedaço do hardware, quando uma licença é cobrada por máquina, ou quando
uma regra diz que seus dados não podem dividir hardware com ninguém. Para a maior parte do trabalho a
virtual é indistinguível e bem mais barata.

## O que você acabou de assumir

Diga isto explicitamente, porque é a troca inteira e costuma ser descoberta em vez de decidida.

**Atualizações de segurança.** Ninguém as aplica por você. Uma máquina sem atualizações num endereço
público é encontrada por varredura automatizada em horas, e isso não é exagero — é a cara do log de
qualquer servidor novo.

**O servidor web.** Instalar, configurar, e o proxy reverso na frente da sua aplicação.

**Certificados.** Obter e renovar, que é a última leitura desta aula porque é onde mais sites
quebram.

**Cópias de segurança.** O provedor tira uma imagem do disco se você pedir e pagar; ninguém faz cópia
do seu banco de dados a menos que você arranje isso, e uma cópia que ninguém restaurou é uma
esperança, não uma cópia.

**Ser acordado.** Não existe fila de suporte que conserte sua aplicação. A responsabilidade do
provedor termina no hardware e na rede.

Essa lista não é um argumento contra. É o preço, e vale pagar quando você precisa do que ele compra
— que é a capacidade de rodar o que quiser, como quiser, a um custo que para de crescer junto com as
suas ambições.

## Quanto custa, e o formato da curva

Um servidor virtual pequeno custa algumas unidades de moeda por mês e aguenta uma quantidade
surpreendente de tráfego. Um maior custa um múltiplo disso.

O que importa é o formato e não o número: **ele é fixo.** Um mês calmo custa o que um mês movimentado
custa. Isso é vantagem sobre a cobrança da próxima leitura quando sua carga é estável e desvantagem
quando não é, e é a coisa mais útil de saber ao comparar as duas.

## Dimensionar, coisa que as pessoas erram nos dois sentidos

O instinto é comprar com generosidade. O instinto melhor é comprar pequeno e observar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Três recursos comparados: a memória acaba de repente e mata um processo, o disco enche em silêncio e tranca você do lado de fora, e o processador costuma ser a última restrição a apertar.\"> <rect x=\"20\" y=\"34\" width=\"216\" height=\"120\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".22\" stroke=\"var(--amber)\"></rect> <text x=\"128\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">memória</text> <text x=\"128\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">acaba de repente</text> <text x=\"128\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">o sistema mata seu</text> <text x=\"128\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">maior processo</text> <rect x=\"252\" y=\"34\" width=\"216\" height=\"120\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".16\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">disco</text> <text x=\"360\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">enche em silêncio</text> <text x=\"360\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">e então nada consegue</text> <text x=\"360\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">escrever, nem você</text> <rect x=\"484\" y=\"34\" width=\"216\" height=\"120\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".18\" stroke=\"var(--phosphor)\"></rect> <text x=\"592\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">processador</text> <text x=\"592\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">em geral o último</text> <text x=\"592\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a apertar, e o que</text> <text x=\"592\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a página de preços vende</text> <text x=\"360\" y=\"196\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\">compre pequeno e observe, e deixe a folga na memória</text> <text x=\"360\" y=\"226\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">rotacionar os logs é um trabalho de cinco minutos que evita uma queda sem causa óbvia</text> </svg>", "caption": "Três recursos, três jeitos diferentes de falhar, e as páginas de preço são organizadas em torno do menos perigoso."}
```

A maioria das aplicações pequenas é limitada pela **memória** bem antes do processador, e a falha
quando a memória acaba é abrupta: o sistema mata o maior processo, que é a sua aplicação ou o seu
banco, e o site cai em vez de ficar lento. Essa assimetria é o argumento para deixar folga na memória
especificamente.

O disco é o que falha em silêncio e é esquecido. Logs crescem. Uma máquina com disco cheio não
consegue escrever uma linha de log, não consegue escrever uma sessão, e muitas vezes não dá para
entrar nela para consertar. Rotacionar os logs é um trabalho de cinco minutos que evita uma queda sem
causa óbvia.

E o processador costuma ser a última restrição a apertar, que é o oposto do que as páginas de preço
incentivam você a acreditar.

## A primeira hora numa máquina nova

Não é uma lista para decorar, e vale ver uma vez, porque uma máquina deixada como chegou é uma
máquina que é encontrada.

**Atualizações primeiro.** Antes de qualquer coisa rodar, aplique o que estiver pendente, e arranje
para que as atualizações de segurança sigam chegando.

**Desligue o login por senha.** Use uma chave, e desative o caminho da senha por completo. A varredura
que encontra sua máquina está adivinhando senhas, e uma chave torna essa tentativa inútil em vez de
lenta.

**Feche tudo que você não usa.** Um firewall que permite as portas web e o seu caminho de entrada, e
recusa o resto. Bancos de dados em particular deveriam escutar a máquina em vez do mundo, e o número
de bancos na internet pública com senha padrão é uma cifra bem documentada e deprimente.

**Não rode a aplicação como administrador.** Uma conta separada com não mais acesso do que a aplicação
precisa transforma um comprometimento num comprometimento menor.

**Decida as cópias de segurança agora**, enquanto a máquina está vazia e leva dez minutos, em vez de
depois que houver nela algo que valha perder.

## O que torna tudo isso valer a pena

Uma nota prática para terminar, porque é fácil perdê-la lendo uma lista de tarefas.

Uma máquina que você controla é uma máquina que você consegue **reproduzir**. A configuração pode
estar num arquivo, o arquivo pode estar num repositório, e uma máquina nova pode ser construída a
partir dele em minutos. Isso não está disponível para você em hospedagem compartilhada a preço
nenhum, e é o que transforma um servidor de algo em que você tem medo de tocar em algo que dá para
jogar fora e reconstruir.

Se você assumir uma máquina, assuma isso junto. Um servidor que ninguém consegue reconstruir é um
servidor que um dia não poderá ser atualizado, e a razão disso é sempre a mesma: ninguém lembra o que
há nele.
