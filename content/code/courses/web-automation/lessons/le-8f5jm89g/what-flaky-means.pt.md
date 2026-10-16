---
title: O mesmo código, outro veredito
version: 1
---

**Um teste é instável quando dá um veredito diferente para o mesmo código**: ninguém mexeu na loja,
ninguém mexeu no teste, a máquina é a mesma, e uma execução fica verde enquanto a seguinte fica
vermelha. A primeira crença que quase todo mundo tem sobre um teste assim é que ele é um incômodo
pequeno, melhor que um teste que falha toda vez, porque pelo menos passa na maioria das vezes. Esta
aula defende o contrário. Um teste que sempre falha é informação. Um teste que falha de vez em
quando é ruído, e o ruído ensina quem o lê a parar de ler.

## A sua própria suíte tem um

Tudo o que você salvou em `tests/` desde a aula 1 é o que um `npx playwright test` simples roda, e
essa execução é o que uma equipe chamaria de portão: a verificação pela qual uma mudança tem de
passar. Aqui está ela dez vezes seguidas, com o `grep` guardando o resumo de cada execução e o nome
de cada teste que falhou:

```
ana@laptop:~/quitanda$ for i in 1 2 3 4 5 6 7 8 9 10; do npx playwright test | grep -E '^  [0-9]+ (failed|flaky|passed)|^    tests/'; done
  42 passed (12.8s)
  42 passed (12.5s)
  2 failed
    tests/cache.spec.js:7:1 › a new offer reaches the page ─────────────────────────────────────────
    tests/ssr.spec.js:8:1 › a click on /ssr adds to the basket once the page is ready ──────────────
  40 passed (20.2s)
  42 passed (12.5s)
  2 failed
    tests/cache.spec.js:7:1 › a new offer reaches the page ─────────────────────────────────────────
    tests/ssr.spec.js:8:1 › a click on /ssr adds to the basket once the page is ready ──────────────
  40 passed (20.2s)
  2 failed
    tests/cache.spec.js:7:1 › a new offer reaches the page ─────────────────────────────────────────
    tests/ssr.spec.js:8:1 › a click on /ssr adds to the basket once the page is ready ──────────────
  40 passed (20.2s)
  42 passed (12.6s)
  2 failed
    tests/cache.spec.js:7:1 › a new offer reaches the page ─────────────────────────────────────────
    tests/ssr.spec.js:8:1 › a click on /ssr adds to the basket once the page is ready ──────────────
  40 passed (20.3s)
  42 passed (12.4s)
  42 passed (12.5s)
```

**Quatro execuções de dez falharam, e as outras seis passaram**, sem nenhuma edição entre elas. Em
todas as vezes os mesmos dois testes falharam juntos: o `a new offer reaches the page` da aula 4 e o
`a click on /ssr adds to the basket once the page is ready` da aula 6. Uma execução com falha levou
cerca de 20 segundos, contra uns 12,5 de uma que passou, porque uma verificação que falha antes
espera os seus cinco segundos.

Os dois testes começam com `POST /api/reset`, e essa requisição reinicia a loja inteira: esvazia a
cesta única e põe a oferta de volta na manga. O Playwright roda arquivos lado a lado, em dois
workers nesta máquina de quatro processadores, e um reset enviado por um teste pode chegar no meio
de outro. O teste do cache troca a oferta para banana e depois abre a página; um reset no meio do
caminho deixa a manga lá. Cada teste está certo sobre uma loja que tenha só para si. A próxima
seção dá nome a essa causa e a mostra em dois testes menores.

## Por que é pior que o vermelho

Um teste que falha toda vez é corrigido ou vira discussão, porque ninguém consegue integrar uma
mudança passando por cima dele. Um teste que falha quatro vezes em dez é **rodado de novo**. A
segunda execução fica verde, a mudança entra, e quem apertou o botão aprende que um vermelho desta
suíte quer dizer *tente outra vez*. Essa lição não fica presa a um teste. No dia em que uma mudança
quebrar de verdade o teste do cache, o vermelho é lido do mesmo jeito, e o defeito entra na segunda
tentativa.

A plataforma em que você estuda registra isso em vários lugares, sempre pelo mesmo motivo. Uma
verificação do dicionário do seu console foi escrita para apontar entradas suspeitas e, na primeira
execução, apontou dez corretas. Ela foi reduzida, porque *uma verificação que dá alarme falso ensina
quem a lê a pular a saída que um dia vai apontar um problema real*. Outra verificação é frouxa de
propósito sobre a idade de um arquivo de dados e só falha depois de um ano, porque um limite de um
trimestre ficaria vermelho a cada virada de trimestre *e seria silenciado em uma semana*. **Um
alarme que toca sem incêndio é um alarme que vai ser desligado.**

## Verde por sorte

A outra metade é mais silenciosa. As seis execuções verdes acima não provam que os dois testes
funcionam; foram execuções em que o reset caiu por acaso num lugar inofensivo. As regras da própria
plataforma descrevem uma das suas suítes do mesmo jeito: ela *passou na máquina local só por causa
do tempo*, e isso foi chamado de pior que falhar, *porque quer dizer que a suíte estava verde por
sorte*. Uma suíte verde por sorte não diz nada nos dias em que está verde.

## Instável, ou um defeito?

A aula 3 traçou uma linha, e esta aula a mantém. O teste de busca dela falhava **toda vez**, na
mesma linha, com as mesmas três frutas: aquilo era um defeito da página, e o teste estava certo. Um
teste instável falha **às vezes**. A causa pode estar no teste, no que está em volta dele ou na
página, e a seção das causas mostra um caso em que é a própria página que oscila. O que separa os
dois é a repetição. Uma execução diz muito pouco. Vinte execuções dizem se você está olhando para
uma taxa.
