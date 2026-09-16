---
title: Host, nó, endpoint
version: 1
---

A seção anterior era sobre *papéis*. Esta é sobre as *coisas* que os desempenham, e sobre três
palavras usadas para essas coisas quase como sinônimos — mas não exatamente.

Acertar essas três vale o esforço por um motivo prático: quando alguma coisa quebra, a primeira
pergunta útil é sempre **qual das três quebrou**, e você não consegue fazê-la sem as palavras.

## Host

Um **host** é uma máquina numa rede que pode ser alcançada: ela tem um endereço, e alguma coisa
nela está pronta para conversar.

A palavra é mais velha que a web e significa o que parece significar. Um host é uma máquina que
hospeda — que guarda coisas e recebe visitantes. Seu notebook é um host. Um celular no 4G é um
host. Uma máquina alugada num data center é um host. Uma impressora com um cabo de rede nela é um
host.

O que faz de algo um host é **ser endereçável**, não ser importante.

Um host não precisa ser um computador físico inteiro, e cada vez menos é. Uma máquina física pode
rodar vinte virtuais, cada uma com seu endereço, cada uma um host por direito próprio e sem saber
das outras. De fora não há como distinguir, e não há motivo para se importar — que é justamente o
objetivo do arranjo.

## Nó

Um **nó** é qualquer coisa na rede, incluindo o maquinário que só move o tráfego adiante —
roteadores, switches, as caixas entre você e todo o resto.

Então todo host é um nó, e muitos nós não são hosts. O roteador da sua casa é um nó: ele está bem
dentro da rede, mas você não o visita, ele não guarda seus arquivos, e existe para passar pacotes
de um lado para o outro.

Quando alguém diz nó, normalmente está pensando no **formato da rede** — o diagrama, o caminho, os
saltos entre aqui e lá. Quando alguém diz host, normalmente está pensando em **uma máquina com que
dá para conversar**. O mesmo equipamento, outra pergunta sendo feita sobre ele.

## Endpoint

Um **endpoint** é um lugar específico para onde você pode mandar uma requisição e de onde recebe
uma resposta.

Este é o mais estreito dos três, e a diferença importa: um host é uma máquina, mas uma máquina
roda muitas coisas ao mesmo tempo. Um host só pode ser:

- um servidor web, respondendo requisições de página;
- um servidor de e-mail, aceitando mensagens;
- um servidor SSH, aceitando logins.

Três endpoints, um host. Cada um é um destino diferente mesmo compartilhando um endereço.

