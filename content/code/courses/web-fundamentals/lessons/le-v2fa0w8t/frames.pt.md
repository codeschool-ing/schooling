---
title: O quadro, e um salto
version: 1
---

Um pacote sabe para onde está indo no fim das contas. Ele não sabe como chegar lá e — esta é a
parte que leva um instante — **não consegue viajar a lugar nenhum sozinho**.

Um pacote é uma ideia. Cabos carregam eletricidade, fibra carrega luz e rádios carregam rádio.
Nenhum deles carrega ideias. Então, a cada passo físico da viagem, o pacote precisa ser embrulhado
em algo que o meio local realmente saiba entregar.

Esse embrulho é um **quadro**.

## Dois envelopes, duas vidas

Aqui está a distinção inteira, e vale ler devagar porque tudo o mais nesta seção é consequência
dela.

**O pacote é endereçado ao destino.** É criado pela máquina que o enviou, e o mesmo pacote — o
mesmo cabeçalho, a mesma carga — chega do outro lado. Ele atravessa a viagem toda.

**O quadro é endereçado à próxima máquina deste cabo.** É criado no começo de um salto e destruído
no fim desse mesmo salto. O salto seguinte constrói um novinho.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 254\" role=\"img\" aria-label=\"Um pacote atravessando quatro máquinas. Acima da linha, uma barra longa rotulada pacote cobrindo a viagem inteira. Abaixo dela, barras curtas separadas, uma por salto, cada uma rotulada quadro, mostrando que são construídas e destruídas a cada salto.\"><rect x=\"14\" y=\"96\" width=\"104\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"66\" y=\"119\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">seu notebook</text><rect x=\"202\" y=\"96\" width=\"104\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"254\" y=\"119\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">roteador de casa</text><rect x=\"390\" y=\"96\" width=\"104\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"442\" y=\"119\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">roteador ISP</text><rect x=\"578\" y=\"96\" width=\"128\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"642\" y=\"119\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">o servidor</text><rect x=\"14\" y=\"36\" width=\"692\" height=\"28\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".14\" stroke=\"var(--phosphor)\"></rect><text x=\"360\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">UM PACOTE — o mesmo, o caminho todo</text><text x=\"360\" y=\"26\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">para 203.0.113.7</text><rect x=\"118\" y=\"174\" width=\"84\" height=\"26\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".16\" stroke=\"var(--amber)\"></rect><text x=\"160\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">quadro 1</text><rect x=\"306\" y=\"174\" width=\"84\" height=\"26\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".16\" stroke=\"var(--amber)\"></rect><text x=\"348\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">quadro 2</text><rect x=\"494\" y=\"174\" width=\"84\" height=\"26\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".16\" stroke=\"var(--amber)\"></rect><text x=\"536\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">quadro 3</text><path d=\"M118 142 L160 170\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"3 3\" fill=\"none\"></path><path d=\"M202 142 L162 170\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"3 3\" fill=\"none\"></path><path d=\"M306 142 L348 170\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"3 3\" fill=\"none\"></path><path d=\"M390 142 L350 170\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"3 3\" fill=\"none\"></path><path d=\"M494 142 L536 170\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"3 3\" fill=\"none\"></path><path d=\"M578 142 L538 170\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"3 3\" fill=\"none\"></path><text x=\"360\" y=\"228\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">TRÊS QUADROS — cada um feito para um cabo e jogado fora no fim dele</text></svg>", "caption": "Um pacote, três quadros. O pacote é a viagem; um quadro é um único passo dela."}
```

Três saltos, três quadros. Cada um é escrito, levado por alguns metros ou algumas centenas de
quilômetros, lido e descartado. O pacote de dentro fica intocado.

Se você levar uma coisa desta seção, leve esta: **um quadro não é um pacote pequeno.** São objetos
diferentes, com endereços diferentes e vidas diferentes, e confundir os dois é o que faz as
próximas quatro aulas parecerem arbitrárias.

## Dois tipos de endereço, para dois tipos de pergunta

Os dois envelopes carregam dois tipos diferentes de endereço, porque respondem a duas perguntas
diferentes.

O endereço do pacote responde *onde no mundo*. O do quadro responde *qual tomada deste cabo*.

| | o endereço do pacote | o endereço do quadro |
|---|---|---|
| responde | para onde no mundo isto vai | qual máquina deste fio o pega em seguida |
| dado por | a rede em que você está, e muda quando você se move | a placa de rede, na fábrica |
| sobrevive | a viagem inteira | um salto |
| você vai conhecer direito em | aula 4 | aula 4 |

Por ora você não precisa de mais do que "um número que nomeia uma máquina" para o primeiro e "um
número gravado numa placa de rede" para o segundo. A aula 4 é onde os dois são lidos com
propriedade — a notação, as faixas, e como uma máquina descobre o número da placa do vizinho.

## A caixa que nunca abre o envelope

Nem toda caixa do caminho constrói um quadro novo. Algumas apenas passam quadros adiante, e a
diferença entre as duas é a maneira mais clara de entender onde um quadro para.

Um **comutador** — o *switch* — é a caixa de que a sua rede de casa ou do escritório é feita. Tem
várias portas, coisas plugadas nelas, e o trabalho dele é pegar um quadro que entra por uma porta e
colocá-lo na porta certa. Ele mantém uma tabela de qual número de placa mora em qual porta, e
consulta essa tabela.

O que ele **não** faz é abrir o quadro. Nunca olha o pacote de dentro. Não sabe nem se importa com
o destino final do pacote — para um comutador, um quadro é endereçado a uma máquina desta rede, e a
única pergunta é em qual porta essa máquina está.

Um **roteador** é o outro tipo de caixa, e faz o contrário. Ele desmonta o quadro, **joga fora**,
lê o pacote de dentro, decide por qual das próprias conexões o pacote deve sair, e constrói um
**quadro novo em folha** para esse próximo salto.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 246\" role=\"img\" aria-label=\"Dois painéis lado a lado. À esquerda um comutador passando um quadro de uma porta para outra, com o quadro inalterado e o pacote de dentro intocado. À direita um roteador desembrulhando o quadro, lendo o pacote e construindo um quadro novo.\"><rect x=\"8\" y=\"14\" width=\"340\" height=\"218\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"178\" y=\"38\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Um comutador</text><text x=\"178\" y=\"56\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">mesmo quadro, outra porta</text><rect x=\"26\" y=\"88\" width=\"128\" height=\"40\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".14\" stroke=\"var(--amber)\"></rect><text x=\"90\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">quadro</text><rect x=\"38\" y=\"108\" width=\"104\" height=\"16\" rx=\"1\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect><text x=\"90\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">pacote</text><rect x=\"202\" y=\"88\" width=\"128\" height=\"40\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".14\" stroke=\"var(--amber)\"></rect><text x=\"266\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o mesmo quadro</text><rect x=\"214\" y=\"108\" width=\"104\" height=\"16\" rx=\"1\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect><text x=\"266\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">intocado</text><path d=\"M156 108 L198 108\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"178\" y=\"162\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">nunca o abre</text><text x=\"178\" y=\"184\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">nunca vê o destino</text><text x=\"178\" y=\"212\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o quadro NÃO para aqui</text><rect x=\"372\" y=\"14\" width=\"340\" height=\"218\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"542\" y=\"38\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Um roteador</text><text x=\"542\" y=\"56\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">quadro novo, mesmo pacote</text><rect x=\"390\" y=\"88\" width=\"128\" height=\"40\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".14\" stroke=\"var(--amber)\" stroke-dasharray=\"3 3\"></rect><text x=\"454\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">quadro descartado</text><rect x=\"402\" y=\"108\" width=\"104\" height=\"16\" rx=\"1\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect><text x=\"454\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">pacote lido</text><rect x=\"566\" y=\"88\" width=\"128\" height=\"40\" rx=\"2\" fill=\"var(--phosphor-dim)\" fill-opacity=\".2\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"630\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">quadro NOVO</text><rect x=\"578\" y=\"108\" width=\"104\" height=\"16\" rx=\"1\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect><text x=\"630\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">mesmo pacote</text><path d=\"M520 108 L562 108\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"542\" y=\"162\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">abre, toda vez</text><text x=\"542\" y=\"184\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">lê o destino, e então decide</text><text x=\"542\" y=\"212\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o quadro para AQUI</text></svg>", "caption": "As duas caixas, e a diferença que importa: um comutador move um quadro, um roteador substitui um."}
```

