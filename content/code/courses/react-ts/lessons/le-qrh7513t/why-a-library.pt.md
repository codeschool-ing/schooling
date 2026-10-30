---
title: Por que o efeito da aula 5 não basta
version: 1
---

**A busca da aula 5 estava correta, e cuidava de uma das muitas coisas que buscar dados envolve.**
Ela carregava uma vez, descartava uma resposta atrasada e desenhava três estados. Aqui está o que ela
não fazia, cada coisa de que uma tela de verdade precisa mais cedo ou mais tarde:

| uma tela de verdade precisa de | o efeito da aula 5 |
|---|---|
| os mesmos dados compartilhados por todo componente que pede, buscados uma vez | cada um que pedisse buscaria o seu |
| duas requisições simultâneas da mesma coisa juntadas numa | só o strict mode já mandava duas |
| uma nova tentativa quando uma requisição falha por um instante | uma falha é definitiva |
| dados novos depois de uma mudança ser salva | a mudança só vive no estado local |
| dados novos quando o usuário volta à aba | nunca busca de novo |
| os dados antigos na tela enquanto os novos carregam | volta a "carregando" |

Nada disso é difícil sozinho, e tudo junto é uma biblioteca. O motivo mais profundo é que **dados de
um servidor não são estado no sentido que a aula 4 quis dizer**. O `useState` é dono do valor: nada
mais consegue mudá-lo. As sessões do planejador são uma cópia de algo que pertence ao servidor, que
qualquer um com acesso pode mudar a qualquer momento, e a cópia só está certa até deixar de estar.
Manter uma cópia certa é fazer cache, e fazer cache é saber quando uma cópia ficou velha.

```schooling-figure
{"svg": "<svg data-fig=\"server-state\" viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Dois tipos de estado. O estado do cliente, como a semana escolhida ou o curso aberto, mora no navegador e só este app o muda. O estado do servidor, os cursos e as sessões, mora no servidor; o navegador guarda uma cópia em cache, que outras pessoas e outras abas podem deixar velha a qualquer momento.\"><rect x=\"20\" y=\"30\" width=\"300\" height=\"160\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"170\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">o navegador</text><rect x=\"40\" y=\"70\" width=\"260\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"84.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">estado do cliente</text><text x=\"170.0\" y=\"99.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">monday · openId</text><rect x=\"40\" y=\"128\" width=\"260\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"170.0\" y=\"142.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">uma cópia em cache</text><text x=\"170.0\" y=\"157.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">['planner']</text><rect x=\"420\" y=\"90\" width=\"280\" height=\"80\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"560.0\" y=\"122.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o servidor</text><text x=\"560.0\" y=\"137.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">data/planner.json</text><line x1=\"418\" y1=\"140\" x2=\"302\" y2=\"150\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"302.0,150.0 309.2,146.2 309.7,152.5\" fill=\"var(--amber)\"></polygon><text x=\"360\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">GET</text><text x=\"560\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">qualquer um com acesso pode mudá-lo</text></svg>", "caption": "O estado do cliente tem dono; o do servidor é uma cópia, e uma cópia pode ficar velha.", "same": ["monday · openId", "['planner']", "data/planner.json"]}
```

O TanStack Query, que muita gente ainda chama de React Query, é um cache para dados de servidor com um
hook na frente. Você diz como buscar algo e dá uma key aos dados; ele decide quando buscar, guarda a
resposta naquela key, a compartilha com todo componente que pede a mesma key, e busca de novo quando
avisado de que os dados mudaram ou quando julga a cópia velha. A aula 9 terminou nisso: bibliotecas de
estado global guardam estado do cliente, e esta é a ferramenta para o outro tipo.
