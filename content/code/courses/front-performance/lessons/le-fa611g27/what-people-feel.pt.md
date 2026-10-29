---
title: Três coisas que uma pessoa sente
version: 1
---

**Uma pessoa não sente o tempo de carga de uma página. Ela sente três coisas separadas: se a página
já está lá, se ela responde quando é tocada, e se ela fica parada enquanto é lida.** Cada uma falha
do seu jeito, e uma página pode ser perfeita numa e péssima noutra. Uma página que mostra o conteúdo
em meio segundo e depois ignora toques por dois segundos é rápida por uma medida e quebrada pela
experiência.

O Google chama um número para cada uma dessas três de **Core Web Vitals**:

| o que uma pessoa sente | a métrica | o que ela mede |
|---|---|---|
| está lá | **LCP**, Largest Contentful Paint | quando o maior pedaço de conteúdo da janela foi pintado |
| responde | **INP**, Interaction to Next Paint | quanto a mais lenta das interações da página levou para mostrar uma resposta |
| fica parada | **CLS**, Cumulative Layout Shift | quanto conteúdo se mexeu sem a pessoa pedir |

## Ensinar a sensação, citar o número

Os três nomes e os seus limites são do Google, que os revisa. **O INP substituiu uma métrica mais
antiga, o First Input Delay, em março de 2024**, porque o FID media só a espera antes de a primeira
interação começar, e uma página podia ir bem nele enquanto cada toque depois do primeiro levava um
segundo para mostrar alguma coisa. Como quer que as métricas se chamem daqui a cinco anos, as três
sensações serão as mesmas, então cada seção abaixo começa pelo que uma pessoa nota e chega ao número
depois. Os limites que esta aula cita são os que a biblioteca `web-vitals` codifica, na versão que a
aula instala, e a seção "Bom, precisa melhorar, ruim" mostra onde lê-los.

## De onde vêm esses números

Todos eles são medidos **no navegador**, pelas próprias APIs de performance do navegador, enquanto
uma página de verdade é usada. Os outros dois números que este curso usou até aqui ficam no caminho
deles:

- a **primeira pintura com conteúdo**, do `look.ts` da aula 1, é o primeiro momento em que *qualquer
  coisa* foi desenhada, e o LCP é o momento em que a maior foi;
- **o momento em que o script assumiu**, do `hydrate.ts` da aula 4, é parte do que o INP sente: um
  toque na janela morta é uma interação cuja resposta não pode vir antes de o script estar lá.

O resto desta aula define cada métrica com precisão suficiente para raciocinar sobre ela, as
acrescenta ao planner, quebra duas delas de propósito e as conserta, e as manda para casa a partir do
navegador do visitante, que é o único lugar onde elas querem dizer alguma coisa.
