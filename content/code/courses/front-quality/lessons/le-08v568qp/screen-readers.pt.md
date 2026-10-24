---
title: O que um leitor de tela faz
version: 1
---

**Um leitor de tela transforma a página em fala ou em braile, um elemento de cada vez.** Ele não lê os
pixels. Ele lê uma estrutura que o navegador constrói ao lado da página, a **árvore de acessibilidade**, em
que cada elemento que importa tem um **papel** (*link*, *botão*, *título*), um **nome** (*Done*,
*JavaScript*) e, quando tem, um **estado** (*marcado*, *expandido*, *nível 1*). Um botão que diz *Done* na
tela e não tem nome na árvore é, para quem usa leitor de tela, um botão que não diz nada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l12-tree\" aria-label=\"Duas colunas. À esquerda, o alto da página de curso do planner como ele é desenhado: uma seta, o título JavaScript, uma linha de sessão com um botão Done. À direita, os mesmos elementos como a árvore de acessibilidade os descreve, cada um como um papel, um nome e um estado: um link chamado pela seta, um título chamado JavaScript no nível 1, um item de lista com o texto 2026-10-22 · 30 min e um botão chamado Done. Setas ligam cada elemento desenhado à sua linha na árvore. Uma nota diz que um leitor de tela lê só a coluna da direita.\"><defs><marker id=\"l12-tree-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"150\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">o que é desenhado</text><text x=\"520\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--phosphor)\">o que a árvore diz</text><rect x=\"30\" y=\"34\" width=\"240\" height=\"170\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"50\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" fill=\"var(--paper)\">←</text><text x=\"50\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"15\" font-weight=\"600\" fill=\"var(--paper)\">JavaScript</text><text x=\"50\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2026-10-22 · 30 min</text><rect x=\"185\" y=\"146\" width=\"56\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"213.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Done</text><text x=\"390\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">papel</text><text x=\"500\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">nome</text><text x=\"610\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">estado</text><rect x=\"380\" y=\"48\" width=\"320\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"390\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">link</text><text x=\"500\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"←\"</text><text x=\"610\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\"></text><rect x=\"380\" y=\"92\" width=\"320\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"390\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">heading</text><text x=\"500\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"JavaScript\"</text><text x=\"610\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">level 1</text><rect x=\"380\" y=\"144\" width=\"320\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"390\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">button</text><text x=\"500\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"Done\"</text><text x=\"610\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\"></text><path d=\"M278 62 L372 62\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l12-tree-ah-paper-dim)\"></path><path d=\"M278 106 L372 106\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l12-tree-ah-paper-dim)\"></path><path d=\"M278 158 L372 158\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l12-tree-ah-paper-dim)\"></path><text x=\"540\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--phosphor)\">um leitor de tela lê só esta coluna</text></svg>", "caption": "A página e a sua árvore de acessibilidade. A árvore é construída pelo navegador a partir do HTML, e é tudo o que um leitor de tela tem: aqui ela nomeia o link de voltar com um símbolo.", "same": ["JavaScript", "2026-10-22 · 30 min", "Done"]}
```

Há um para cada sistema, e a maioria das pessoas que usam um usa o que vem com o sistema ou o gratuito para
ele:

| sistema | leitor de tela | liga com |
|---|---|---|
| Windows | **NVDA**, gratuito e de código aberto; JAWS, pago; Narrador, embutido | NVDA: Ctrl+Alt+N depois de instalado; Narrador: Ctrl+Win+Enter |
| macOS | **VoiceOver**, embutido | Cmd+F5 |
| Linux | **Orca**, embutido no GNOME | Super+Alt+S |
| iOS, Android | VoiceOver; TalkBack | nos ajustes de acessibilidade do sistema |

## Como as pessoas andam por uma página

Quase ninguém ouve uma página de cima para baixo. Quem usa leitor de tela **passa os olhos**, como o olho de
quem enxerga faz, e o leitor dá jeitos de saltar por papel:

- **por título**, com H no modo de navegação do NVDA, ou com o rotor do VoiceOver (Ctrl+Option+U), que
  lista os títulos, os links e os landmarks da página, cada um numa lista;
- **por landmark**, para o conteúdo principal, a navegação, o rodapé;
- **por controle**, numa lista de todos os links ou de todos os campos de formulário da página;
- e **pelo Tab**, pelo que recebe o foco, exatamente como a aula 11 o percorreu.

Cada uma dessas listas é construída a partir da árvore. Uma página sem títulos não tem nada na lista de
títulos; uma página cujos links dizem todos *clique aqui* tem uma lista de links de linhas idênticas. **É
por isso que a árvore é a coisa a testar**, e a próxima seção imprime a do planner.

## Dois modos

Um leitor de tela numa página lê num **modo de navegação**, em que as teclas andam pelo conteúdo e uma
única letra salta (H para o próximo título, K para o próximo link no NVDA), e num **modo de foco**, em que
as teclas vão para o controle, para que digitar num campo digite. Ele troca de um para o outro sozinho
quando o foco entra num campo e sai dele. É por isso que um controle próprio que nunca diz ao leitor o que
é pode deixar alguém digitando H e indo para um título em vez de escrever uma letra.
