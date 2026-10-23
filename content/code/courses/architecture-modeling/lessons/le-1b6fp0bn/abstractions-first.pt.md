---
title: Primeiro as abstrações, depois a notação
version: 1
---

**O modelo C4 é um pequeno conjunto de abstrações para descrever software, e um conjunto de
diagramas que as mostram em quatro níveis de detalhe.** Simon Brown o desenvolveu a partir das
aulas que dava no fim dos anos 2000, e o publicou com esse nome por volta de 2011. A premissa é que
a maioria dos diagramas de arquitetura falha não porque as formas estão erradas, mas porque ninguém
combinou o que as caixas são.

Por isso o C4 começa pelo vocabulário, e só depois vai para os desenhos.

## Cinco palavras

| | o que é | exemplo na Carcará |
| --- | --- | --- |
| **pessoa** | um usuário humano do sistema, num papel | um passageiro, um agente de guichê, um motorista |
| **sistema de software** | o nível mais alto de abstração: algo que entrega valor aos seus usuários, em geral de um único time ou organização | a *venda de passagens Carcará*; o gateway da empresa de pagamentos; a *Frota*, o sistema de frota |
| **container** | uma aplicação ou um armazenamento de dados que precisa estar rodando para o sistema funcionar | o app web do passageiro, a API de passagens, o banco de reservas |
| **componente** | um agrupamento de funcionalidades relacionadas atrás de uma interface, dentro de um container | o serviço de reservas dentro da API de passagens |
| **código** | as classes, funções e tabelas que implementam um componente | `Booking`, `BookingRepository` |

