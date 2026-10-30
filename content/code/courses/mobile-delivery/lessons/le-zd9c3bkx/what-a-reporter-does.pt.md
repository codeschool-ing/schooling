---
title: O que um coletor de crashes faz
version: 1
---

**Um crash num celular não deixa rastro que a equipe enxergue.** O app some e a pessoa o abre de
novo, ou não. O sistema operacional guarda os próprios logs de crash, e as duas lojas mostram parte
deles, o Android vitals da lição 8 e as contagens de crash do App Store Connect, mas com um dia ou
mais de atraso e só de quem aceitou compartilhar diagnósticos. Um **coletor de crashes** é uma
biblioteca dentro do app que avisa você ele mesmo, em minutos, com o contexto que o sistema não tem.

## A forma que todos eles têm

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l12-sequence\" aria-label=\"Duas aberturas do app numa linha do tempo. Na primeira, o coletor começa primeiro, o app guarda migalhas enquanto roda, e então quebra; o coletor grava o relatório no disco do celular e o app some. A pessoa abre o app de novo. Na segunda abertura, o coletor começa primeiro de novo, acha o relatório no disco e o manda ao servidor, que responde que o aceitou, e o relatório é apagado do disco.\"><defs><marker id=\"l12-sequence-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l12-sequence-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l12-sequence-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"300\" height=\"160\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"170\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">abertura 1</text><rect x=\"400\" y=\"20\" width=\"300\" height=\"160\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"550\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">abertura 2</text><text x=\"40\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">1  coletor começa</text><text x=\"40\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">2  migalhas guardadas</text><text x=\"40\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">3  crash</text><text x=\"40\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">4  relatório gravado no disco</text><text x=\"40\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5  o app some</text><text x=\"420\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">1  coletor começa</text><text x=\"420\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">2  relatório mandado</text><text x=\"420\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">3  aceito, apagado</text><path d=\"M320 100 L398 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l12-sequence-ah-paper-dim)\"></path><text x=\"359\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">aberto de novo</text><rect x=\"150\" y=\"220\" width=\"180\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"240.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o disco do celular</text><rect x=\"470\" y=\"220\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"550.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">servidor de crash</text><path d=\"M170 180 L210 218\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-sequence-ah-amber)\"></path><path d=\"M330 230 L468 230\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-sequence-ah-phosphor)\"></path></svg>", "caption": "O relatório atravessa o intervalo entre duas aberturas no disco. Nada é mandado no momento do crash, porque um processo quebrando é o último lugar em que confiar uma requisição de rede.", "same": ["3 crash"]}
```

1. **Ele começa primeiro**, antes de qualquer outro código do app, para que um crash durante a
   abertura também seja pego.
2. **Ele guarda migalhas** (breadcrumbs): uma lista curta do que o app estava fazendo, "abriu
   Estatísticas", "tocou em violão", guardada na memória e substituída conforme anda.
3. **Num crash, ele grava um relatório no disco, e mais nada.** Um processo quebrando pode ter a
   memória corrompida, a rede morta, segundos de vida. Gravar um arquivo é o máximo que se pode
   confiar que ele termine. Um crash nativo no iOS ou no Android é pego por um tratador de sinal, onde
   até alocar memória é inseguro, então os coletores gravam um buffer já reservado.
4. **Na abertura seguinte, ele manda o que está no disco**, e apaga cada relatório depois que o
   servidor o aceitou. Um relatório que não pôde ser mandado fica para a abertura depois dessa.

Então **o relatório de um crash chega quando a pessoa abre o app de novo**, e por isso um crash na
abertura, o que impede as pessoas de abrir o app, é o que tem mais chance de nunca chegar. Os
melhores coletores tentam mandar um crash de abertura na hora, de forma síncrona, por esse motivo.

## O que um relatório leva

O **erro**: o tipo, a mensagem e a pilha, a lista de funções que estavam rodando. O **build**: nome
da versão e número, lição 9, para casar o relatório com o código. O **aparelho**: modelo, versão do
sistema, memória livre, orientação. As **migalhas**. E um **identificador da instalação**, para que
um crash que acontece quarenta vezes com uma pessoa não seja contado como quarenta pessoas.

O que ele não deveria levar é qualquer coisa que identifique a pessoa, a não ser que você tenha
decidido que deve e declarado isso, lição 5. A próxima seção monta um coletor cujo cada campo você
consegue ler.
