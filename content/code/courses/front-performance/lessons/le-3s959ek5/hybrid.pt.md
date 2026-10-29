---
title: Renderização híbrida
version: 1
---

**Híbrida é o nome do que o planner faz agora com o JavaScript ligado: o servidor renderiza a
primeira página, e dali em diante o navegador renderiza cada página para onde a pessoa vai.** A
primeira visão ganha aquilo em que a renderização no servidor é boa, conteúdo na primeira
resposta. Cada clique depois dela ganha aquilo em que a renderização no cliente é boa, nenhuma ida
ao servidor atrás de HTML.

Rode o `look.ts` com JavaScript contra o `server.ts` e observe as requisições: a página, o seu
script e a sua folha de estilo, e o `/courses.json`. Depois clique em *Git* no seu próprio
navegador, com as ferramentas de desenvolvedor abertas na aba Network: **nenhuma requisição de
página sai.** O tratador de links em `mount` mudou o endereço com `history.pushState` e desenhou a
página do curso a partir do plano que já tinha. Recarregue, e a requisição vai ao servidor de novo,
que desenha ele mesmo a página do curso.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Uma sessão híbrida. A primeira página é pedida ao servidor, que a desenha. Depois dois cliques, para o curso de Git e de volta à lista, são desenhados pelo script no navegador, e nenhuma requisição de página vai ao servidor. Um recarregamento manda a requisição ao servidor de novo.\"><text x=\"20\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">servidor</text><text x=\"20\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">navegador</text><line x1=\"100\" y1=\"50\" x2=\"700\" y2=\"50\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 3\"></line><line x1=\"100\" y1=\"140\" x2=\"700\" y2=\"140\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 3\"></line><rect x=\"120\" y=\"34\" width=\"110\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"175\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">desenha</text><line x1=\"175\" y1=\"66\" x2=\"175\" y2=\"122\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"175.0,122.0 171.9,114.6 178.1,114.6\" fill=\"var(--amber)\"></polygon><rect x=\"120\" y=\"124\" width=\"110\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"175\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">mostra</text><text x=\"175\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">GET /</text><rect x=\"270\" y=\"124\" width=\"110\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"325\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">desenha</text><text x=\"325\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">clique em Git</text><rect x=\"420\" y=\"124\" width=\"110\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"475\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">desenha</text><text x=\"475\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">clique em All courses</text><rect x=\"580\" y=\"34\" width=\"110\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"635\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">desenha</text><line x1=\"635\" y1=\"66\" x2=\"635\" y2=\"122\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"635.0,122.0 631.9,114.6 638.1,114.6\" fill=\"var(--amber)\"></polygon><rect x=\"580\" y=\"124\" width=\"110\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"635\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">mostra</text><text x=\"635\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">recarregar</text></svg>", "caption": "O servidor desenha a primeira página e cada recarregamento; o navegador desenha tudo no meio.", "same": ["GET /"]}
```

## Híbrida em mais três sentidos

A palavra serve para mais de um arranjo, e os frameworks da aula 2 oferecem todos eles, então vale
separá-los agora.

**Por navegação**, como acima: servidor para a primeira página, navegador para o resto. É o que
cada um dos quatro meta-frameworks faz por padrão.

**Por rota**: alguns endereços são renderizados a cada requisição, alguns uma vez no build e
servidos como arquivos, e alguns ficam inteiramente com o navegador. Um catálogo de cursos que muda
uma vez por semana, um painel que mostra a cada pessoa os seus próprios números e uma tela de
configurações que ninguém jamais vai achar por um buscador querem três respostas diferentes, e um
mesmo site pode dar as três. A aula 2 mostra como cada framework escreve essa escolha, e a aula 3 é
a resposta do build.

**Por componente**: a maior parte de uma página é HTML estático que nunca muda depois de chegar, e
só algumas partes respondem a alguma coisa. Uma abordagem chamada **islands**, ilhas, manda a parte
estática como HTML puro, sem script nenhum, e só envia JavaScript para as partes que precisam dele,
como os botões *Mark done* e o formulário do planner. A aula 4 volta a ela, porque é um jeito de
deixar a hidratação mais barata.

## Quanto a híbrida custa

A híbrida mantém os dois custos das duas seções anteriores e acrescenta um seu. O servidor
renderiza cada primeira página, como na renderização no servidor. O navegador baixa e roda o app
inteiro, como na renderização no cliente, porque é ele que vai desenhar a próxima página. **E a
mesma página agora tem dois renderizadores que precisam concordar**: o HTML que o servidor desenhou
e o HTML que o script desenharia têm de ser iguais, ou a passagem muda o que a pessoa está olhando.
No planner eles concordam por construção, porque os dois chamam `page`. A aula 4 quebra isso de
propósito, com uma data.
