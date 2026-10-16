---
title: A definição de pronto
version: 1
---

**A definição de pronto é a declaração compartilhada do time sobre o que precisa ser verdade antes de qualquer
trabalho contar como terminado.** O Guia do Scrum a chama de descrição formal do estado do incremento quando
ele cumpre as medidas de qualidade exigidas para o produto. Em palavras simples: a régua, escrita, que toda
história precisa passar, a mesma régua para toda história.

Sem uma, "pronto" quer dizer o que a pessoa que o diz quis dizer: o pronto do Rafael é "o código está
escrito", o da Lia é "eu testei", o da Joana é "os clientes conseguem usar". Três pessoas relatando a mesma
história como pronta dizem três coisas diferentes, e o vão entre elas é por onde trabalho não testado escorrega
para uma entrega.

## A do Cine Aurora

Depois da sprint em que três histórias chegaram à Lia no dia nove, o time escreveu esta:

> Uma história está pronta quando:
> 1. o código foi revisado por outro desenvolvedor;
> 2. cada critério de aceitação tem um teste, e os testes passam;
> 3. as verificações automatizadas de tudo o que foi construído antes ainda passam;
> 4. a Lia, ou outro Developer, a explorou por pelo menos meia hora além dos critérios;
> 5. toda pergunta que ela levantou sobre uma regra tem uma resposta da Joana, escrita como exemplo;
> 6. ela está na versão que poderia ser entregue hoje, sem ninguém precisar lembrar de fazer algo antes.

Cada linha existe por causa de algo que deu errado. A linha 3 é a pilha de regressão da aula 10. A linha 4
existe porque critérios de aceitação só cobrem o que se pensou, e a aula 6 achou a soma de descontos da quarta
olhando além deles. A linha 5 é a resposta da quarta, transformada em hábito. A linha 6 é a que os times mais
deixam de fora, e é o que "incremento utilizável" quer dizer.

## Definição de pronto e critérios de aceitação

As duas são muito confundidas, e a diferença é simples:

- a **definição de pronto** vale para **toda** história: as mesmas seis linhas, seja qual for o assunto da
  história;
- os **critérios de aceitação** valem para **uma** história: o que este trabalho específico precisa fazer.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 660 250\" role=\"img\" data-fig=\"l12-done\" aria-label=\"Uma moldura grande chamada definição de pronto, toda história, lista seis condições: revisada, critérios testados, conferências antigas passam, explorada, respostas escritas, entregável. Dentro dela estão três histórias: estudantes pagam meia, idosos pagam meia, cupons. Cada história leva a sua própria caixinha de critérios de aceitação, só daquela história.\"><rect x=\"10.0\" y=\"10.0\" width=\"640.0\" height=\"230.0\" rx=\"8\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"24.0\" y=\"30.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">definição de pronto: toda história</text><text x=\"24.0\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">✓ revisada</text><text x=\"234.0\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">✓ critérios testados</text><text x=\"444.0\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">✓ conferências antigas passam</text><text x=\"24.0\" y=\"64.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">✓ explorada</text><text x=\"234.0\" y=\"64.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">✓ respostas escritas</text><text x=\"444.0\" y=\"64.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">✓ entregável</text><rect x=\"30.0\" y=\"80.0\" width=\"185.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"122.5\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">estudantes pagam meia</text><rect x=\"42.0\" y=\"132.0\" width=\"161.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><path d=\"M54.0 150.0 L190.0 150.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M54.0 166.0 L190.0 166.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M54.0 182.0 L190.0 182.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"235.0\" y=\"80.0\" width=\"185.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"327.5\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">idosos pagam meia</text><rect x=\"247.0\" y=\"132.0\" width=\"161.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><path d=\"M259.0 150.0 L395.0 150.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M259.0 166.0 L395.0 166.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M259.0 182.0 L395.0 182.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"440.0\" y=\"80.0\" width=\"185.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"532.5\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">cupons</text><rect x=\"452.0\" y=\"132.0\" width=\"161.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><path d=\"M464.0 150.0 L600.0 150.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M464.0 166.0 L600.0 166.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M464.0 182.0 L600.0 182.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"330.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">critérios de aceitação: só desta história</text></svg>", "caption": "A definição de pronto é uma régua só para toda história; os critérios de aceitação são o que uma história precisa fazer. Uma história cumpre os dois, ou não está pronta."}
```

Para a história *estudantes pagam meia*, os critérios de aceitação poderiam ser: um estudante numa sessão da
noite paga R$ 18,00; um estudante numa matinê paga R$ 14,00; um estudante numa quarta paga R$ 18,00, não
R$ 9,00. A definição de pronto diz que cada um desses três precisa ter um teste que passa, junto com todo o
resto da lista. Uma história pode cumprir todos os critérios de aceitação e ainda não estar pronta, porque
ninguém a explorou ou porque ela quebrou uma verificação antiga.

## Uma definição que o time de fato cumpre

Uma definição de pronto só vale o que o time faz quando uma história não a passa. O resultado honesto é que a
história não está pronta, volta ao backlog ou continua em andamento, e não é mostrada na revisão como
terminada. O resultado desonesto, comum sob pressão de prazo, é chamá-la de pronta mesmo assim e "corrigir na
próxima sprint", que é a dívida de teste da aula 11 na forma mais pura.

O trabalho de quem testa aqui é menos policiar a definição do que mantê-la honesta: apontar quando uma
história está sendo chamada de pronta sem estar, e levar a lacuna à retrospectiva, onde o time pode decidir se
a definição está errada ou se a sprint é que estava.
