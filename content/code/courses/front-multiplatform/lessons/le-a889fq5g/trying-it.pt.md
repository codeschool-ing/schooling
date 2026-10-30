---
title: Experimentando, e o que um celular mostraria
version: 1
---

Sirva a exportação como na aula 7 e abra-a. O router desenha uma página assim que sabe qual tela o
endereço nomeia, então a primeira execução espera um instante por isso:

```
ana@dev:~/planner-native$ node look.mjs 'http://localhost:8082/?today=2026-10-21' --wait 1000
- heading "Study planner" [level=1]
- main:
  - text: "This week: 75 of 125 minutes done"
  - button "Spanish A2"
  - button "Statistics"
  - button "Guitar"
```

**A barra de título é um título, "Study planner"**, desenhado pela pilha a partir do `title` que a tela
definiu, acima da tela em si, o `main`. Agora o curso, uma sessão nova para 23 de outubro, e uma com uma
data que o planner não consegue ler:

```
ana@dev:~/planner-native$ node look.mjs 'http://localhost:8082/?today=2026-10-21' --click Statistics --fill Date=2026-10-23 --fill Minutes=25 --click 'Add session'
- link "Study planner, back":
  - /url: /?today=2026-10-21
- heading "Statistics" [level=1]
- main:
  - text: "This week: 75 of 150 minutes done 2026-10-20, 45 min done 2026-10-26, 60 min"
  - button "Mark done"
  - text: 2026-10-23, 25 min
  - button "Mark done"
  - textbox "Date":
    - /placeholder: YYYY-MM-DD
  - textbox "Minutes"
  - button "Add session"
ana@dev:~/planner-native$ node look.mjs 'http://localhost:8082/?today=2026-10-21' --click Statistics --fill Date=23/10 --fill Minutes=25 --click 'Add session' | tail -n 3
  - textbox "Minutes": "25"
  - button "Add session"
  - alert: "not a date: 23/10"
```

A sessão nova está na lista e a semana foi de 125 para 150, a mesma conta da aula 1 seção 06, do mesmo
`addSession`. A segunda execução digitou `23/10`: o `addSession` a recusou com a própria mensagem, `not a
date: 23/10`, e a tela mostrou isso como um alerta em vez de acrescentar uma sessão que ninguém
conseguiria somar. Na tela do curso a pilha também desenhou um **link de volta**, com o nome da tela para
onde ele volta; num celular, essa é a seta de voltar da barra de título, e o gesto de voltar do sistema
faz o mesmo.

## O que o celular mostra no lugar

*O Expo Go e os emuladores não foram rodados para este curso, como a aula 7 disse; isto é o que o mesmo
código faz lá, pela documentação do Expo e do React Native.* A barra de título é a da plataforma:
centralizada no iOS, à esquerda no Android. A tela do curso desliza da direita, e no iOS um deslizar a
partir da borda esquerda a tira. Os campos são nativos, e o campo de minutos abre o teclado de dígitos.
**Nada no código acima diz nada disso**: é o que as views nativas e uma pilha nativa dão, e é a parte do
"o que ele compra" da aula 7 que um navegador não consegue mostrar.
