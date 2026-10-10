---
title: As linhas importam tanto quanto as caixas
version: 1
---

O jeito mais comum de descrever um sistema é listar as partes: a Carreto tem um app Shipper, um
serviço de Pricing, um serviço de Matching, e assim por diante. **Uma lista de partes não é uma
arquitetura.** As mesmas partes, ligadas de jeitos diferentes, são sistemas diferentes: falham de
outro modo, mudam de outro modo, e times diferentes precisam conversar para mantê-las funcionando. O
jeito como as partes se ligam tem nome na literatura, o *conector*, e merece tanta atenção quanto as
próprias partes.

## Três sistemas com as mesmas três caixas

Pegue um fluxo da Carreto. Um embarcador publica uma carga no app Shipper; o Pricing cota o frete; o
Matching começa a oferecer a carga aos motoristas. Três componentes, e pelo menos três jeitos de
ligá-los.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Três painéis com os mesmos três componentes: o Shipper app, o Pricing e o Matching. No primeiro o Shipper app chama os outros dois por HTTP; se o Pricing cai, nenhuma carga pode ser publicada. No segundo o Shipper app publica num broker que os dois consomem; se o Pricing cai, as mensagens esperam. No terceiro os três leem e escrevem a tabela loads num único banco PostgreSQL; uma consulta lenta de um deixa os outros lentos.\"><defs><marker id=\"wire-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"220\" height=\"310\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"120\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">chamadas síncronas</text><rect x=\"72\" y=\"60\" width=\"96\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"120\" y=\"77\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Shipper app</text><rect x=\"18\" y=\"170\" width=\"96\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"66\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Pricing</text><rect x=\"126\" y=\"170\" width=\"96\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"174\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Matching</text><path d=\"M100 94 L70 168\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#wire-ah)\"></path><path d=\"M140 94 L170 168\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#wire-ah)\"></path><text x=\"62\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">HTTP</text><text x=\"178\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">HTTP</text><text x=\"120\" y=\"262.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Pricing fora do ar: nenhum</text><text x=\"120\" y=\"277.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">embarcador publica carga</text><rect x=\"250\" y=\"10\" width=\"220\" height=\"310\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"360\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">por uma fila</text><rect x=\"312\" y=\"50\" width=\"96\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"67\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Shipper app</text><rect x=\"300\" y=\"118\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"133\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">broker</text><rect x=\"258\" y=\"180\" width=\"96\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"306\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Pricing</text><rect x=\"366\" y=\"180\" width=\"96\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"414\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Matching</text><path d=\"M360 84 L360 116\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#wire-ah)\"></path><path d=\"M340 148 L310 178\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#wire-ah)\"></path><path d=\"M380 148 L410 178\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#wire-ah)\"></path><text x=\"360\" y=\"262.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Pricing fora do ar: publica-se;</text><text x=\"360\" y=\"277.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a cotação espera na fila</text><rect x=\"490\" y=\"10\" width=\"220\" height=\"310\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"600\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">banco compartilhado</text><rect x=\"496\" y=\"60\" width=\"66\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"529\" y=\"74.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Shipper</text><text x=\"529\" y=\"87.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">app</text><rect x=\"567\" y=\"60\" width=\"66\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"600\" y=\"81.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Pricing</text><rect x=\"638\" y=\"60\" width=\"66\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"671\" y=\"81.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Matching</text><rect x=\"530\" y=\"170\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"600\" y=\"183\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">PostgreSQL</text><text x=\"600\" y=\"199\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">loads</text><path d=\"M529 102 L570 168\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M600 102 L600 168\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M671 102 L630 168\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><text x=\"600\" y=\"262.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">nenhuma seta entre as caixas;</text><text x=\"600\" y=\"277.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">uma consulta lenta trava os três</text></svg>", "caption": "Os mesmos três componentes, três arquiteturas. O que muda é o conector e, com ele, o que acontece quando uma parte falha e quem precisa concordar antes de os dados mudarem.", "same": ["Shipper app", "Pricing", "Matching", "broker"]}
```

**Ligados por chamadas síncronas.** O app Shipper chama o Pricing por HTTP, espera a cotação, depois
chama o Matching e espera de novo. É a versão mais fácil de ler e de depurar: uma requisição, um
trace, uma resposta. A fraqueza é que todas as partes precisam estar de pé ao mesmo tempo. Se cada
serviço está disponível 99,9% do tempo, os três juntos estão disponíveis cerca de 99,7% do tempo —
as probabilidades se multiplicam. Num mês de 30 dias, 99,9% permite cerca de 43 minutos fora do ar;
99,7% permite cerca de 130. E enquanto o Pricing está fora, **nenhum embarcador consegue publicar
carga alguma**, embora não haja nada de errado com a publicação.

**Ligados por uma fila.** O app Shipper grava a carga e publica uma mensagem "carga publicada" no
broker. O Pricing e o Matching a consomem, cada um no seu tempo. Agora o Pricing pode cair sem parar
os embarcadores: as mensagens esperam. Se o Pricing fica 20 minutos fora enquanto os embarcadores
publicam 30 cargas por minuto, há 600 mensagens esperando quando ele volta. O preço disso é pago em
outro lugar. O embarcador já não vê a cotação na mesma tela. Uma mensagem pode chegar duas vezes,
então cada consumidor precisa lidar com duplicatas. E alguém precisa vigiar a profundidade da fila,
porque uma fila que cresce em silêncio é uma queda que ainda não foi percebida.

**Ligados por um banco compartilhado.** Os três leem e escrevem as mesmas tabelas no PostgreSQL do
monólito. É a versão mais rápida de construir, e é como boa parte da Carreto funciona hoje. Nada num
diagrama mostra a dependência: não há setas entre as caixas, só uma linha de cada uma até o banco.
Mas uma consulta lenta do Matching segura travas que o app Shipper está esperando, e **mudar uma
coluna é mudar o código de três times**, e é por isso que uma migração da tabela `loads` precisa de
três tech leads na mesma reunião.

## O que um conector decide

As três versões diferem num punhado de propriedades, e essas propriedades são o que um arquiteto lê
num conector:

| | chamadas síncronas | fila | banco compartilhado |
|---|---|---|---|
| um embarcador publica uma carga com o Pricing fora do ar | falha | funciona; a cotação vem depois | funciona, a menos que as consultas do Pricing sejam o que está lento |
| quando o embarcador vê o preço | na mesma tela | alguns segundos depois, por uma notificação | na mesma tela |
| quem conhece quem | quem chama conhece todos os chamados | quem publica e quem consome só conhecem a mensagem | todos conhecem todas as tabelas |
| quanto custa mudar os dados | mudar uma API, com versões | mudar um formato de mensagem, com versões | uma migração a que todo leitor precisa sobreviver |
| o que vê quem está de plantão | um erro num trace | uma fila crescendo | um banco lento e nenhum culpado óbvio |

Nenhuma das três é a resposta certa. **Cada uma é uma decisão sobre qual falha a Carreto prefere
ter.** Uma cadeia síncrona é simples e frágil ao mesmo tempo. Uma fila mantém os embarcadores
publicando quando o Pricing falha, e cobra em duplicatas e numa cotação atrasada. Um banco
compartilhado é rápido e esconde o acoplamento até o dia em que alguém muda uma coluna. A mecânica
de cada um — timeouts e retries, garantias de entrega, consumidores idempotentes — foi assunto das
aulas 5, 6 e 7 de `architecture`, e este curso não a repete. O que muda aqui é que você olha a
escolha como arquitetural: ela é cara de desfazer e decide como três times trabalham juntos.

## A Carreto usa as três ao mesmo tempo

Sistemas reais misturam os conectores, e a Carreto não é exceção. Quando um embarcador publica uma
carga hoje, o app Shipper a envia ao monólito, que a grava na tabela `loads`. O monólito chama o
Pricing por HTTP e espera a cotação, então um Pricing lento deixa a publicação lenta. O Matching não
fica sabendo da carga por ninguém: ele lê as linhas novas da mesma tabela `loads` a cada poucos
segundos. O Tracking, o único time que saiu do monólito de forma limpa, publica as posições dos
caminhões no broker, e o Matching as consome para saber que motoristas estão perto de uma carga.

Então um fluxo comum atravessa uma chamada síncrona, uma tabela compartilhada e uma fila, e **cada
parte dele falha do seu jeito.** Quando o Pricing está lento, os embarcadores esperam na tela.
Quando o banco está lento, publicação e matching ficam lentos juntos e nenhum painel diz por quê.
Quando o broker cai, o Matching continua oferecendo cargas com posições que envelhecem a cada
minuto. Quem quer dizer como a Carreto se comporta sob falha precisa saber que conector está em cada
passo, e ninguém tinha registrado isso.

## A seta no diagrama

É também por isso que um desenho de caixas e setas tantas vezes diz menos do que parece. **Uma seta
sem rótulo pode ser qualquer um dos três conectores acima**, e quem lê completa com o que imaginar.
Uma pessoa lê "chama"; outra lê "envia um evento para"; uma terceira lê "compartilha dados com". As
três vão concordar que o desenho está certo.

Quando Renata desenha a Carreto pela primeira vez, ela escreve o tipo de cada linha ao lado dela:
*HTTP, espera resposta*; *evento pelo broker*; *lê a tabela `loads`*. O desenho fica mais difícil de
deixar bonito e muito mais útil. Ele também mostra algo que o slide antigo da integração não
mostrava, e é daí que parte a aula 2: **cinco serviços, além do próprio monólito, se conectam direto
ao banco do monólito**, e no slide nenhum deles se conectava.

## Elementos, relações e propriedades

Volte à definição do livro-texto na seção anterior: elementos, as relações entre eles e **as
propriedades de ambos**. Um conector tem propriedades próprias — síncrono ou não, o que garante
sobre a entrega, o que faz quando a outra ponta não está lá — e elas são tão parte da arquitetura
quanto as propriedades de um serviço. Um time pode reescrever o interior do Pricing num trimestre
sem que ninguém de fora perceba. Mudar o Pricing de chamada síncrona para consumidor de eventos muda
o app Shipper, as telas que os embarcadores usam, o monitoramento e o runbook do plantão. **Essa
diferença no custo da mudança é a razão de os conectores serem arquitetura.**
