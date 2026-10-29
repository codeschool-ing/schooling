---
title: A janela em que os cliques se perdem
version: 1
---

**Entre o momento em que uma página renderizada no servidor aparece e o momento em que o seu script a
assume, todo botão dela é a foto de um botão.** Um clique nessa janela chega a um elemento sem
listener, não faz nada, e é esquecido. Num notebook rápido a janela tem alguns milissegundos e
ninguém a encontra. Num celular lento ela tem segundos.

O `tools/hydrate.ts` consegue fazê-la ter segundos de propósito: `--script-delay 2000` segura todo
script por dois segundos, e `--click-at 300` clica em *Mark done* 300 milissegundos depois de a página
chegar, quando ela já está pintada e o script ainda está a caminho:

```
ana@dev:~/planner$ node tools/hydrate.ts http://localhost:3000/courses/git --script-delay 2000 --click-at 300
clicked Mark done 300 ms after the page arrived
painted at 52 ms, taken over by the script at 2049 ms
Sat 2026-10-24 · 25 min Mark done
Tue 2026-10-27 · 40 min Mark done
```

**O clique aconteceu, e a sessão continua não feita.** A página tinha pintado muito antes, e o script
a assumiu uns dois segundos depois, então o clique caiu no meio. Nada na página dizia que ela não
estava pronta, e nada depois disse que um clique tinha se perdido.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Uma linha do tempo em milissegundos. A página pintou aos 52, o clique em Mark done aconteceu aos 300, e o script assumiu a página aos 2049. O clique caiu dentro da janela entre a pintura e a tomada, e se perdeu.\"><line x1=\"40\" y1=\"120\" x2=\"680\" y2=\"120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"680.0,120.0 672.6,123.1 672.6,116.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"680\" y=\"138\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ms</text><rect x=\"54.654545454545456\" y=\"92\" width=\"562.790909090909\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"396.04999999999995\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">visível, sem funcionar</text><line x1=\"54.654545454545456\" y1=\"68\" x2=\"54.654545454545456\" y2=\"118\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></line><text x=\"54.654545454545456\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pintou · 52</text><line x1=\"124.54545454545455\" y1=\"44\" x2=\"124.54545454545455\" y2=\"118\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><text x=\"124.54545454545455\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">clique: perdido · 300</text><line x1=\"617.4454545454545\" y1=\"68\" x2=\"617.4454545454545\" y2=\"118\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><text x=\"617.4454545454545\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">assumida · 2049</text><text x=\"40\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">O script foi segurado dois segundos de propósito, como numa conexão lenta.</text></svg>", "caption": "Tudo o que acontece com a página entre a pintura e a tomada acontece com uma foto."}
```

## Três jeitos de fechá-la

**Encurtar a janela.** Menos JavaScript antes da hidratação, e um servidor perto da pessoa. Isso é o
assunto das aulas 7 e 8, e é a única correção que também ajuda todo o resto.

**Fazer a página dizer que não está pronta.** Um botão renderizado como `disabled` pelo servidor e
habilitado pelo script não pode ser apertado na janela, e só parece apertável quando é. Custa uma
piscada de controles acinzentados e diz a verdade.

**Gravar os cliques e repeti-los.** O Angular faz isso com o `withEventReplay()` do `app.config.ts` da
aula 2: um pequeno script embutido na página, antes de tudo, grava os eventos do documento inteiro, e a
hidratação os repete para os componentes que agora existem. A página que o Angular mandou na aula 2
traz esse script, `ng-event-dispatch-contract`. O React, a partir da versão 18, repete alguns eventos
que caem numa parte da página que ainda está hidratando. **Um formulário com um `action` de verdade é a
versão mais antiga da ideia**: um envio antes da hidratação ainda vai ao servidor, e funciona.

O planner tem um formulário, e o seu *Add session* mandaria um envio ao servidor se fosse apertado na
janela; o `server.ts` não tem tratador para isso, e a aula 1 disse. Os botões *Mark done* não têm
alternativa nenhuma.
