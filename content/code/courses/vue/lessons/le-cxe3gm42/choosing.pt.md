---
title: Escolhendo, página por página
version: 1
---

**Não existe melhor modo, só um melhor modo para uma página**, decidido por duas perguntas: a página é
igual para todo leitor, e com que rapidez uma mudança precisa chegar a ela?

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Três linhas do tempo de uma visita, da esquerda para a direita. Renderização no cliente: o HTML chega vazio, o script é baixado e roda, os dados são buscados, e só então a página é desenhada e pode ser usada. Renderização no servidor: o servidor renderiza a página para a requisição, o HTML chega desenhado e pode ser lido na hora, depois o script baixa e a hidrata, e só depois disso ela responde a um clique. Geração estática: a página foi renderizada uma vez, no build; a requisição é respondida com o arquivo, legível na hora, e hidratada quando o script rodou.\"><text x=\"40\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">CSR</text><rect x=\"80\" y=\"40\" width=\"110\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"135.0\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">HTML vazio</text><rect x=\"194\" y=\"40\" width=\"90\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"239.0\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">script</text><rect x=\"288\" y=\"40\" width=\"80\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"328.0\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">dados</text><rect x=\"372\" y=\"40\" width=\"150\" height=\"32\" rx=\"4\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"447.0\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">desenhada, usável</text><text x=\"40\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">SSR</text><rect x=\"80\" y=\"110\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">servidor renderiza</text><rect x=\"204\" y=\"110\" width=\"150\" height=\"32\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"279.0\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">desenhada, legível</text><rect x=\"358\" y=\"110\" width=\"160\" height=\"32\" rx=\"4\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"438.0\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">hidratada, usável</text><text x=\"40\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">SSG</text><rect x=\"80\" y=\"180\" width=\"70\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">arquivo</text><rect x=\"154\" y=\"180\" width=\"150\" height=\"32\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"229.0\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">desenhada, legível</text><rect x=\"308\" y=\"180\" width=\"160\" height=\"32\" rx=\"4\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"388.0\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">hidratada, usável</text><line x1=\"80\" y1=\"228\" x2=\"690\" y2=\"228\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"690.0,228.0 682.6,231.1 682.6,224.9\" fill=\"var(--wire)\"></polygon><text x=\"385\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">tempo desde o clique no link</text></svg>", "caption": "Os modos do servidor põem palavras na tela mais cedo; em todos eles a página só responde a um clique depois da hidratação.", "same": ["script"]}
```

| modo | o HTML é feito | primeiras palavras na tela | uma mudança chega à página | precisa de servidor |
| --- | --- | --- | --- | --- |
| CSR, o planner do Vite | no navegador, a cada visita | depois do script e dos dados | na hora | só para os dados |
| SSR, o padrão do Nuxt | no servidor, a cada requisição | com o HTML | na hora | sim |
| SSG, `nuxt generate` | uma vez, no build | com o HTML | no próximo deploy | não |
| SWR ou ISR | no servidor, e depois guardado | com o HTML | dentro da janela, `60` s aqui | sim, ou o do host |
| só no cliente | no navegador, depois da hidratação | depois do script | na hora | não |

Todo modo menos o CSR manda HTML já desenhado, e todos esses hidratam, então as divergências desta
aula valem para todos eles, SSG incluído: o que o navegador sabe e o servidor não precisa ser desenhado
depois da hidratação, seja qual for o modo.

## As escolhas do planner

- **A semana, `/`: SSR**, com o dia do leitor só no cliente. Ela muda a cada marcação, e é a página que
  um estudante abre todo dia, então vale a pena ela chegar desenhada.
- **Um curso, `/courses/:id`: SSR.** O `swr` da seção de route rules é a troca errada para uma página que
  o leitor edita; a regra sai do `nuxt.config.ts` no dia em que este planner for para produção.
- **`/about`: pré-renderizada.** Igual para todo mundo até o próximo deploy.
- **A API: sem cache.** Uma lista de sessões que alguém acabou de mudar não é coisa de se guardar.

Um catálogo de cursos, o tipo de site para o qual esses modos foram inventados, decide ao contrário:
as páginas dele são iguais para todo leitor, são lidas milhares de vezes entre duas edições e precisam
ser encontradas por buscadores, então são geradas ou guardadas com `swr`, e só as partes que pertencem
a um leitor, um carrinho ou um nome, são desenhadas no navegador.

A aula 2 de `front-performance` mede esses modos, no Nuxt e em outros três frameworks, e é o lugar para
levar os números adiante. A próxima aula volta à linha de que o SSR e o SSG dependem, o `useFetch`, e ao
que acontece com dados buscados de um lado e usados do outro.
