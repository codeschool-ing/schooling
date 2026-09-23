---
title: Um pull request é um branch pedindo para entrar
version: 1
---

**Um pull request é um pedido para fazer merge de um branch em outro**, com uma página na web para
discutir isso antes. GitHub e Bitbucket o chamam de pull request; o GitLab o chama de merge request, que
é o nome mais preciso. Nada novo é guardado no Git: o branch é um branch comum que você enviou, e a
página é o serviço de hospedagem lendo esse branch.

A Ana enviou o `sunday-hours`, com três commits, e abriu um pull request para o `main`. A página tem
uma aba que lista os commits dele. Essa aba é isto:

```
ana@vm:~/site$ git log --oneline main..sunday-hours
77b6507 Mention Sundays on the menu page
4bda868 Write the Sunday time the way the rest of the page does
b63efb6 Add Sunday hours to the home page
```

**`main..sunday-hours` quer dizer os commits do `sunday-hours` que não estão no `main`.** Esses três são
o que o merge traria. O commit do Bruno no `main` não está entre eles, porque ele já está no `main`.

A outra aba, *files changed*, é um diff. Desta vez com três pontos:

```
ana@vm:~/site$ git diff --stat main...sunday-hours
 index.html | 2 +-
 menu.html  | 1 +
 2 files changed, 2 insertions(+), 1 deletion(-)
```

**`main...sunday-hours` compara o branch com o commit em que ele saiu do `main`**, não com o `main` como
está hoje. Então mostra o que a Ana mudou, e nada sobre o commit da folha de estilo do Bruno, que
aconteceu no `main` nesse meio-tempo. É exatamente o que quem revisa quer: *esta* mudança, não a
diferença entre dois alvos em movimento.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"Seis passos da esquerda para a direita: push do branch, abrir o pull request, checks rodam e pessoas revisam, aprovado, merge no main, branch apagado. Um laço volta do passo da revisão para ele mesmo: quando pedem mudanças, mais commits são enviados para o mesmo branch e a revisão recomeça.\"><defs><marker id=\"pr-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"8\" y=\"80\" width=\"104\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"60\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">push</text><text x=\"60\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">do branch</text><path d=\"M113 108 L125 108\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pr-ah)\"></path><rect x=\"127\" y=\"80\" width=\"104\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"179\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">abrir</text><text x=\"179\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o pull request</text><path d=\"M232 108 L244 108\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pr-ah)\"></path><rect x=\"246\" y=\"80\" width=\"104\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"298\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">checks rodam</text><text x=\"298\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">pessoas revisam</text><path d=\"M351 108 L363 108\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pr-ah)\"></path><rect x=\"365\" y=\"80\" width=\"104\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"417\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">aprovado</text><path d=\"M470 108 L482 108\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pr-ah)\"></path><rect x=\"484\" y=\"80\" width=\"104\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"536\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">merge</text><text x=\"536\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">no main</text><path d=\"M589 108 L601 108\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pr-ah)\"></path><rect x=\"603\" y=\"80\" width=\"104\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"655\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">branch</text><text x=\"655\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">apagado</text><path d=\"M326 78 C336 30 260 30 270 76\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pr-ah)\"></path><text x=\"298\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">mudanças pedidas: mais commits no mesmo branch</text></svg>", "caption": "Um pull request é uma conversa presa a um branch. O branch continua andando até a conversa terminar.", "same": ["push", "branch"]}
```

## O branch continua andando

Um pull request não é uma fotografia do branch no momento em que foi aberto. **Envie outro commit para
o mesmo branch e o pull request o mostra** — commits, diff e tudo — porque a página lê o branch como
ele está agora. É assim que a revisão funciona na prática: quem revisa pede uma mudança, quem escreveu
faz o commit e envia, e a conversa continua no mesmo lugar.

Mais duas coisas que todo serviço tem:

- Pull requests **em rascunho** (*draft*), abertos cedo para mostrar trabalho em andamento e receber
  comentários cedo, marcados como ainda não prontos para o merge.
- **Checks**, que são programas que o serviço roda a cada envio para o branch: os testes, um linter, um
  build. Eles aparecem como aprovados ou reprovados ao lado do botão de merge, e uma equipe pode
  proibir o merge enquanto um estiver vermelho. A aula 17 é sobre para que eles servem.
