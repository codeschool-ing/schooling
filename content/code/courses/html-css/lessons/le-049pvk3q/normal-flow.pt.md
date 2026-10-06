---
title: O fluxo normal, e o que static quer dizer
version: 1
---

Toda página das aulas 1 a 6 foi montada no **fluxo normal**: caixas block empilhadas de cima para baixo, cada uma da largura do contêiner, e caixas inline correndo pelas linhas dentro delas da esquerda para a direita. Uma caixa no fluxo ocupa espaço, e as caixas depois dela começam onde ela termina. Aumente um parágrafo e tudo abaixo dele desce. É o comportamento que você quer para quase todo conteúdo, porque é o comportamento da leitura.

O valor padrão da propriedade `position` é **`static`**, e ele quer dizer exatamente isso: a caixa está no fluxo normal, onde o fluxo a põe. Os quatro outros valores tiram uma caixa do fluxo, inteira ou em parte:

| valor | ocupa espaço? | `top` e `left` são medidos a partir de |
| --- | --- | --- |
| `static` | sim | nada: são ignorados |
| `relative` | sim, onde estaria | onde ela estaria |
| `absolute` | não | o bloco de contenção dela, seção 05 |
| `fixed` | não | a janela |
| `sticky` | sim | o contêiner de rolagem dela, dentro do pai |

As propriedades que fazem o deslocamento são **`top`**, **`right`**, **`bottom`** e **`left`**, chamadas propriedades de **inset**. Numa caixa static elas não fazem nada. O resto desta aula são os quatro valores, um de cada vez, medidos.

## A regra que vale ter antes de começar

Posicionamento é para colocar algumas caixas em relação a outras: um selo, um menu que desce, um aviso por cima da página. **Não é assim que se monta uma página.** Um layout de colunas feito com caixas absolutas em coordenadas fixas quebra assim que um texto fica mais longo que o previsto, uma janela fica mais estreita ou o leitor aumenta a fonte, porque nada nele abre espaço para nada. As aulas 8 e 9 montam páginas com Flexbox e Grid, que mantêm tudo num fluxo que se adapta; o posicionamento é para o que fica por cima desse fluxo.