### O que os separa é a porta

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 226\" role=\"img\" aria-label=\"Um retângulo grande é um host com um endereço. Dentro dele, três caixas menores são endpoints, nas portas 443, 22 e 25. Uma seta chega de fora endereçada ao endereço seguido de dois-pontos 443, e alcança apenas a primeira caixa.\"><defs>\n<marker id=\"ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker>\n<marker id=\"ahs\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker>\n<marker id=\"ahv\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor-dim)\"></path></marker>\n<marker id=\"ahn\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker>\n</defs>\n  <rect x=\"196\" y=\"30\" width=\"510\" height=\"150\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect>\n  <text x=\"212\" y=\"50\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"700\" fill=\"var(--paper-dim)\">UM HOST</text>\n  <text x=\"212\" y=\"66\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">203.0.113.7</text>\n\n  <rect x=\"216\" y=\"84\" width=\"150\" height=\"74\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"291.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">servidor web</text><text x=\"291.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">:443</text>\n  <rect x=\"382\" y=\"84\" width=\"150\" height=\"74\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"457.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">SSH</text><text x=\"457.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">:22</text>\n  <rect x=\"548\" y=\"84\" width=\"142\" height=\"74\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"619.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">e-mail</text><text x=\"619.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">:25</text>\n\n  <path d=\"M20 121 L210 121\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\" fill=\"none\" marker-end=\"url(#ahs)\"></path>\n  <text x=\"20\" y=\"112\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">203.0.113.7:443</text>\n  <text x=\"20\" y=\"142\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">uma requisição</text>\n  <text x=\"196\" y=\"206\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Três endpoints. Um host. Um endereço. Quem escolheu foi o número.</text>\n</svg>", "caption": "O endereço encontra a máquina. A porta encontra o programa. Os outros dois estão escutando o tempo todo e não eram o destino da requisição."}
```

Um endereço leva uma requisição até a **máquina** certa. Uma **porta** — um número que viaja junto
do endereço — leva a requisição até o **programa certo naquela máquina**.

A convenção é que certos números significam certos serviços, para que um cliente saiba onde bater
sem precisar ser avisado:

| porta | o que costuma esperar ali |
|---|---|
| 80 | um servidor web, sem criptografia |
| 443 | um servidor web, criptografado — o que quase tudo usa hoje |
| 22 | SSH, para entrar na própria máquina |
| 25 | e-mail sendo passado entre servidores |
| 5432 | um banco de dados PostgreSQL |

São convenções, não leis. Um servidor web pode escutar na 8080, ou na 3000, ou na 61234 — que é
exatamente o que acontece quando você roda alguma coisa localmente e abre `localhost:3000`. O
número depois dos dois-pontos *é* a porta, e você o está digitando porque o seu servidor de
desenvolvimento não pegou a convencional.

Você vai conhecer portas de verdade na próxima aula, junto com sockets. Por ora a ideia útil é
esta: **"a máquina" e "a coisa na máquina que responde" não são o mesmo objeto**, e quase toda
falha confusa mora na distância entre os dois.

## Um host, muitos nomes — e muitos hosts, um nome

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" aria-label=\"Dois painéis. À esquerda, três nomes de domínio diferentes apontam para um único endereço que abriga um servidor web. À direita, um único nome aponta para três endereços em cidades diferentes, e o escolhido depende de onde está quem pergunta.\"><defs>\n<marker id=\"ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker>\n<marker id=\"ahs\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker>\n<marker id=\"ahv\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor-dim)\"></path></marker>\n<marker id=\"ahn\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker>\n</defs>\n  <text x=\"14\" y=\"18\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"700\" fill=\"var(--paper-dim)\">MUITOS NOMES → UM HOST</text>\n  <line x1=\"348\" y1=\"8\" x2=\"348\" y2=\"240\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 4\"></line>\n  <text x=\"368\" y=\"18\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"700\" fill=\"var(--paper-dim)\">UM NOME → MUITOS HOSTS</text>\n\n  <rect x=\"14\" y=\"42\" width=\"122\" height=\"26\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect>\n  <text x=\"75\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">loja.exemplo</text>\n  <rect x=\"14\" y=\"86\" width=\"122\" height=\"26\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect>\n  <text x=\"75\" y=\"99\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">blog.exemplo</text>\n  <rect x=\"14\" y=\"130\" width=\"122\" height=\"26\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect>\n  <text x=\"75\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">api.exemplo</text>\n\n  <path d=\"M136 55 L204 96\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah)\"></path>\n  <path d=\"M136 99 L204 101\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah)\"></path>\n  <path d=\"M136 143 L204 106\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah)\"></path>\n\n  <rect x=\"210\" y=\"76\" width=\"118\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"269.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">um host</text><text x=\"269.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">203.0.113.9</text>\n  <text x=\"269\" y=\"150\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o servidor web lê</text>\n  <text x=\"269\" y=\"165\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">qual nome você pediu</text>\n\n  <rect x=\"368\" y=\"76\" width=\"118\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"427.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">um nome</text><text x=\"427.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">cdn.exemplo</text>\n\n  <path d=\"M486 90 L546 58\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah)\"></path>\n  <path d=\"M486 102 L546 102\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\" marker-end=\"url(#ahs)\"></path>\n  <path d=\"M486 114 L546 146\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah)\"></path>\n\n  <rect x=\"554\" y=\"44\" width=\"152\" height=\"28\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect>\n  <text x=\"630\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">198.51.100.4 · Paris</text>\n  <rect x=\"554\" y=\"88\" width=\"152\" height=\"28\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".13\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect>\n  <text x=\"630\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">203.0.113.7 · S. Paulo</text>\n  <rect x=\"554\" y=\"132\" width=\"152\" height=\"28\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect>\n  <text x=\"630\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">192.0.2.31 · Tóquio</text>\n\n  <text x=\"630\" y=\"182\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">você recebe o mais perto de você</text>\n  <text x=\"360\" y=\"230\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">o nome é um rótulo que alguém resolve — o endereço é para onde os pacotes vão</text>\n</svg>", "caption": "As duas direções existem, e são a mesma pergunta feita de trás para frente. Um nome não é um endereço: é um rótulo que alguém resolve, e a resposta pode mudar conforme o visitante."}
```

Dois arranjos que surpreendem as pessoas, e os dois são comuns:

**Um host pode atender por muitos nomes.** Uma única máquina num único endereço rotineiramente
serve centenas de sites diferentes. A requisição carrega o nome que o cliente pediu, o servidor lê
esse nome, e responde com o site certo. Nada no endereço ou na porta os distingue — só o nome
dentro da requisição. É por isso que hospedagem barata é barata.

**Um nome pode apontar para muitos hosts.** O nome de um site grande resolve para máquinas
diferentes conforme a pessoa, escolhidas por onde ela está ou por quais máquinas estão saudáveis
naquele momento. "O servidor" de um site desses não é uma máquina: é um conjunto delas que muda.

