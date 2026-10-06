---
title: Integração, entrega, implantação
version: 1
---

Três expressões dividem a sigla CI/CD, e as pessoas as usam sem muito cuidado. Elas nomeiam três
promessas diferentes, e a diferença entre as duas últimas é uma decisão: **quem aperta o botão que
põe uma mudança na frente dos usuários.**

- **Integração contínua**, aulas 5 e 6: toda mudança é integrada com frequência e conferida
  automaticamente. O resultado é um veredito, verde ou vermelho, sobre o código.
- **Entrega contínua** (*continuous delivery*): toda mudança que passa vira um release **que poderia ir
  para a produção a qualquer momento**, e prova que é implantável sendo implantada num lugar parecido
  com a produção. Uma pessoa decide quando ela entra no ar, e entrar no ar é um ato de rotina que leva
  minutos.
- **Implantação contínua** (*continuous deployment*): toda mudança que passa vai para a produção
  **automaticamente**, sem pessoa no caminho. O pipeline é o processo de release.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Três linhas comparam as práticas. A integração contínua vai do merge ao teste e para aí. A entrega contínua vai do merge ao teste e à homologação, e uma pessoa decide antes da produção. A implantação contínua segue o mesmo caminho sem pessoa: a produção vem automaticamente.\"><text x=\"136\" y=\"50\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">integração</text><rect x=\"150\" y=\"30\" width=\"110\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"205.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">merge</text><rect x=\"285\" y=\"30\" width=\"110\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"340.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">teste</text><path d=\"M260 50 L279 50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></path><path d=\"M278 46 L285 50 L278 54 z\" fill=\"var(--paper-dim)\"></path><text x=\"136\" y=\"125\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">entrega</text><rect x=\"150\" y=\"105\" width=\"110\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"205.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">merge</text><rect x=\"285\" y=\"105\" width=\"110\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"340.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">teste</text><path d=\"M260 125 L279 125\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></path><path d=\"M278 121 L285 125 L278 129 z\" fill=\"var(--paper-dim)\"></path><rect x=\"420\" y=\"105\" width=\"110\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"475.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">homologação</text><path d=\"M395 125 L414 125\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></path><path d=\"M413 121 L420 125 L413 129 z\" fill=\"var(--paper-dim)\"></path><rect x=\"590\" y=\"105\" width=\"110\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"645.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">produção</text><path d=\"M530 125 L584 125\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></path><path d=\"M583 121 L590 125 L583 129 z\" fill=\"var(--amber)\"></path><circle cx=\"560.0\" cy=\"125\" r=\"6\" fill=\"var(--amber)\"></circle><text x=\"560.0\" y=\"159\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">uma pessoa decide</text><text x=\"136\" y=\"200\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">implantação</text><rect x=\"150\" y=\"180\" width=\"110\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"205.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">merge</text><rect x=\"285\" y=\"180\" width=\"110\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"340.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">teste</text><path d=\"M260 200 L279 200\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></path><path d=\"M278 196 L285 200 L278 204 z\" fill=\"var(--paper-dim)\"></path><rect x=\"420\" y=\"180\" width=\"110\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"475.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">homologação</text><path d=\"M395 200 L414 200\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></path><path d=\"M413 196 L420 200 L413 204 z\" fill=\"var(--paper-dim)\"></path><rect x=\"590\" y=\"180\" width=\"110\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"645.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">produção</text><path d=\"M530 200 L584 200\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></path><path d=\"M583 196 L590 200 L583 204 z\" fill=\"var(--phosphor)\"></path><text x=\"560.0\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">automático</text></svg>", "caption": "As três práticas dividem os primeiros passos. Diferem em onde param, e em quem leva um release para a produção.", "same": ["merge"]}
```

Uma imagem errada comum é a de que entrega contínua é implantação contínua malfeita, por uma equipe
que ainda não teve coragem de automatizar o último passo. São escolhas diferentes. Uma equipe que
pratica entrega contínua consegue publicar qualquer commit verde em uma hora; ela só escolhe quando. O
que ela nunca pode ter é um release que exige uma semana de preparação, porque essa é uma equipe que
não entrega continuamente de jeito nenhum, diga o pipeline o que disser.

## O que as duas exigem

Tudo depois da integração se apoia em quatro coisas, e esta aula constrói cada uma para o
`shipquote`:

1. **Um artefato**, montado uma vez a partir de um commit, identificado pelo conteúdo e promovido sem
   mudança de ambiente em ambiente (seções 03 e 04).
2. **Um pipeline** que leva esse artefato pelos estágios numa ordem fixa (seção 05).
3. **Um deploy que é um comando**, e não um procedimento na cabeça de alguém, e que confere o próprio
   resultado (seções 06 e 07).
4. **Uma barreira** onde a decisão é tomada, por uma pessoa ou por uma regra (seção 08).

O laboratório os mantém pequenos. Um ambiente aqui é um diretório com configuração própria e um
processo numa porta própria; a aula 8 diz o que ambientes de verdade acrescentam. O que não encolhe
são a ordem e as verificações: são as mesmas num notebook e num datacenter.
