---
title: Revert: desfazer um commit acrescentando outro
version: 1
---

A farinha chegou, e o pão de centeio deve voltar para o cardápio. O commit que o tirou está no
histórico, e a esta altura também está na cópia do Bruno, e na compartilhada. **O `git revert` faz um
commit novo que faz o contrário de um antigo:**

```
ana@vm:~/site$ git revert --no-edit HEAD~1
[main c28977c] Revert "Take rye bread off until the flour arrives"
 Date: Mon Sep 21 10:30:00 2026 -0300
 1 file changed, 1 insertion(+)
ana@vm:~/site$ git log --oneline -3
c28977c Revert "Take rye bread off until the flour arrives"
6555c9b Link the menu from the home page
eadf998 Take rye bread off until the flour arrives
ana@vm:~/site$ cat menu.html
<h1>Menu</h1>
<p>French bread, 0.90</p>
<p>Rye bread, 1.35</p>
<p>Cheese roll, 2.50</p>
```

O log mostra o que aconteceu e o que não aconteceu. O commit antigo, `eadf998`, continua lá. Um novo,
`c28977c`, fica em cima, com uma mensagem que o Git escreveu: `Revert "Take rye bread off until the
flour arrives"`. A mudança dele é a mudança antiga do avesso, uma linha acrescentada de volta, e o
cardápio tem pão de centeio de novo. O `--no-edit` aceitou essa mensagem como está; sem ele, o Git
abre o editor para você acrescentar *por que* está revertendo, o que em geral vale a pena.

## Por que acrescentar em vez de remover

Parece dar uma volta: o commit foi um erro, então por que não apagá-lo? Porque **as cópias das outras
pessoas já o contêm.** A aula 1 mostrou que o id de cada commit cobre o do pai; tire um commit do
meio de um histórico e todo commit depois dele ganha um id novo. A sua cópia e a do Bruno
discordariam sobre o que o histórico *é*, e na próxima vez que vocês compartilhassem trabalho, o Git
veria dois conjuntos de commits sem relação, com as mesmas mensagens. A aula 7 mostra como isso
parece do outro lado.

Um revert não tem nada disso. É um commit novo comum, em cima, e todo mundo que o busca recebe um
histórico que continua batendo com o seu. **O revert é o único desfazer seguro num commit que já foi
compartilhado**, e na maioria das equipes o branch principal é compartilhado por definição.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Duas versões do mesmo histórico de três commits, A, B e C. Na primeira, o revert acrescenta um quarto commit que desfaz o C, e o main avança até ele; o C continua no histórico. Na segunda, o reset leva o main de volta ao B, e o C fica sem branch nenhum, desenhado apagado, lembrado só pelo reflog.\"><defs><marker id=\"ud-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">revert — um commit novo desfaz o C</text><path d=\"M169 80 L93 80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ud-ah)\"></path><path d=\"M269 80 L193 80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ud-ah)\"></path><path d=\"M369 80 L293 80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ud-ah)\"></path><circle cx=\"80\" cy=\"80\" r=\"10\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.6\"></circle><text x=\"80\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">A</text><circle cx=\"180\" cy=\"80\" r=\"10\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.6\"></circle><text x=\"180\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">B</text><circle cx=\"280\" cy=\"80\" r=\"10\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.6\"></circle><text x=\"280\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">C</text><circle cx=\"380\" cy=\"80\" r=\"10\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"380\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">revert C</text><rect x=\"357.0\" y=\"40\" width=\"46\" height=\"20\" rx=\"10\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"380\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">main</text><path d=\"M380 60 L380 68\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"440\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o histórico cresce; o C fica, e o desfazer dele também</text><path d=\"M20 140 L700 140\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"20\" y=\"170\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">reset — o branch volta para antes do C</text><path d=\"M169 230 L93 230\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ud-ah)\"></path><circle cx=\"80\" cy=\"230\" r=\"10\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.6\"></circle><text x=\"80\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">A</text><circle cx=\"180\" cy=\"230\" r=\"10\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"180\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">B</text><rect x=\"157.0\" y=\"190\" width=\"46\" height=\"20\" rx=\"10\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"180\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">main</text><path d=\"M180 210 L180 218\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><circle cx=\"280\" cy=\"230\" r=\"10\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.6\"></circle><circle cx=\"280\" cy=\"230\" r=\"10\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></circle><text x=\"280\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">C</text><path d=\"M269 230 L193 230\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ud-ah)\" stroke-dasharray=\"3 3\"></path><text x=\"320\" y=\"234\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o C não está em branch nenhum; só o reflog ainda o aponta</text></svg>", "caption": "O revert acrescenta ao histórico, então é seguro em commits que outras pessoas têm. O reset tira do branch, então só é seguro em commits que ninguém mais tem."}
```

## O que o revert não faz

Ele não esconde nada. Os dois commits ficam no log para sempre, e isso é uma vantagem: daqui a seis
meses, alguém lendo `git log -- menu.html` vê o centeio removido e o centeio devolvido, com o motivo
de cada um.

Ele também funciona em qualquer commit, não só no último. Aqui ele reverteu o `HEAD~1` e deixou em
paz o link na página inicial, que veio depois. Se um commit posterior tivesse mudado as mesmas
linhas, o Git não conseguiria calcular o contrário sozinho e pararia para perguntar a você, o que é
um conflito; a aula 6 ensina o que fazer com um.
