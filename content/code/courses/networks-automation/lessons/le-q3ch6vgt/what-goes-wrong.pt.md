---
title: O que dá errado à mão
version: 1
---

As falhas da seção anterior não são azar. **São as três maneiras como uma mudança feita à mão dá
errado**, e elas têm nome:

- **Um valor errado que é válido.** `192.0.12.0/24` passa na análise, então nada o recusa. O
  roteador verifica se uma prefix list está bem formada e não tem como verificar se é a que
  pediram.
- **Uma omissão.** O `edge2` nunca foi tocado. Nada no `edge2` diz que havia uma mudança
  pendente, e nada nos outros dois diz que ela aconteceu em outro lugar.
- **Deriva.** Quando os três roteadores diferem, toda mudança seguinte parte de três pontos de
  partida diferentes, e a diferença cresce. Ninguém decidiu que o `edge1` seria especial; ele
  ficou especial uma tecla por vez.

**A crença comum é que cuidado resolve isso**: ir mais devagar, ler duas vezes, usar uma
checklist. O cuidado baixa a taxa de erro e nunca chega a zero, e a taxa é multiplicada pelo
número de equipamentos e pelo número de mudanças. Uma pessoa cuidadosa que erra um comando em
cem, numa rede de cem roteadores, digita em média um erro por mudança, e o entrega junto com cada
mudança.

O que a automação muda é **onde o erro pode acontecer**. Um script digita a linha do mesmo jeito
toda vez, então um erro no script é um erro em todo lugar, o que é pior de um jeito e muito
melhor de outro. Ele é achado uma vez, no primeiro roteador, por quem lê a saída, e corrigido em
um lugar só. Um erro digitado à mão no quadragésimo roteador é achado quando algo quebra.

**A automação não elimina o erro humano. Ela o leva para onde ele pode ser revisado**: um
arquivo que um colega lê antes de rodar, e um teste que roda antes de chegar a um equipamento. As
aulas 13 e 14 constroem os dois.
