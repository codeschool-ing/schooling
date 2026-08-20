---
title: DOM: o HTML virando árvore
---

O navegador lê o HTML e constrói o **DOM** — uma árvore de objetos em que cada elemento é um nó com pai, filhos e propriedades. O HTML é o texto; o DOM é o que existe na memória depois de interpretá-lo.

A distinção importa porque o DOM não é obrigado a se parecer com o arquivo. Ele é corrigido na montagem (uma tag mal fechada é remendada) e alterado depois, pelo JavaScript. Por isso "ver o código-fonte" e "inspecionar o elemento" podem mostrar coisas diferentes — o primeiro é o texto que veio, o segundo é a árvore como está agora.
