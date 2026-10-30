---
title: O CDK, comportamento sem aparência
version: 1
---

**O CDK é aquilo de que o Material é feito: os comportamentos que os componentes dele compartilham, sem
estilo próprio.** Um diálogo precisa de um overlay acima da página, do foco preso dentro dele enquanto
está aberto e devolvido quando fecha, do Escape para fechá-lo, e da página de trás escondida dos
leitores de tela. O diálogo do Material tira tudo isso do CDK e acrescenta a aparência Material. Uma
aplicação com design próprio usa o CDK direto, e acerta as partes difíceis sem levar a aparência do
Material.

| pacote do CDK | dá |
|---|---|
| `@angular/cdk/a11y` | `FocusTrap`, `FocusMonitor`, `LiveAnnouncer`, navegação de listas pelo teclado |
| `@angular/cdk/overlay` | painéis flutuantes posicionados junto a um elemento: menus, tooltips, pop-ups |
| `@angular/cdk/dialog` | diálogos, com o foco preso e devolvido, sem estilo |
| `@angular/cdk/drag-drop` | arrastar para reordenar, com uma alternativa de teclado a construir |
| `@angular/cdk/layout` | `BreakpointObserver`, para reagir ao tamanho da tela |
| `@angular/cdk/table` | a estrutura de uma tabela de dados, sem estilo |
| `@angular/cdk/scrolling` | rolagem virtual, desenhando só as linhas que estão na tela |

**A acessibilidade é a parte de um controle mais deixada pela metade**, porque é invisível para quem
construiu o controle com mouse e tela. Um foco que escapa de um diálogo para a página de trás, uma
atualização ao vivo que ninguém anuncia, uma lista que só um mouse reordena: cada um passa em toda
conferência visual. O pacote a11y do CDK existe para que cada um desses seja resolvido uma vez, por
pessoas que testaram com leitores de tela, e não de novo em cada aplicação. As duas próximas seções
usam duas peças dele.
