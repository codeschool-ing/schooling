---
title: Quando a chamada extra compensa
version: 1
---

O prompting de recuo não é um padrão melhor para toda pergunta. **Ele ajuda quando a redação
específica esconde o princípio que decide a resposta**, e custa uma segunda chamada toda vez,
tenha ajudado ou não.

## Onde ajuda

O misto quente do feriado é o caso típico: os fatos estão todos presentes, e a redação aponta para
o errado. Três tipos de pergunta têm esse formato:

- uma pergunta que é um caso de uma regra dita em outro lugar, sobretudo uma exceção a uma regra
  mais óbvia. Feriado segue o horário de domingo; reembolso acima de R$ 100 precisa do gerente.
- uma pergunta de uma área com leis ou definições, em que dar nome à lei é a maior parte do
  trabalho: física, química, impostos, uma cláusula de contrato.
- uma pergunta sobre um momento de uma história mais longa. "Em que time este jogador estava em
  março de 2009?" fica mais fácil depois que a pergunta de recuo, "como foi a carreira deste
  jogador, clube por clube?", pôs a lista inteira no prompt para a data ser lida contra ela.

## Onde não ajuda

Uma pergunta que já é geral não ganha nada sendo generalizada. "Como se chama a rede Wi-Fi dos
clientes?" não tem princípio por trás para onde recuar; a resposta é uma linha do manual. **Recuar
ali é uma segunda chamada que repete a primeira**, e o máximo que ela consegue é deixar a resposta
onde estava.

Ele também não cria conhecimento. Se o modelo não conhece a regra, ou o prompt não a contém, a
resposta de recuo enuncia uma regra plausível no lugar, e a segunda chamada responde fielmente a
partir do princípio errado. É a falha da lição 5 movida um passo para trás, onde fica mais difícil
de ver, porque a resposta final decorre logicamente do que vem antes. **Leia a resposta de recuo, e
não só a resposta final**: é a parte que dá para conferir contra o manual.

## Quanto custa

As duas chamadas mandam um prompt cada, e a segunda espera a primeira. O `tok` conta os prompts:

```
ana@lab:~/pe$ tok count direct.txt step1.txt step2.txt
tokens  words  chars  file
   116     81    457  direct.txt
   122     92    516  step1.txt
   226    161    891  step2.txt
```

A pergunta direta manda 116 tokens. A versão com recuo manda 122 e depois 226, o que dá 348 tokens
de entrada, três vezes mais, e além disso a resposta da primeira chamada é saída que você paga e
espera antes que a segunda possa começar. **O dobro de idas e voltas e cerca do triplo de entrada é
o preço de uma resposta**, então vale pagar onde uma resposta errada sai cara e o princípio é fácil
de perder, e não em toda requisição.

As duas chamadas podem ser dobradas num prompt só: "primeiro diga as regras gerais que se aplicam,
depois responda". Isso economiza a ida e volta e mantém boa parte do efeito, porque as regras
continuam escritas antes da resposta. E deixa você ver, numa resposta só, se as regras estavam
certas.

## Ao lado da cadeia de pensamento

Escrever algo antes da resposta também é o que a cadeia de pensamento faz, e a lição 26 trata
dela. A diferença está no que se escreve. **A cadeia de pensamento escreve os passos desta pergunta
até a sua resposta; o recuo escreve a regra geral de que a pergunta é um caso**, e faz isso antes
de olhar as especificidades. Os dois se combinam: recuar até o princípio, depois raciocinar sobre
o caso. A lição 26 mostra a segunda metade.
