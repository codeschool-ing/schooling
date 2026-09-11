---
title: Atravessar uma rede à qual você não pertence
version: 1
---

Um roteador tem um pacote nas mãos. O pacote diz que está indo para `203.0.113.7`. O roteador não é
`203.0.113.7`, e não faz ideia de onde isso fica.

O que acontece em seguida é o maquinário que transforma alguns milhões de máquinas independentes em
algo que um pacote consegue atravessar, e é bem mais simples do que o resultado sugere.

## Ninguém sabe o caminho

Comece descartando a suposição natural. Não há mapa. Nenhuma máquina em lugar nenhum guarda uma
rota do seu notebook até o servidor, e nada consulta uma.

Cada roteador sabe uma coisa só: **para um pacote indo mais ou menos para lá, a próxima máquina a
quem entregar é esta.** Não o caminho. O próximo passo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Uma fila de cinco máquinas. Acima de cada roteador, um balão dizendo apenas a qual vizinho ele passaria o pacote em seguida. Nenhuma máquina enuncia o caminho inteiro.\"><rect x=\"10\" y=\"96\" width=\"96\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"58\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">você</text><rect x=\"158\" y=\"96\" width=\"96\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"206\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">roteador A</text><rect x=\"306\" y=\"96\" width=\"96\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"354\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">roteador B</text><rect x=\"454\" y=\"96\" width=\"96\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"502\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">roteador C</text><rect x=\"602\" y=\"96\" width=\"106\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"655\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o servidor</text><path d=\"M106 118 L154 118\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M254 118 L302 118\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M402 118 L450 118\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M550 118 L598 118\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\"></path><rect x=\"148\" y=\"36\" width=\"116\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".1\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"206\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">não é meu.</text><text x=\"206\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">passa para o B</text><rect x=\"296\" y=\"36\" width=\"116\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".1\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"354\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">não é meu.</text><text x=\"354\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">passa para o C</text><rect x=\"444\" y=\"36\" width=\"116\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".1\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"502\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">essa faixa está</text><text x=\"502\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">no meu próprio fio</text><path d=\"M206 74 L206 92\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" stroke-dasharray=\"2 2\" fill=\"none\"></path><path d=\"M354 74 L354 92\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" stroke-dasharray=\"2 2\" fill=\"none\"></path><path d=\"M502 74 L502 92\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" stroke-dasharray=\"2 2\" fill=\"none\"></path><text x=\"360\" y=\"176\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">nenhuma máquina aqui sabe a rota — cada uma sabe um passo</text><text x=\"360\" y=\"196\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o caminho é o que acontece, não o que foi planejado</text></svg>", "caption": "Uma dúzia de decisões locais, tomadas de forma independente, somam uma viagem que ninguém projetou."}
```

O caminho é um **resultado**, não um plano. É o que aconteceu quando uma série de máquinas
respondeu, cada uma por vez, à mesma perguntinha. Ninguém o escolheu e ninguém o está segurando.

## A tabela, que é uma lista curta de faixas

A coisa que um roteador consulta é uma **tabela de rotas**, e o formato dela é o que importa.

Não é uma lista de máquinas — há bilhões, e nenhuma tabela caberia. É uma lista de **faixas de
endereços**, cada uma emparelhada com um vizinho a quem entregá-las.

| para endereços em | entregue o pacote a |
|---|---|
| `203.0.113.0` – `203.0.113.255` | o fio plugado na porta 3 |
| `203.0.0.0` – `203.255.255.255` | roteador C |
| `10.0.0.0` – `10.255.255.255` | roteador A |
| **todo o resto** | o gateway padrão |

Cada linha cobre um bloco inteiro de endereços de uma vez. É isso que mantém a tabela pequena o
bastante para caber: um roteador perto do meio da internet guarda algumas centenas de milhares de
linhas, não alguns bilhões, porque cada linha representa uma faixa enorme.

Quando um pacote chega, o roteador vê quais linhas cobrem o destino — e quando mais de uma cobre,
**a mais específica vence.** Na tabela acima, um pacote para `203.0.113.7` casa com a primeira e com
a segunda linha. A primeira cobre 256 endereços e a segunda cobre dezesseis milhões, então a
primeira é a resposta: sai pela porta 3, no próprio fio deste roteador.

Essa regra é o que permite a uma exceção pequena e precisa ficar acima de um padrão enorme e vago
sem que ninguém precise reordenar nada.

## A última linha, e a que existe na sua própria máquina

A linha final daquela tabela é a interessante. **Todo o resto → entregue ao gateway padrão.**

É a admissão de ignorância, e é o que faz o esquema inteiro funcionar. Um roteador não precisa
conhecer a maior parte da internet. Precisa conhecer o que está perto dele, e precisa conhecer um
vizinho a quem entregar todo o resto — um vizinho que, em geral, está mais perto do meio e sabe
mais.

**A sua própria máquina também tem uma tabela de rotas**, e é bem curta. Se você já olhou as
configurações de rede e viu um campo chamado *gateway padrão*, era isto: o endereço do roteador a
quem entregar tudo que não estiver na sua própria rede.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 226\" role=\"img\" aria-label=\"Um notebook com uma tabela de rotas de duas linhas. A primeira cobre a rede local e aponta para o fio local. A segunda cobre todo o resto e aponta para o gateway padrão, desenhado como uma seta saindo rumo ao resto da internet.\"><rect x=\"12\" y=\"58\" width=\"120\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"72\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">seu notebook</text><text x=\"72\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">192.168.1.24</text><rect x=\"162\" y=\"30\" width=\"360\" height=\"52\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".09\" stroke=\"var(--phosphor)\"></rect><text x=\"180\" y=\"50\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">192.168.1.0 – 192.168.1.255</text><text x=\"180\" y=\"68\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">no meu próprio fio — mande o quadro direto</text><rect x=\"162\" y=\"98\" width=\"360\" height=\"52\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".09\" stroke=\"var(--amber)\"></rect><text x=\"180\" y=\"118\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">todo o resto</text><text x=\"180\" y=\"136\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">entregue a 192.168.1.1 — o gateway padrão</text><path d=\"M132 74 L158 60\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M132 104 L158 122\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"552\" y=\"88\" width=\"156\" height=\"72\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"630\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">seu roteador de casa</text><text x=\"630\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">ele também tem um padrão</text><text x=\"630\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">e o padrão dele também tem</text><path d=\"M522 124 L548 124\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"360\" y=\"196\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">duas linhas bastam, porque a segunda é problema de outro</text><text x=\"360\" y=\"216\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">este é o campo que as configurações de rede chamam de \"gateway padrão\"</text></svg>", "caption": "Quase toda máquina da internet roteia com duas linhas: o que está do meu lado, e outra pessoa."}
```