Então "qual host me respondeu?" é uma pergunta real com uma resposta real, e nem sempre é a
resposta que você adivinharia pela barra de endereços. A aula 8 cobre o maquinário que faz as duas
coisas funcionarem.

## Por que a distinção se paga

```schooling-figure
{"svg": "<svg viewBox=\"0 0 744 282\" role=\"img\" aria-label=\"Três tentativas desenhadas uma acima da outra. A primeira é uma seta tracejada que não alcança nada e termina num círculo cruzado. A segunda é uma seta de ida e uma seta de volta imediata. A terceira é uma troca completa cuja resposta carrega uma caixa marcada como erro.\"><defs>\n<marker id=\"ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker>\n<marker id=\"ahs\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker>\n<marker id=\"ahv\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor-dim)\"></path></marker>\n<marker id=\"ahn\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker>\n</defs>\n  <text x=\"14\" y=\"24\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"700\" letter-spacing=\"1.2\" fill=\"var(--paper-dim)\">O QUE VOLTA</text>\n\n  <text x=\"14\" y=\"60\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">host inacessível</text>\n  <path d=\"M196 54 L520 54\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"5 4\"></path>\n  <circle cx=\"536\" cy=\"54\" r=\"10\" fill=\"var(--amber)\" fill-opacity=\".13\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle>\n  <path d=\"M531 49 L541 59 M541 49 L531 59\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></path>\n  <text x=\"558\" y=\"58\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">nada volta · timeout</text>\n\n  <text x=\"14\" y=\"140\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">nada escutando</text>\n  <path d=\"M196 128 L300 128\" stroke=\"var(--paper)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#ah)\"></path>\n  <path d=\"M300 150 L199 150\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#ahv)\"></path>\n  <text x=\"316\" y=\"145\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">recusado, na hora · o host está vivo</text>\n\n  <text x=\"14\" y=\"222\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">os dois bem</text>\n  <path d=\"M196 210 L520 210\" stroke=\"var(--paper)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#ah)\"></path>\n  <path d=\"M520 232 L392 232 M326 232 L199 232\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#ahs)\"></path>\n  <rect x=\"330\" y=\"220\" width=\"58\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect>\n  <text x=\"359\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">erro</text>\n  <text x=\"540\" y=\"228\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a troca funcionou</text>\n  <text x=\"14\" y=\"270\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Nada está “fora do ar” no terceiro. Alguma coisa está errada.</text>\n</svg>", "caption": "Três falhas que a mesma frase esconde. Um timeout é não ter ninguém para dizer não; uma recusa é alguém dizendo, e é a mais saudável das três; um erro respondido é a troca inteira funcionando e o conteúdo estando errado."}
```

Porque "o servidor caiu" são três problemas diferentes, consertados por pessoas diferentes, e
**eles são diferentes vistos de fora**:

| o que está errado | o que você vê |
|---|---|
| o **host** está inacessível — desligado, ou a rede até ele está quebrada | a tentativa fica pendurada e desiste: um timeout |
| o host está bem, o **endpoint** não — nada está escutando naquela porta | uma recusa imediata e definitiva |
| os dois estão bem e a **resposta é um erro** | uma resposta rápida e bem formada dizendo que deu errado |

A diferença entre os dois primeiros vale ser internalizada. **Um timeout significa que não havia
ninguém lá para dizer não.** Sua requisição saiu e nada voltou — a máquina
está desligada, ou algo entre você e ela está descartando tráfego em silêncio.

**Uma recusa significa que havia alguém lá e ele disse não.** A máquina está de pé, a rede chegou
até ela, e o sistema operacional dela respondeu "não há nada escutando nessa porta". Essa é uma
falha *mais saudável* que um timeout, porque ela lhe diz que o host está vivo e reduz o problema
ao programa.

A terceira é diferente em espécie: a troca se completou perfeitamente e o conteúdo da resposta é
uma reclamação. Nada caiu. Alguma coisa está errada.

Boa parte de diagnosticar qualquer coisa é saber qual das três você está olhando. Na última aula
deste curso você vai fazer exatamente isso com ferramentas reais; o vocabulário de que você
precisa para distingui-las começa aqui.

## Uma observação sobre "a nuvem"

Nada disso muda quando a máquina é alugada em vez de comprada. Um servidor na nuvem é um host: ele
tem um endereço, roda programas que escutam em portas, e pode estar inacessível, ou acessível sem
nada escutando, ou respondendo com um erro.

O que alugar compra é que outra pessoa cuida da eletricidade, do hardware e do prédio, e que você
pode ter outro em noventa segundos. Não compra um modelo diferente de como as máquinas conversam,
e quem lhe disser que a nuvem é uma coisa fundamentalmente diferente está vendendo alguma coisa. A
aula 9 é sobre os formatos que dá para alugar e o que cada um realmente tira das suas costas.
