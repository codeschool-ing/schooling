---
title: Testando dentro de um ciclo de duas semanas
version: 1
---

**Um time ágil constrói o sistema em ciclos curtos, em geral de uma a quatro semanas, e no fim de cada um
algo funciona que não funcionava antes.** Para quem testa, a diferença em relação a tudo das aulas 9 e 10 é
o tamanho do laço. O V inteiro, do requisito à aceitação, precisa caber em duas semanas, para uma fatia do
sistema pequena o bastante para caber.

## A minicascata, e por que ela falha

O jeito mais comum de o ágil dar errado para quem testa tem nome próprio: a **minicascata**. O time planeja
um ciclo de duas semanas, os desenvolvedores constroem por oito dias, e tudo chega a quem testa no nono. É a
cascata da aula 9, encolhida: o mesmo aperto no fim, o mesmo trabalho chegando todo de uma vez, agora a cada
duas semanas em vez de uma vez por ano.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 660 230\" role=\"img\" data-fig=\"l11-two-sprints\" aria-label=\"Duas linhas do tempo de dez dias úteis. Minicascata: construir ocupa os dias 1 a 8 e o teste é espremido nos dias 9 e 10, com uma nota de que tudo chega no dia 9. Teste o tempo todo: no dia 1 quem testa faz perguntas, e a partir do dia 2 pedaços pequenos são construídos e cada um é testado um ou dois dias depois, então blocos de construir e testar se alternam pelo ciclo inteiro.\"><text x=\"174.5\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">dia 1</text><text x=\"223.5\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">dia 2</text><text x=\"272.5\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">dia 3</text><text x=\"321.5\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">dia 4</text><text x=\"370.5\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">dia 5</text><text x=\"419.5\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">dia 6</text><text x=\"468.5\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">dia 7</text><text x=\"517.5\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">dia 8</text><text x=\"566.5\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">dia 9</text><text x=\"615.5\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">dia 10</text><text x=\"140.0\" y=\"60.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">minicascata</text><rect x=\"150.0\" y=\"40.0\" width=\"390.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"345.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">construir</text><rect x=\"542.0\" y=\"40.0\" width=\"96.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">testar</text><text x=\"542.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">tudo chega no dia 9</text><text x=\"140.0\" y=\"150.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">teste o tempo todo</text><rect x=\"150.0\" y=\"130.0\" width=\"47.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"173.5\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">perguntar</text><rect x=\"199.0\" y=\"130.0\" width=\"47.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"222.5\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">construir</text><rect x=\"248.0\" y=\"130.0\" width=\"47.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"271.5\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">construir</text><rect x=\"297.0\" y=\"130.0\" width=\"47.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"320.5\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--phosphor)\">testar</text><rect x=\"346.0\" y=\"130.0\" width=\"47.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"369.5\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">construir</text><rect x=\"395.0\" y=\"130.0\" width=\"47.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"418.5\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--phosphor)\">testar</text><rect x=\"444.0\" y=\"130.0\" width=\"47.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"467.5\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">construir</text><rect x=\"493.0\" y=\"130.0\" width=\"47.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"516.5\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--phosphor)\">testar</text><rect x=\"542.0\" y=\"130.0\" width=\"47.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"565.5\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">construir</text><rect x=\"591.0\" y=\"130.0\" width=\"47.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"614.5\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--phosphor)\">testar</text></svg>", "caption": "As mesmas duas semanas. Em cima, a cascata encolhida para uma sprint; embaixo, o teste acompanha a construção, e todo defeito é achado enquanto é novo."}
```

A figura mostra a diferença. Na minicascata, o teste é um bloco no fim e o que ele acha ou passa para o
próximo ciclo ou vai para produção. Na versão que funciona, o teste corre desde o primeiro dia: no dia um a
Lia está fazendo perguntas sobre as histórias, no dia três está testando o primeiro pedaço pequeno que o
Rafael terminou, e no último dia sobra pouco que ninguém olhou.

## O que torna o teste contínuo possível

Três hábitos, cada um uma escolha do time, e cada um com uma aula posterior própria:

- **histórias pequenas.** Um trabalho pequeno o bastante para ser construído e testado em um ou dois dias
  chega ao teste cedo, sozinho, enquanto o autor ainda lembra dele. "A regra de preço inteira" é grande
  demais; "estudantes pagam meia" é uma história;
- **uma definição de pronto compartilhada.** Uma história não está pronta quando o código está escrito;
  está pronta quando está testada, pelo que quer que o time combine que "testada" quer dizer. A aula 12 trata
  de escrever essa definição;
- **verificações de regressão automatizadas.** Todo ciclo muda código que funcionava no ciclo anterior, e a
  aula 10 mostrou como a regressão cresce. Um time que retesta à mão deixa de conseguir terminar um ciclo em
  poucos meses. As aulas 15 a 17 tratam das formas de verificação automatizada em que os times ágeis mais se
  apoiam.

## O que quem testa faz o dia inteiro

Num ciclo curto, a semana de quem testa se parece menos com uma fase de teste e mais com a tabela da
terceira semana da Lia, na aula 5: perguntas no começo, pareamento no meio, exploração do que acabou de ficar
pronto, e ajuda ao time para decidir se o trabalho do ciclo está pronto. A conferência de pedaços prontos
continua lá, mas acontece em porções pequenas, o tempo todo, e não num bloco no fim.

O ritmo importa por causa da aula 3. Um defeito achado no dia três de um ciclo de duas semanas tem algumas
horas de vida; o autor lembra dele, nada está construído em cima, ninguém de fora do time topou com ele.
**Ciclos curtos fazem de todo defeito um defeito novo**, que é o tipo mais barato que existe, desde que o
teste acompanhe a construção em vez de esperar pelo fim.