Siga a cadeia de padrões para cima e o quadro se completa sozinho. O seu notebook entrega o que não
é local ao roteador de casa. O roteador de casa entrega o que não reconhece ao seu provedor. O
provedor entrega o que não reconhece mais adiante. Em algum ponto perto do meio há roteadores sem
padrão nenhum — deles se espera que saibam, e são eles que carregam aquelas centenas de milhares de
linhas.

## O contador que impede um laço

Decisões independentes têm um risco óbvio. Se o roteador A acredita que o caminho é o B, e o B
acredita que é o A, um pacote fica quicando entre os dois para sempre, e todo pacote seguinte
também. O enlace enche de tráfego que não vai a lugar nenhum.

A defesa é um único campo no cabeçalho do pacote, e é bruta: um **contador que começa em torno de
64 e é reduzido em um a cada roteador**. Quando chega a zero, o pacote é jogado fora.

É só isso. Ninguém detecta o laço, ninguém o conserta, ninguém é avisado — um pacote mal direcionado
simplesmente tem um número limitado de chances e então deixa de existir. O campo se chama *tempo de
vida*, o que engana: ele conta saltos, não segundos.

## Por que o traceroute é do jeito que é

Você vai encontrar o `traceroute` na próxima aula, imprimindo uma lista numerada das máquinas entre
você e algum lugar. Vale saber desde já que ele é um **truque construído sobre aquele contador**,
porque isso explica tanto o que a ferramenta mostra quanto o que ela não consegue mostrar.

Quando um roteador reduz o contador a zero e descarta o pacote, ele normalmente manda uma mensagem
curta de volta: *joguei isto fora, e aqui está quem eu sou.*

Então: mande um pacote com o contador em 1. O primeiro roteador o reduz a zero, descarta e se
identifica. Mande outro com 2. O segundo roteador faz o mesmo. Continue, e as respostas vão
nomeando as máquinas do caminho, um salto por vez.

O que explica duas coisas que as pessoas acham estranhas na saída. A lista é montada a partir de uma
dúzia de sondas separadas, então uma linha posterior pode nomear uma máquina de um **caminho
diferente** de uma linha anterior — nada garante que todas tomaram a mesma rota. E algumas linhas
não mostram nada: um roteador tem o direito de não mandar aquela mensagem, e muitos não mandam.

## O que não está sendo dito aqui

A tabela é o mecanismo; **como as linhas entram nela é outro assunto**, e um assunto grande.

Dentro de uma organização, os roteadores anunciam uns aos outros o que conseguem alcançar, e a
tabela se monta sozinha. Entre organizações — entre o seu provedor e um provedor de outro país — há
um sistema separado pelo qual cada uma anuncia as faixas de endereços para as quais aceita tráfego,
e esses anúncios se propagam pelo mundo inteiro.

Esses sistemas têm nomes, e são um curso inteiro: `networks-addressing` é onde eles moram. O que
você precisa aqui é do que o pacote vivencia, e o que o pacote vivencia é uma tabela.

## Onde isto te deixa

Um pacote atravessa o mundo sendo entregue adiante, um roteador por vez, cada um escolhendo o
próximo passo numa lista de faixas de endereços — a linha mais específica primeiro, com um padrão no
fim para tudo que for desconhecido. Nenhuma máquina guarda a rota, um contador interrompe o pacote
se as decisões discordarem, e o caminho que você vê num diagnóstico é uma reconstrução, não um
registro.

Há uma coisa que um roteador pode fazer e que esta seção pulou: o que acontece quando o pacote é
**grande demais para o próximo cabo**. É a próxima seção, e é a origem de uma família de falhas que
não se parece com nenhuma outra.
