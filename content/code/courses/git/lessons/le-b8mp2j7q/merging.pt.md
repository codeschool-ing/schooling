---
title: Merge: fast-forward, ou um commit com dois pais
version: 1
---

O trabalho num branch termina quando ele entra no `main`. **O `git merge nome` traz o branch nomeado
para aquele em que você está**, e, dependendo do que aconteceu em cada lado, faz uma de duas coisas
diferentes.

## Quando o main não andou: fast-forward

Desde que o `opening-hours` foi criado, ninguém fez commit no `main`. Então o `main` está
simplesmente atrás:

```
ana@vm:~/site$ git merge opening-hours
Updating 6555c9b..9677eef
Fast-forward
 index.html | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
ana@vm:~/site$ git log --oneline -3
9677eef Open on Sundays from seven
6555c9b Link the menu from the home page
eadf998 Take rye bread off until the flour arrives
```

`Fast-forward` quer dizer que o Git **levou o `main` para a frente, até o commit do outro branch**, e
não fez mais nada. Nenhum commit novo foi criado, porque nenhum era necessário: todo commit do
`opening-hours` já vem depois dos do `main`, então apontar o `main` para o mais novo é o merge
inteiro. O log mostra uma linha reta.

## Quando os dois lados andaram: um commit de merge

Agora o caso comum. Um branch para o preço novo do pão francês e, enquanto isso, um commit no `main`
sobre o espaçamento dos parágrafos:

```
ana@vm:~/site$ git switch -c menu-prices
Switched to a new branch 'menu-prices'
ana@vm:~/site$ git commit -qam "Charge 0.95 for French bread"
ana@vm:~/site$ git switch main
Switched to branch 'main'
ana@vm:~/site$ git commit -qam "Give paragraphs more room"
ana@vm:~/site$ git log --oneline --graph --all -4
* 68491c4 Give paragraphs more room
| * 59ec506 Charge 0.95 for French bread
|/  
* 9677eef Open on Sundays from seven
* 6555c9b Link the menu from the home page
```

O `--graph` desenha a forma que o log de uma linha escondia. Os dois commits ficam lado a lado, cada
um na sua linha do desenho, e os dois nasceram do `9677eef`. **O histórico se bifurcou.** Nenhum
ponteiro consegue avançar de modo a incluir os dois, porque nenhum contém o outro.

```
ana@vm:~/site$ git merge --no-edit menu-prices
Merge made by the 'ort' strategy.
 menu.html | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
ana@vm:~/site$ git log --oneline --graph -5
*   d340360 Merge branch 'menu-prices'
|\  
| * 59ec506 Charge 0.95 for French bread
* | 68491c4 Give paragraphs more room
|/  
* 9677eef Open on Sundays from seven
* 6555c9b Link the menu from the home page
ana@vm:~/site$ git cat-file -p HEAD
tree 8a50de9e8a8d84b76058c336a553b557e91cd480
parent 68491c428c34de228b3f8f1b1b87d0897fe28834
parent 59ec50622bb677f0ee952bbd07f001cd2c77b671
author Ana Souza <ana@example.com> 1790002800 -0300
committer Ana Souza <ana@example.com> 1790002800 -0300

Merge branch 'menu-prices'
```

**O Git escreveu um commit novo cujo trabalho é juntar os dois**, o `d340360`, e o `cat-file` dele
mostra o que faz dele um merge: duas linhas `parent`, uma para cada lado. A árvore dele combina as
duas mudanças, o preço novo do `menu-prices` e o espaçamento do `main`. O desenho agora fecha a
bifurcação. O `ort` na primeira linha da saída é o nome do método que o Git usou para combiná-los, e
você não vai precisar escolher outro.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 350\" role=\"img\" aria-label=\"Dois casos. No primeiro, o main não tem commits próprios desde que o branch foi criado, então o merge só leva o main para a frente, até o commit do branch. No segundo, o main e o menu-prices têm cada um um commit novo, então o merge cria um commit novo, d340360, cujos dois pais são as pontas dos dois branches.\"><defs><marker id=\"mg-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">fast-forward: o main não tinha andado</text><path d=\"M209 80 L93 80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mg-ah)\"></path><circle cx=\"80\" cy=\"80\" r=\"10\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.6\"></circle><text x=\"80\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">6555c9b</text><circle cx=\"220\" cy=\"80\" r=\"10\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"220\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">9677eef</text><rect x=\"197.0\" y=\"38\" width=\"46\" height=\"20\" rx=\"10\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"220\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">main</text><path d=\"M220 58 L220 68\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"46\" y=\"38\" width=\"68\" height=\"20\" rx=\"10\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></rect><text x=\"80\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">main</text><path d=\"M116 48 C150 40 170 40 184 46\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mg-ah)\" stroke-dasharray=\"3 3\"></path><text x=\"280\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o main desliza para a frente; nenhum commit novo</text><path d=\"M20 130 L700 130\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"20\" y=\"160\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">divergiram: os dois lados têm commits novos</text><path d=\"M209 210 C150.0 210 150.0 250 93 250\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mg-ah)\"></path><path d=\"M209 290 C150.0 290 150.0 250 93 250\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mg-ah)\"></path><path d=\"M369 250 C300.0 250 300.0 210 233 210\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mg-ah)\"></path><path d=\"M369 250 C300.0 250 300.0 290 233 290\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mg-ah)\"></path><circle cx=\"80\" cy=\"250\" r=\"10\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.6\"></circle><text x=\"80\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">9677eef</text><circle cx=\"220\" cy=\"210\" r=\"10\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.6\"></circle><text x=\"220\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">68491c4</text><circle cx=\"220\" cy=\"290\" r=\"10\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.6\"></circle><text x=\"220\" y=\"312\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">59ec506</text><circle cx=\"380\" cy=\"250\" r=\"10\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"380\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">d340360</text><rect x=\"357.0\" y=\"204\" width=\"46\" height=\"20\" rx=\"10\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"380\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">main</text><path d=\"M380 224 L380 238\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"220\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">main</text><text x=\"220\" y=\"334\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">menu-prices</text><text x=\"430\" y=\"254\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">um commit de merge com dois pais</text></svg>", "caption": "O Git faz fast-forward quando pode, e escreve um commit de merge quando os dois lados andaram."}
```

O Git conseguiu combinar isso sozinho porque os dois lados mudaram arquivos diferentes. Quando os dois
lados mudam as mesmas linhas, ele não consegue decidir qual está certo e para para perguntar: isso é
um conflito, e a aula 6 é sobre ele.

**Qual dos dois você recebe não é escolha sua por padrão, é do histórico.** Algumas equipes preferem
um commit de merge mesmo quando daria para fazer fast-forward, para que todo trabalho apareça como uma
unidade no log; o `git merge --no-ff` faz isso. A aula 9 é onde essa preferência é discutida.