As palavras se encaixam umas nas outras. **Um sistema de software é feito de containers; um
container é feito de componentes; um componente é implementado por código.** É esse encaixe que dá
aos quatro diagramas os seus níveis de zoom: cada diagrama pega uma caixa do nível de cima e a
abre.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" data-fig=\"l03-zoom\" aria-label=\"Os quatro níveis do C4 como zooms sucessivos. Nível 1, contexto do sistema: uma caixa para a venda de passagens da Carcará entre pessoas e outros sistemas. Nível 2, containers: a caixa se abre em apps, uma API e repositórios de dados. Nível 3, componentes: um container, a API de passagens, se abre nas suas partes principais. Nível 4, código: um componente se abre em classes. Cada nível pega uma caixa do nível de cima e mostra o que tem dentro.\"><defs><marker id=\"l03-zoom-am-fill-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" markerUnits=\"userSpaceOnUse\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"14.0\" y=\"30.0\" width=\"160.0\" height=\"140.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"94.0\" y=\"16.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">1 · Contexto</text><text x=\"94.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">para todo mundo</text><rect x=\"64.0\" y=\"85.0\" width=\"60.0\" height=\"30.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><rect x=\"20.0\" y=\"46.0\" width=\"28.0\" height=\"18.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><path d=\"M46.0 62.0 L64.0 90.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"140.0\" y=\"46.0\" width=\"28.0\" height=\"18.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><path d=\"M142.0 62.0 L124.0 90.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"20.0\" y=\"136.0\" width=\"28.0\" height=\"18.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><path d=\"M46.0 138.0 L64.0 110.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"140.0\" y=\"136.0\" width=\"28.0\" height=\"18.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><path d=\"M142.0 138.0 L124.0 110.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M176.0 100.0 L190.0 100.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l03-zoom-am-fill-amber)\"></path><rect x=\"192.0\" y=\"30.0\" width=\"160.0\" height=\"140.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"272.0\" y=\"16.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">2 · Containers</text><text x=\"272.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">para gente técnica</text><rect x=\"206.0\" y=\"40.0\" width=\"132.0\" height=\"120.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><rect x=\"218.0\" y=\"54.0\" width=\"44.0\" height=\"22.0\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"282.0\" y=\"54.0\" width=\"44.0\" height=\"22.0\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"250.0\" y=\"89.0\" width=\"44.0\" height=\"22.0\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"218.0\" y=\"124.0\" width=\"44.0\" height=\"22.0\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"282.0\" y=\"124.0\" width=\"44.0\" height=\"22.0\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"247.0\" y=\"86.0\" width=\"50.0\" height=\"28.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><rect x=\"250.0\" y=\"89.0\" width=\"44.0\" height=\"22.0\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><path d=\"M354.0 100.0 L368.0 100.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l03-zoom-am-fill-amber)\"></path><rect x=\"370.0\" y=\"30.0\" width=\"160.0\" height=\"140.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"16.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">3 · Componentes</text><text x=\"450.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">para o time do container</text><rect x=\"384.0\" y=\"40.0\" width=\"132.0\" height=\"120.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><rect x=\"398.0\" y=\"52.0\" width=\"44.0\" height=\"20.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"458.0\" y=\"52.0\" width=\"44.0\" height=\"20.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"398.0\" y=\"90.0\" width=\"44.0\" height=\"20.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"458.0\" y=\"90.0\" width=\"44.0\" height=\"20.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"428.0\" y=\"128.0\" width=\"44.0\" height=\"20.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><path d=\"M532.0 100.0 L546.0 100.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l03-zoom-am-fill-amber)\"></path><rect x=\"548.0\" y=\"30.0\" width=\"160.0\" height=\"140.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"628.0\" y=\"16.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">4 · Código</text><text x=\"628.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">raramente desenhado</text><rect x=\"562.0\" y=\"40.0\" width=\"132.0\" height=\"120.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><rect x=\"570.0\" y=\"52.0\" width=\"52.0\" height=\"36.0\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\"></rect><path d=\"M570.0 64.0 L622.0 64.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"634.0\" y=\"52.0\" width=\"52.0\" height=\"36.0\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\"></rect><path d=\"M634.0 64.0 L686.0 64.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"602.0\" y=\"112.0\" width=\"52.0\" height=\"36.0\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\"></rect><path d=\"M602.0 124.0 L654.0 124.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path></svg>", "caption": "Cada diagrama abre uma caixa do diagrama anterior. O público se estreita à medida que o detalhe cresce.", "same": ["2 · Containers"]}
```

## Independente de notação

O C4 não prescreve formas nem cores. Um container pode ser um retângulo, um cilindro para um banco
de dados ou o contorno de um celular para um app móvel. O que ele prescreve é que **todo elemento
traga o seu nome, o seu tipo, a sua tecnologia quando tiver uma, e uma descrição curta**, e que
**toda relação traga um rótulo dizendo o que ela faz e, quando for útil, a tecnologia que usa**. O
teste de leitura da aula 1 pedia as mesmas coisas; o C4 faz delas a regra e não a exceção.

Por causa disso, um diagrama C4 precisa de legenda como qualquer outro. A convenção comum, usada
nesta aula, é uma caixa arredondada com uma cabeça para uma pessoa, caixas de uma cor para os
elementos dentro do sistema descrito, e cinza para tudo o que está fora dele.

## Por que pegou

Duas razões explicam por que o C4 virou a resposta padrão para *como devemos desenhar a nossa
arquitetura?* em muitos times que tinham desistido da UML:

- **Ele bate com o jeito como engenheiros já falam.** "O app chama a API, que grava no banco" é um
  diagrama de containers em palavras. Ninguém precisa aprender o que é um nó ou um ambiente de
  execução.
- **Ele separa os públicos.** O diagrama de contexto é para qualquer pessoa, o de containers para
  gente técnica, o de componentes para o time dono de um container. A aula 14 se apoia nisso quando
  escolhe um desenho por público.

Ele pega emprestado sem cerimônia: um diagrama de componentes no C4 é parecido com um diagrama de
componentes da UML sem as bolas e os soquetes, e o nível de código, quando é desenhado, costuma ser
um diagrama de classes da UML. Aprender os dois não é duplicação. **O C4 decide o que desenhar em
cada nível; a UML diz com precisão como desenhar parte disso.**
