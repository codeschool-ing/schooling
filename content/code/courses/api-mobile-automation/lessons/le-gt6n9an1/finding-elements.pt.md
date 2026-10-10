---
title: Como um teste acha um botão que não consegue ver
version: 1
---

**Um teste mobile não consegue olhar a tela; ele pergunta ao Android o que há nela.** Todo elemento
que um app desenha é um nó numa árvore que o Android mantém para os serviços de acessibilidade, os
leitores de tela e controles por chave que as pessoas usam para operar um celular sem vê-lo ou
tocá-lo. O Appium lê essa árvore por fora; o Espresso percorre as próprias views do app por dentro.
Em qualquer caso, um teste é tão confiável quanto a alça que ele usa para tirar um nó da árvore.

Em ordem de preferência, as alças que um teste pode usar no Android:

| alça | no app | num teste | quebra quando |
|---|---|---|---|
| **resource id** | `android:id="@+id/refresh"` no layout | Espresso `withId(R.id.refresh)`; Appium `id`: `example.tickets:id/refresh` | alguém renomeia o id, o que um desenvolvedor raramente faz sem querer |
| **content description** | `android:contentDescription="Refresh the list"` | Espresso `withContentDescription(...)`; Appium `accessibility id` | a descrição é reescrita; ela também é o que um leitor de tela fala |
| **texto** | `android:text="@string/refresh"` | Espresso `withText("Refresh")`; Appium por texto | o texto muda, ou o celular está em português |
| **posição na árvore** | nada escrito | um XPath como `//android.widget.Button[1]` | qualquer coisa se mexe, em qualquer layout, a qualquer momento |

**O resource id é a primeira escolha**, e é por isso que todo elemento das duas telas do Tickets que
um teste toca tem um: `banner`, `refresh`, `error` e `shows` na lista, `title`, `time`, `price`,
`seats`, `remind` e `remind_denied` num espetáculo. Um id é uma promessa entre quem constrói o app e
quem o testa, e ele não muda quando uma palavra muda.

**O texto é a armadilha.** `withText("Refresh")` se lê com naturalidade e passa no dia em que é
escrito. Falha no dia em que o botão vira *Reload*, ou no dia em que a suíte roda num celular em
português e o botão diz *Atualizar*. O texto pertence a uma asserção (*a faixa diz Offline*), não à
alça que encontra a faixa.

**A posição é o último recurso**, e `web-automation` terá dito o mesmo sobre XPath na web. Um XPath
que conta botões descreve o layout de hoje; um designer que acrescenta um ícone quebra todo teste que
contou.

## Como é a árvore

O Appium pede essa árvore ao Android em XML e busca nela, e a lição 15 mostra como pedi-la. Cada nó é
um elemento com a classe, o resource id, o texto, a content description e os limites na tela em
pixels, então um teste que diz "o elemento cujo resource id é `example.tickets:id/refresh`" está
pedindo exatamente um nó dela. O resource id leva o nome do pacote na frente, `example.tickets:id/`,
porque dois apps numa tela, como o Tickets e o diálogo de permissão que o Android desenha por cima
dele, podem ter cada um um elemento chamado `refresh`.

## Testabilidade é acessibilidade

Um elemento sem id, sem descrição e sem texto é invisível para um teste e para uma pessoa cega do
mesmo jeito, pelo mesmo motivo: a árvore não tem nada a dizer sobre ele. Um botão só com ícone e sem
content description é o caso mais comum, e a correção é a mesma linha para os dois. **Quando um teste
é difícil de escrever porque um elemento não pode ser encontrado, registre isso como defeito de
acessibilidade**, porque é um, e esse é o argumento com mais chance de fazê-lo ser corrigido.
