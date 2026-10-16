---
title: Defendendo uma decisão
version: 1
---

Um registro é proposto antes de ser aceito, em geral num pull request, e a revisão é onde uma decisão é
defendida. Os revisores fazem as mesmas poucas perguntas, e um bom registro já as respondeu antes de
alguém perguntar:

| a pergunta | o que a responde |
| --- | --- |
| "Por que não a alternativa óbvia?" | as opções consideradas, cada uma com o motivo de ter perdido |
| "Quanto isso custa?" | consequências que incluem as ruins, com números onde há números |
| "O que nos faria mudar de ideia?" | as condições do contexto: "com dez vezes o tráfego de hoje", "se a equipe passar de duas pessoas" |
| "Isso é reversível?" | quão difícil é desfazer a decisão, o que decide quanta discussão ela merece |
| "Quem mais é afetado?" | as equipes, serviços ou clientes cujo trabalho muda |

Este curso foi um longo ensaio da segunda linha. Todo padrão veio com o seu preço, medido no laboratório: a
ida e volta de uma chamada síncrona, a janela de uma cópia eventualmente consistente, a latência de uma
réplica síncrona, a memória de um sidecar, a reserva que recusou um cliente por café que nunca foi
vendido. **Uma decisão defendida com uma medição é muito mais difícil de descartar** do que uma defendida
com uma preferência, e muito mais fácil de revisitar quando a medição muda.

A quarta linha merece uma frase própria. A distinção de Jeff Bezos entre **portas de mão única e de mão
dupla** é o jeito de costume de dizer isso: uma decisão que pode ser revertida barato deveria ser tomada
rápido, por quem está mais perto dela, e uma que não pode deveria ser tomada devagar e escrita com
cuidado. A maior parte dos registros que uma equipe escreve é sobre portas de mão única, porque são essas
que vão precisar de explicação.