Então a resposta para *onde um quadro para* é precisa: **um quadro para no primeiro roteador.** Ele
passa por quantos comutadores forem necessários no caminho — eles não são paradas, são corredores —
e termina no instante em que encontra algo que precise ler o pacote de dentro.

## Por que duas camadas em vez de uma

Uma pergunta justa a esta altura: por que não ter um envelope só? Por que não colocar o endereço
mundial na coisa que o cabo carrega e acabou?

Porque o cabo e o mundo são problemas diferentes, e mudam em ritmos diferentes.

A parte mundial tem que funcionar igual em todo lugar: o mesmo pacote precisa fazer sentido para
uma máquina em outro país, num equipamento comprado de outro fabricante, vinte anos depois.

A parte do cabo tem que ser o que **este meio específico** precisar. A Ethernet tem um jeito de
colocar bits no cobre e detectar uma colisão. O Wi-Fi tem um problema completamente diferente — um
espaço de rádio compartilhado, interferência, um aparelho que se move — e o resolve com
confirmações e retentativas de que a Ethernet nunca precisou.

Separar as duas significa que cada uma pode mudar sem tocar na outra. O Wi-Fi foi inventado, passou
por cinco gerações e virou a maneira como a maioria das pessoas se conecta — e **nenhum cabeçalho
de pacote precisou mudar**. O quadro do seu notebook saindo por rádio não se parece em nada com o
quadro do seu roteador saindo por fibra, e o pacote que os dois carregam é idêntico byte a byte.

Esse embrulho — uma coisa que significa algo, dentro de uma coisa que pode ser entregue — é um
padrão, não um caso isolado. Acontece mais de duas vezes, e a pilha inteira dele é *Redes em
camadas*, a aula 5. Aqui você está vendo uma instância real disso; lá vira o princípio.

## O que um quadro acrescenta no fim

Uma coisinha no rabo de um quadro vale ser nomeada, porque explica uma palavra que você vai
encontrar na próxima aula.

Um quadro carrega uma **soma de verificação** — um número calculado a partir do conteúdo, escrito
no fim pelo remetente e recalculado por quem recebe. Se os dois discordarem, alguma coisa foi
corrompida no caminho: um conector ruim, interferência, um cabo falhando.

O que acontece então é a parte interessante. Quem recebe **joga o quadro fora e não diz nada**. Não
há reclamação de volta, nem pedido de reenvio, nem registro que alguém vá ler. O quadro simplesmente
deixa de existir, e o pacote de dentro foi junto.

O que significa que corrupção num fio chega às duas máquinas das pontas com a aparência exata de um
roteador descartando um pacote numa fila cheia: alguma coisa foi enviada, e nada veio. A promessa da
rede continua sendo apenas melhor esforço, e agora você viu duas maneiras diferentes de ela
silenciosamente não cumpri-la.

## Onde isto te deixa

Um pacote atravessa a viagem inteira. Um quadro atravessa um salto, e é construído e destruído em
cada ponta dele. Comutadores movem quadros sem abri-los; roteadores abrem, leem o pacote e
constroem um quadro novo para o passo seguinte.

O que levanta a pergunta que esta seção cuidadosamente não respondeu: quando um roteador lê o
destino do pacote, **como ele decide para onde mandar em seguida?** É a próxima seção, e é a peça
que transforma um monte de máquinas independentes em algo que um pacote consegue atravessar.
